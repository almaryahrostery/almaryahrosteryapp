import 'package:flutter/material.dart';

class SavedAddress {
  final String id;
  final String name;
  final String fullAddress;
  final double latitude;
  final double longitude;
  final String? buildingDetails;
  final String? landmark;
  final AddressType type;
  final DateTime createdAt;
  final bool isDefault;

  const SavedAddress({
    required this.id,
    required this.name,
    required this.fullAddress,
    required this.latitude,
    required this.longitude,
    this.buildingDetails,
    this.landmark,
    required this.type,
    required this.createdAt,
    this.isDefault = false,
  });

  factory SavedAddress.fromJson(Map<String, dynamic> json) {
    return SavedAddress(
      id: json['id'] as String,
      name: json['name'] as String,
      fullAddress: json['fullAddress'] as String,
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      buildingDetails: json['buildingDetails'] as String?,
      landmark: json['landmark'] as String?,
      type: AddressType.values[json['type'] as int],
      createdAt: DateTime.parse(json['createdAt'] as String),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  /// Parse address from backend API response (MongoDB format)
  factory SavedAddress.fromBackendJson(Map<String, dynamic> json) {
    // Parse address type from string
    final typeStr = (json['type'] as String?)?.toLowerCase() ?? 'other';
    AddressType addressType;
    switch (typeStr) {
      case 'home':
        addressType = AddressType.home;
        break;
      case 'work':
        addressType = AddressType.work;
        break;
      default:
        addressType = AddressType.other;
    }

    return SavedAddress(
      id: json['_id'] as String, // MongoDB uses _id
      name: json['name'] as String,
      fullAddress: json['fullAddress'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      buildingDetails: json['buildingDetails'] as String?,
      landmark: json['landmark'] as String?,
      type: addressType,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'fullAddress': fullAddress,
      'latitude': latitude,
      'longitude': longitude,
      'buildingDetails': buildingDetails,
      'landmark': landmark,
      'type': type.index,
      'createdAt': createdAt.toIso8601String(),
      'isDefault': isDefault,
    };
  }

  SavedAddress copyWith({
    String? id,
    String? name,
    String? fullAddress,
    double? latitude,
    double? longitude,
    String? buildingDetails,
    String? landmark,
    AddressType? type,
    DateTime? createdAt,
    bool? isDefault,
  }) {
    return SavedAddress(
      id: id ?? this.id,
      name: name ?? this.name,
      fullAddress: fullAddress ?? this.fullAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      buildingDetails: buildingDetails ?? this.buildingDetails,
      landmark: landmark ?? this.landmark,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  String get displayName {
    return buildingDetails?.isNotEmpty == true
        ? '$name, $buildingDetails'
        : name;
  }

  String get shortAddress {
    final parts = fullAddress.split(',');
    return parts.length > 2 ? '${parts[0]}, ${parts[1]}' : fullAddress;
  }
}

enum AddressType {
  home,
  work,
  other;

  String get displayName {
    switch (this) {
      case AddressType.home:
        return 'Home';
      case AddressType.work:
        return 'Work';
      case AddressType.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case AddressType.home:
        return Icons.home;
      case AddressType.work:
        return Icons.work;
      case AddressType.other:
        return Icons.location_on;
    }
  }
}
