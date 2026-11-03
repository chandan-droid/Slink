import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/logger.dart';
import '../models/device_dto.dart';

abstract class DeviceRepository {
  Future<DeviceResponseDto?> registerDevice(String deviceToken, {String? platform});
  Future<bool> unregisterDevice(String deviceToken);
  Future<List<DeviceResponseDto>> getUserDevices();
}

class DeviceRepositoryImpl implements DeviceRepository {
  final DioClient _dio;

  DeviceRepositoryImpl(this._dio);

  static String detectPlatform() {
    if (kIsWeb) return 'WEB';
    if (Platform.isAndroid) return 'ANDROID';
    if (Platform.isIOS) return 'IOS';
    if (Platform.isWindows) return 'WINDOWS';
    if (Platform.isMacOS) return 'MACOS';
    if (Platform.isLinux) return 'LINUX';
    return 'ANDROID';
  }

  @override
  Future<DeviceResponseDto?> registerDevice(String deviceToken, {String? platform}) async {
    final effectivePlatform = platform ?? detectPlatform();
    AppLogger.info('Registering device token with server: ${deviceToken.substring(0, deviceToken.length.clamp(0, 15))}... ($effectivePlatform)', tag: 'Device');
    try {
      final req = DeviceRegistrationRequest(
        deviceToken: deviceToken,
        platform: effectivePlatform,
      );
      final response = await _dio.dio.post(
        AppConfig.devicesEndpoint,
        data: req.toJson(),
      );
      AppLogger.info('Device token registered successfully with backend', tag: 'Device');
      return DeviceResponseDto.fromJson(response.data as Map<String, dynamic>);
    } catch (e, st) {
      AppLogger.error('Failed to register device token with backend', tag: 'Device', error: e, stackTrace: st);
      return null;
    }
  }

  @override
  Future<bool> unregisterDevice(String deviceToken) async {
    AppLogger.info('Unregistering device token from server: ${deviceToken.substring(0, deviceToken.length.clamp(0, 15))}...', tag: 'Device');
    try {
      await _dio.dio.delete('${AppConfig.devicesEndpoint}/$deviceToken');
      AppLogger.info('Device token unregistered successfully from backend', tag: 'Device');
      return true;
    } catch (e, st) {
      AppLogger.error('Failed to unregister device token from backend', tag: 'Device', error: e, stackTrace: st);
      return false;
    }
  }

  @override
  Future<List<DeviceResponseDto>> getUserDevices() async {
    try {
      final response = await _dio.dio.get(AppConfig.devicesEndpoint);
      final list = (response.data as List)
          .map((e) => DeviceResponseDto.fromJson(e as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e, st) {
      AppLogger.error('Failed to fetch user devices', tag: 'Device', error: e, stackTrace: st);
      return [];
    }
  }
}

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DeviceRepositoryImpl(ref.read(dioClientProvider));
});

