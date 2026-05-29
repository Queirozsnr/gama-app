/// Parses an ISO-8601 string that the server returns without 'Z' but is UTC,
/// and converts to the device's local time.
DateTime parseUtc(String s) =>
    DateTime.parse(s.endsWith('Z') ? s : '${s}Z').toLocal();

DateTime? parseUtcOpt(String? s) => s == null ? null : parseUtc(s);
