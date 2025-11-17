import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'user_address.g.dart';

@HiveType(typeId: 0)
class UserAddress extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String label; // Home, Work, Other

  @HiveField(2)
  late String street;

  @HiveField(3)
  late String building;

  @HiveField(4)
  late String apartment;

  @HiveField(5)
  late String directions;

  @HiveField(6)
  late String nickname;

  @HiveField(7)
  late String receiverName;

  @HiveField(8)
  late String phoneNumber;

  @HiveField(9)
  late double latitude;

  @HiveField(10)
  late double longitude;

  @HiveField(11)
  late bool isDefault;

  @HiveField(12)
  late DateTime createdAt;

  @HiveField(13)
  late DateTime updatedAt;

  // New fields for enhanced functionality
  @HiveField(14)
  late String area;

  @HiveField(15)
  late String city;

  @HiveField(16)
  late String flatNumber;

  @HiveField(17)
  late String floorNumber;

  @HiveField(18)
  late bool isVerified;

  @HiveField(19)
  late String addressType; // apartment, villa, office, other

  @HiveField(20)
  late String deliveryInstructions;

  @HiveField(21)
  late String contactName;

  @HiveField(22)
  late String contactNumber;

  // Non-persistent field for distance calculation
  double? distanceFromUser;

  UserAddress({
    String? id,
    required this.label,
    required this.street,
    this.building = '',
    this.apartment = '',
    this.directions = '',
    this.nickname = '',
    required this.receiverName,
    required this.phoneNumber,
    required this.latitude,
    required this.longitude,
    this.isDefault = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.area = '',
    this.city = 'Dubai',
    this.flatNumber = '',
    this.floorNumber = '',
    this.isVerified = false,
    this.addressType = 'apartment',
    this.deliveryInstructions = '',
    String? contactName,
    String? contactNumber,
    this.distanceFromUser,
  }) {
    this.id = id ?? const Uuid().v4();
    this.createdAt = createdAt ?? DateTime.now();
    this.updatedAt = updatedAt ?? DateTime.now();
    this.contactName = contactName ?? receiverName;
    this.contactNumber = contactNumber ?? phoneNumber;
  }

  // Copy with method for easy updates
  UserAddress copyWith({
    String? id,
    String? label,
    String? street,
    String? building,
    String? apartment,
    String? directions,
    String? nickname,
    String? receiverName,
    String? phoneNumber,
    double? latitude,
    double? longitude,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? area,
    String? city,
    String? flatNumber,
    String? floorNumber,
    bool? isVerified,
    String? addressType,
    String? deliveryInstructions,
    String? contactName,
    String? contactNumber,
    double? distanceFromUser,
  }) {
    return UserAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      street: street ?? this.street,
      building: building ?? this.building,
      apartment: apartment ?? this.apartment,
      directions: directions ?? this.directions,
      nickname: nickname ?? this.nickname,
      receiverName: receiverName ?? this.receiverName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      area: area ?? this.area,
      city: city ?? this.city,
      flatNumber: flatNumber ?? this.flatNumber,
      floorNumber: floorNumber ?? this.floorNumber,
      isVerified: isVerified ?? this.isVerified,
      addressType: addressType ?? this.addressType,
      deliveryInstructions: deliveryInstructions ?? this.deliveryInstructions,
      contactName: contactName ?? this.contactName,
      contactNumber: contactNumber ?? this.contactNumber,
      distanceFromUser: distanceFromUser ?? this.distanceFromUser,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': label, // Backend uses 'title'
      'label': label,
      'streetName': street, // Backend uses 'streetName'
      'street': street,
      'buildingName': building, // Backend uses 'buildingName'
      'building': building,
      'apartment': apartment,
      'directions': directions,
      'nickname': nickname,
      'receiverName': receiverName,
      'phoneNumber': phoneNumber,
      'latitude': latitude,
      'longitude': longitude,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'area': area,
      'city': city,
      'flatNumber': flatNumber,
      'floorNumber': floorNumber,
      'landmark': directions, // Map directions to landmark
      'isVerified': isVerified,
      'addressType': addressType,
      'deliveryInstructions': deliveryInstructions,
      'contactName': contactName,
      'contactNumber': contactNumber,
      'fullAddress': formattedAddress,
    };
  }

  // Create from JSON
  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      id: json['id'] as String? ?? json['_id'] as String?,
      label: json['label'] as String? ?? json['title'] as String? ?? 'Other',
      street: json['street'] as String? ?? json['streetName'] as String? ?? '',
      building:
          json['building'] as String? ?? json['buildingName'] as String? ?? '',
      apartment: json['apartment'] as String? ?? '',
      directions:
          json['directions'] as String? ?? json['landmark'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      receiverName:
          json['receiverName'] as String? ??
          json['contactName'] as String? ??
          '',
      phoneNumber:
          json['phoneNumber'] as String? ??
          json['contactNumber'] as String? ??
          '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      area: json['area'] as String? ?? '',
      city: json['city'] as String? ?? 'Dubai',
      flatNumber: json['flatNumber'] as String? ?? '',
      floorNumber: json['floorNumber'] as String? ?? '',
      isVerified: json['isVerified'] as bool? ?? false,
      addressType: json['addressType'] as String? ?? 'apartment',
      deliveryInstructions: json['deliveryInstructions'] as String? ?? '',
      contactName: json['contactName'] as String?,
      contactNumber: json['contactNumber'] as String?,
      distanceFromUser: json['distanceFromUser'] as double?,
    );
  }

  // Get formatted address for display
  String get formattedAddress {
    final parts = <String>[];

    if (flatNumber.isNotEmpty) {
      parts.add('Flat $flatNumber');
    }
    if (floorNumber.isNotEmpty && flatNumber.isEmpty) {
      parts.add('Floor $floorNumber');
    }
    if (apartment.isNotEmpty && flatNumber.isEmpty) {
      parts.add('Apt $apartment');
    }
    if (building.isNotEmpty) {
      parts.add(building);
    }
    parts.add(street);
    if (area.isNotEmpty) {
      parts.add(area);
    }
    if (city.isNotEmpty) {
      parts.add(city);
    }

    return parts.join(', ');
  }

  // Get short address for list items
  String get shortAddress {
    if (nickname.isNotEmpty) return nickname;
    return formattedAddress;
  }

  // Get icon based on address type
  String get icon {
    switch (addressType) {
      case 'apartment':
        return 'apartment';
      case 'villa':
        return 'home';
      case 'office':
        return 'business';
      default:
        return 'location_on';
    }
  }

  // Get formatted distance from user
  String get formattedDistance {
    if (distanceFromUser == null) return '';

    if (distanceFromUser! < 1) {
      return '${(distanceFromUser! * 1000).round()}m';
    } else {
      return '${distanceFromUser!.toStringAsFixed(1)}km';
    }
  }

  @override
  String toString() {
    return 'UserAddress(id: $id, label: $label, street: $street, isDefault: $isDefault)';
  }
}

// Address label constants
class AddressLabel {
  static const String home = 'Home';
  static const String work = 'Work';
  static const String other = 'Other';

  static List<String> get all => [home, work, other];
}
