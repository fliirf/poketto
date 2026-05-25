import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class TransactionLocation {
  final double? latitude;
  final double? longitude;
  final String? name;
  final String? message;

  const TransactionLocation({
    this.latitude,
    this.longitude,
    this.name,
    this.message,
  });

  bool get hasCoordinate => latitude != null && longitude != null;

  String? get coordinateLabel {
    if (!hasCoordinate) return null;
    return '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}';
  }

  String get statusLabel {
    if (hasCoordinate) {
      final label = name ?? coordinateLabel;
      return 'Lokasi berhasil: $label';
    }
    return message ??
        'Lokasi tidak tersedia, transaksi tetap bisa disimpan tanpa lokasi.';
  }
}

class LocationService {
  Future<TransactionLocation> getCurrentTransactionLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        return const TransactionLocation(
          message: 'Izin lokasi ditolak, transaksi akan disimpan tanpa lokasi.',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        return const TransactionLocation(
          message:
              'Izin lokasi ditolak permanen, transaksi akan disimpan tanpa lokasi.',
        );
      }

      final lastKnown = await _lastKnownPosition();
      if (lastKnown != null && _canUseLastKnown(lastKnown)) {
        final locationName = await _reverseGeocode(
          lastKnown.latitude,
          lastKnown.longitude,
        );
        return TransactionLocation(
          latitude: lastKnown.latitude,
          longitude: lastKnown.longitude,
          name: locationName,
          message: 'Lokasi terakhir berhasil ditambahkan.',
        );
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const TransactionLocation(
          message:
              'Lokasi tidak diaktifkan, transaksi tetap dapat disimpan tanpa lokasi.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 6),
      );

      final locationName = await _reverseGeocode(
        position.latitude,
        position.longitude,
      );

      return TransactionLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        name: locationName,
        message: 'Lokasi berhasil ditambahkan.',
      );
    } on TimeoutException {
      debugPrint('Location timeout while getting current position.');
      return const TransactionLocation(
        message:
            'Lokasi tidak berhasil diambil. Transaksi tetap disimpan tanpa lokasi.',
      );
    } catch (error) {
      debugPrint('Location error: $error');
      return const TransactionLocation(
        message:
            'Lokasi tidak berhasil diambil. Transaksi tetap disimpan tanpa lokasi.',
      );
    }
  }

  Future<Position?> _lastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition()
          .timeout(const Duration(seconds: 2));
    } catch (error) {
      debugPrint('Last known location error: $error');
      return null;
    }
  }

  bool _canUseLastKnown(Position position) {
    final timestamp = position.timestamp;
    if (timestamp == null) return true;
    final ageSeconds = DateTime.now().difference(timestamp).inSeconds.abs();
    return ageSeconds <= const Duration(hours: 24).inSeconds;
  }

  Future<String?> _reverseGeocode(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude)
          .timeout(const Duration(seconds: 3));
      if (placemarks.isEmpty) return null;

      final place = placemarks.first;
      final parts = [
        place.subLocality,
        place.locality,
        place.administrativeArea,
      ].where((part) => part != null && part.trim().isNotEmpty).toList();

      return parts.isEmpty ? null : parts.join(', ');
    } catch (error) {
      debugPrint('Reverse geocoding error: $error');
      return null;
    }
  }
}
