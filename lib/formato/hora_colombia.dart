/// Colombia keeps UTC-5 all year, the zone the database uses
/// (America/Bogota), whatever the zone of the device is.
const desfaseColombia = Duration(hours: -5);

/// The wall-clock time in Colombia of a timestamp read from the database.
DateTime horaColombia(String timestamp) {
  final t = DateTime.parse(timestamp).toUtc().add(desfaseColombia);
  return DateTime(
    t.year,
    t.month,
    t.day,
    t.hour,
    t.minute,
    t.second,
    t.millisecond,
    t.microsecond,
  );
}

/// The day in Colombia of a timestamp read from the database.
DateTime diaColombia(String timestamp) {
  final t = horaColombia(timestamp);
  return DateTime(t.year, t.month, t.day);
}

/// [hora], a wall-clock time in Colombia, written for the database with its
/// offset.
String textoColombia(DateTime hora) {
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${hora.year.toString().padLeft(4, '0')}-${dos(hora.month)}-'
      '${dos(hora.day)}T${dos(hora.hour)}:${dos(hora.minute)}:'
      '${dos(hora.second)}-05:00';
}
