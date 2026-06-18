class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final Object? cause;

  const ApiException({
    required this.message,
    this.statusCode,
    this.cause,
  });

  bool get canUseLocalFallback {
    return statusCode == null ||
        statusCode == 404 ||
        statusCode == 405 ||
        statusCode == 501;
  }

  String get userMessage {
    if (statusCode == null) {
      return 'Koneksi ke server bermasalah. Periksa internet atau backend Poketto.';
    }

    switch (statusCode) {
      case 400:
      case 422:
        return message.isNotEmpty ? message : 'Data yang dikirim belum valid.';
      case 401:
        return 'Sesi berakhir. Silakan login ulang.';
      case 403:
        return 'Anda tidak memiliki akses untuk aksi ini.';
      case 404:
        return 'Data tidak ditemukan.';
      case 408:
        return 'Koneksi timeout. Coba lagi.';
      default:
        if (statusCode != null && statusCode! >= 500) {
          return 'Server sedang bermasalah. Coba lagi nanti.';
        }
        return message.isNotEmpty ? message : 'Terjadi kesalahan.';
    }
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
