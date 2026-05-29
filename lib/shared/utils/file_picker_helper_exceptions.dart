const kMaxMediaBytes = 50 * 1024 * 1024; // 50 MB

class FileTooLargeException implements Exception {
  const FileTooLargeException(this.name);
  final String name;
}
