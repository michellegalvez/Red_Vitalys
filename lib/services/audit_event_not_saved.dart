/// The database could not create the audit event, so the action was not
/// done and the user sees "No se pudo completar la acción" (F-20).
class AuditEventNotSaved implements Exception {
  const AuditEventNotSaved();

  @override
  String toString() => 'AuditEventNotSaved: the audit event was not created';
}

/// The SQL state the saving functions of migration 014 use when the audit
/// event cannot be created.
const auditEventErrorCode = 'RVE01';
