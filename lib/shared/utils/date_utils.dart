DateTime parseUtc(String s) =>
    DateTime.parse(s.endsWith('Z') ? s : '${s}Z').toLocal();

DateTime? parseUtcOpt(String? s) => s == null ? null : parseUtc(s);
