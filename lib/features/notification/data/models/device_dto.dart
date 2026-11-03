class DeviceRegistrationRequest {
  final String deviceToken;
  final String platform;

  const DeviceRegistrationRequest({
    required this.deviceToken,
    required this.platform,
  });

  Map<String, dynamic> toJson() => {
        'deviceToken': deviceToken,
        'platform': platform.toUpperCase(),
      };
}

class DeviceResponseDto {
  final String id;
  final String userId;
  final String deviceToken;
  final String platform;
  final DateTime? createdAt;
  final DateTime? lastActiveAt;

  const DeviceResponseDto({
    required this.id,
    required this.userId,
    required this.deviceToken,
    required this.platform,
    this.createdAt,
    this.lastActiveAt,
  });

  factory DeviceResponseDto.fromJson(Map<String, dynamic> json) {
    return DeviceResponseDto(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      deviceToken: json['deviceToken']?.toString() ?? '',
      platform: json['platform']?.toString() ?? 'ANDROID',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.tryParse(json['lastActiveAt'].toString())
          : null,
    );
  }
}

