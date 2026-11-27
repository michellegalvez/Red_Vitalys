import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The session expired or is missing and could not be renewed, so the
/// request was not made; the app goes back to the sign-in screen.
class SessionExpired implements Exception {
  const SessionExpired();

  @override
  String toString() => 'SessionExpired: the Supabase session ended';
}

/// How long a request to Supabase may take before it counts as failed.
const remoteTimeout = Duration(seconds: 15);

/// Rows that PostgREST gives per request in Supabase (its `max-rows`).
const remotePageSize = 1000;

/// The single door every Supabase request goes through: it checks that there
/// is a session, renews it once when the server rejects the token, ends it
/// through `AuthService.sessionEnded` when it cannot be renewed, and gives up
/// after [timeout] so the screen shows its error state.
class SessionGuard {
  SessionGuard._(this.client)
    : _token = client.auth.currentSession?.accessToken {
    client.auth.onAuthStateChange.listen(
      (state) {
        // The stream repeats the last event to a new listener: a session
        // already known is not a change.
        final token = state.session?.accessToken;
        if (!_sessionChanges.contains(state.event) || token == _token) return;
        _token = token;
        _generation++;
      },
      onError: (Object error) {
        debugPrint('Auth state error: $error');
      },
    );
  }

  /// The guard of [client]: one per client, shared by all its services.
  factory SessionGuard.of(SupabaseClient client) =>
      _guards[client] ??= SessionGuard._(client);

  static final _guards = Expando<SessionGuard>();

  static const _sessionChanges = {
    AuthChangeEvent.signedIn,
    AuthChangeEvent.signedOut,
    AuthChangeEvent.userUpdated,
  };

  final SupabaseClient client;

  /// The limit of each request; shorter in the tests.
  @visibleForTesting
  Duration timeout = remoteTimeout;

  int _generation = 0;
  String? _token;
  String? _owner;
  Future<void>? _ending;

  /// Changes whenever the session or its user changes: anything cached under
  /// another value belongs to someone else and must be read again.
  int get generation {
    final id = client.auth.currentUser?.id;
    if (id != _owner) {
      _owner = id;
      _generation++;
    }
    return _generation;
  }

  /// Runs [request] with the session rules. With [requiresSession] false it
  /// only applies the timeout (the failed sign-in has no session).
  Future<T> run<T>(
    Future<T> Function() request, {
    bool requiresSession = true,
    Duration? limit,
  }) async {
    final wait = limit ?? timeout;
    if (!requiresSession) return request().timeout(wait);
    if (client.auth.currentSession == null) {
      throw await _end('there is no session');
    }
    try {
      return await request().timeout(wait);
    } on Exception catch (error) {
      if (!isAuthFailure(error)) rethrow;
      debugPrint('The server rejected the token, renewing it: $error');
    }
    try {
      await client.auth.refreshSession().timeout(wait);
    } on AuthRetryableFetchException {
      // No network: the session may still be fine, so it is not ended.
      rethrow;
    } on TimeoutException {
      rethrow;
    } on AuthException catch (error) {
      throw await _end('the token could not be renewed: $error');
    }
    try {
      return await request().timeout(wait);
    } on Exception catch (error) {
      if (!isAuthFailure(error)) rethrow;
      throw await _end('the renewed token was rejected: $error');
    }
  }

  /// Reads every page of [query], [remotePageSize] rows at a time, so no row
  /// is lost to the PostgREST limit. [query] must have a stable order.
  Future<List<Map<String, dynamic>>> fetchAll(
    PostgrestTransformBuilder<PostgrestList> Function() query,
  ) async {
    final rows = <Map<String, dynamic>>[];
    while (true) {
      final from = rows.length;
      final page = await run(
        () => query().range(from, from + remotePageSize - 1),
      );
      rows.addAll(page);
      if (page.length < remotePageSize) return rows;
    }
  }

  /// Signs out on this device only. Supabase removes the session and emits
  /// `signedOut` before calling the server, so the app reacts even offline.
  Future<SessionExpired> _end(String reason) async {
    debugPrint('Ending the Supabase session: $reason');
    await (_ending ??= _signOut().whenComplete(() => _ending = null));
    return const SessionExpired();
  }

  Future<void> _signOut() async {
    try {
      await client.auth.signOut(scope: SignOutScope.local).timeout(timeout);
    } on Exception catch (error) {
      debugPrint('Could not tell the server about the ended session: $error');
    }
  }
}

/// Whether [error] means the server no longer accepts the session's token.
@visibleForTesting
bool isAuthFailure(Object error) => switch (error) {
  PostgrestException(:final code, :final message) =>
    _authCodes.contains(code) || _mentionsBadToken(message),
  StorageException(:final statusCode, :final message) =>
    statusCode == '401' || _mentionsBadToken(message),
  AuthRetryableFetchException() => false,
  // The client could not renew the token before sending the request.
  AuthException() => true,
  _ => false,
};

const _authCodes = {'401', 'PGRST301', 'PGRST302', 'PGRST303'};

bool _mentionsBadToken(String message) {
  final text = message.toLowerCase();
  return text.contains('jwt expired') ||
      text.contains('invalid jwt') ||
      (text.contains('jwt') && text.contains('expired'));
}
