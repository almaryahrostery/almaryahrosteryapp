/// Location model for tracking
class LocationModel {
  final double lat;
  final double lng;
  final DateTime? updatedAt;
  final double? speed;
  final double? heading;

  const LocationModel({
    required this.lat,
    required this.lng,
    this.updatedAt,
    this.speed,
    this.heading,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      lat: (json['lat'] ?? json['latitude'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? json['longitude'] ?? 0.0).toDouble(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      speed: json['speed']?.toDouble(),
      heading: json['heading']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      'updatedAt': updatedAt?.toIso8601String(),
      if (speed != null) 'speed': speed,
      if (heading != null) 'heading': heading,
    };
  }

  LocationModel copyWith({
    double? lat,
    double? lng,
    DateTime? updatedAt,
    double? speed,
    double? heading,
  }) {
    return LocationModel(
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      updatedAt: updatedAt ?? this.updatedAt,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
    );
  }
}

/// Driver model
class DriverModel {
  final String id;
  final String name;
  final String phone;
  final String? vehicleModel;
  final String? vehiclePlate;
  final String? photoUrl;
  final double? rating;

  const DriverModel({
    required this.id,
    required this.name,
    required this.phone,
    this.vehicleModel,
    this.vehiclePlate,
    this.photoUrl,
    this.rating,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? 'Driver',
      phone: json['phone'] ?? '',
      vehicleModel: json['vehicleModel'],
      vehiclePlate: json['vehiclePlate'],
      photoUrl: json['photoUrl'],
      rating: json['rating']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      if (vehicleModel != null) 'vehicleModel': vehicleModel,
      if (vehiclePlate != null) 'vehiclePlate': vehiclePlate,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (rating != null) 'rating': rating,
    };
  }
}

/// Staff model
class StaffModel {
  final String id;
  final String name;
  final String phone;
  final String? photoUrl;

  const StaffModel({
    required this.id,
    required this.name,
    required this.phone,
    this.photoUrl,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? 'Staff',
      phone: json['phone'] ?? '',
      photoUrl: json['photoUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      if (photoUrl != null) 'photoUrl': photoUrl,
    };
  }
}

/// Delivery address model for tracking (renamed to avoid conflict with UserAddress)
class DeliveryAddressModel {
  final String id;
  final String label;
  final String fullAddress;
  final String? building;
  final String? street;
  final String? area;
  final String? city;
  final String? deliveryInstructions;
  final LocationModel location;

  const DeliveryAddressModel({
    required this.id,
    required this.label,
    required this.fullAddress,
    this.building,
    this.street,
    this.area,
    this.city,
    this.deliveryInstructions,
    required this.location,
  });

  factory DeliveryAddressModel.fromJson(Map<String, dynamic> json) {
    return DeliveryAddressModel(
      id: json['id'] ?? json['_id'] ?? '',
      label: json['label'] ?? json['title'] ?? 'Home',
      fullAddress: json['fullAddress'] ?? json['address'] ?? '',
      building: json['building'] ?? json['buildingName'],
      street: json['street'] ?? json['streetName'],
      area: json['area'],
      city: json['city'],
      deliveryInstructions: json['deliveryInstructions'],
      location: LocationModel.fromJson(
        json['location'] ?? json['gps'] ?? {'lat': 0, 'lng': 0},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'fullAddress': fullAddress,
      if (building != null) 'building': building,
      if (street != null) 'street': street,
      if (area != null) 'area': area,
      if (city != null) 'city': city,
      if (deliveryInstructions != null)
        'deliveryInstructions': deliveryInstructions,
      'location': location.toJson(),
    };
  }
}

/// Order timeline entry
class TimelineEntry {
  final String stage;
  final DateTime time;
  final String? message;

  const TimelineEntry({required this.stage, required this.time, this.message});

  factory TimelineEntry.fromJson(Map<String, dynamic> json) {
    return TimelineEntry(
      stage: json['stage'] ?? '',
      time: DateTime.parse(json['time']),
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stage': stage,
      'time': time.toIso8601String(),
      if (message != null) 'message': message,
    };
  }
}

/// ETA model
class ETAModel {
  final DateTime start;
  final DateTime end;
  final int? distanceMeters;
  final int? durationSeconds;

  const ETAModel({
    required this.start,
    required this.end,
    this.distanceMeters,
    this.durationSeconds,
  });

  factory ETAModel.fromJson(Map<String, dynamic> json) {
    return ETAModel(
      start: DateTime.parse(json['start']),
      end: DateTime.parse(json['end']),
      distanceMeters: json['distanceMeters'],
      durationSeconds: json['durationSeconds'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      if (distanceMeters != null) 'distanceMeters': distanceMeters,
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
    };
  }

  /// Get status label based on current time vs ETA
  String getStatusLabel() {
    final now = DateTime.now();
    if (now.isBefore(start)) {
      return 'On Time';
    } else if (now.isBefore(end)) {
      return 'Slight delay';
    } else {
      return 'Delayed';
    }
  }

  /// Get time remaining in minutes
  int getMinutesRemaining() {
    final now = DateTime.now();
    final diff = end.difference(now);
    return diff.inMinutes.clamp(0, 999);
  }
}

/// Order status enum
enum OrderStatus {
  acceptedByStaff('accepted_by_staff'),
  preparing('preparing'),
  readyForHandover('ready_for_handover'),
  pickedByDriver('picked_by_driver'),
  onTheWay('on_the_way'),
  arriving('arriving'),
  delivered('delivered'),
  cancelled('cancelled');

  final String value;
  const OrderStatus(this.value);

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => OrderStatus.preparing,
    );
  }

  String get displayName {
    switch (this) {
      case OrderStatus.acceptedByStaff:
        return 'Accepted by Staff';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.readyForHandover:
        return 'Ready for Handover';
      case OrderStatus.pickedByDriver:
        return 'Picked by Driver';
      case OrderStatus.onTheWay:
        return 'On the Way';
      case OrderStatus.arriving:
        return 'Arriving';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get userMessage {
    switch (this) {
      case OrderStatus.acceptedByStaff:
        return 'Your order has been accepted and will be prepared shortly.';
      case OrderStatus.preparing:
        return 'Our staff is preparing your order. It will be handed to a driver shortly.';
      case OrderStatus.readyForHandover:
        return 'Order is ready and waiting for driver pickup.';
      case OrderStatus.pickedByDriver:
        return 'Driver has picked up your order and is heading your way.';
      case OrderStatus.onTheWay:
        return 'Your order is on the way to your location.';
      case OrderStatus.arriving:
        return 'Driver is arriving at your location now!';
      case OrderStatus.delivered:
        return 'Your order has been delivered. Enjoy!';
      case OrderStatus.cancelled:
        return 'This order has been cancelled.';
    }
  }

  int get progressValue {
    switch (this) {
      case OrderStatus.acceptedByStaff:
        return 1;
      case OrderStatus.preparing:
        return 2;
      case OrderStatus.readyForHandover:
        return 3;
      case OrderStatus.pickedByDriver:
        return 4;
      case OrderStatus.onTheWay:
        return 5;
      case OrderStatus.arriving:
        return 6;
      case OrderStatus.delivered:
        return 7;
      case OrderStatus.cancelled:
        return 0;
    }
  }
}

/// Main live order tracking model
class LiveOrderTracking {
  final String orderId;
  OrderStatus status;
  ETAModel? eta;
  LocationModel? staffLocation;
  LocationModel? driverLocation;
  LocationModel userLocation;
  DriverModel? driver;
  StaffModel? staff;
  DeliveryAddressModel address;
  List<TimelineEntry> timeline;
  bool isDriverStationary;
  DateTime lastUpdate;

  LiveOrderTracking({
    required this.orderId,
    required this.status,
    this.eta,
    this.staffLocation,
    this.driverLocation,
    required this.userLocation,
    this.driver,
    this.staff,
    required this.address,
    this.timeline = const [],
    this.isDriverStationary = false,
    required this.lastUpdate,
  });

  factory LiveOrderTracking.fromJson(Map<String, dynamic> json) {
    return LiveOrderTracking(
      orderId: json['orderId'] ?? json['_id'] ?? '',
      status: OrderStatus.fromString(json['status'] ?? 'preparing'),
      eta: json['eta'] != null ? ETAModel.fromJson(json['eta']) : null,
      staffLocation: json['staffLocation'] != null
          ? LocationModel.fromJson(json['staffLocation'])
          : null,
      driverLocation: json['driverLocation'] != null
          ? LocationModel.fromJson(json['driverLocation'])
          : null,
      userLocation: LocationModel.fromJson(
        json['userLocation'] ??
            json['deliveryAddress']?['location'] ??
            {'lat': 0, 'lng': 0},
      ),
      driver: json['driver'] != null
          ? DriverModel.fromJson(json['driver'])
          : null,
      staff: json['staff'] != null ? StaffModel.fromJson(json['staff']) : null,
      address: DeliveryAddressModel.fromJson(
        json['deliveryAddress'] ?? json['address'] ?? {},
      ),
      timeline:
          (json['timeline'] as List<dynamic>?)
              ?.map((e) => TimelineEntry.fromJson(e))
              .toList() ??
          [],
      isDriverStationary: json['isDriverStationary'] ?? false,
      lastUpdate: json['lastUpdate'] != null
          ? DateTime.parse(json['lastUpdate'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'status': status.value,
      if (eta != null) 'eta': eta!.toJson(),
      if (staffLocation != null) 'staffLocation': staffLocation!.toJson(),
      if (driverLocation != null) 'driverLocation': driverLocation!.toJson(),
      'userLocation': userLocation.toJson(),
      if (driver != null) 'driver': driver!.toJson(),
      if (staff != null) 'staff': staff!.toJson(),
      'address': address.toJson(),
      'timeline': timeline.map((e) => e.toJson()).toList(),
      'isDriverStationary': isDriverStationary,
      'lastUpdate': lastUpdate.toIso8601String(),
    };
  }

  LiveOrderTracking copyWith({
    String? orderId,
    OrderStatus? status,
    ETAModel? eta,
    LocationModel? staffLocation,
    LocationModel? driverLocation,
    LocationModel? userLocation,
    DriverModel? driver,
    StaffModel? staff,
    DeliveryAddressModel? address,
    List<TimelineEntry>? timeline,
    bool? isDriverStationary,
    DateTime? lastUpdate,
  }) {
    return LiveOrderTracking(
      orderId: orderId ?? this.orderId,
      status: status ?? this.status,
      eta: eta ?? this.eta,
      staffLocation: staffLocation ?? this.staffLocation,
      driverLocation: driverLocation ?? this.driverLocation,
      userLocation: userLocation ?? this.userLocation,
      driver: driver ?? this.driver,
      staff: staff ?? this.staff,
      address: address ?? this.address,
      timeline: timeline ?? this.timeline,
      isDriverStationary: isDriverStationary ?? this.isDriverStationary,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }

  /// Check if driver has picked up the order
  bool get isPickedUp {
    return status == OrderStatus.pickedByDriver ||
        status == OrderStatus.onTheWay ||
        status == OrderStatus.arriving ||
        status == OrderStatus.delivered;
  }

  /// Check if order is completed
  bool get isCompleted {
    return status == OrderStatus.delivered || status == OrderStatus.cancelled;
  }

  /// Check if driver is active
  bool get hasActiveDriver {
    return driver != null && driverLocation != null && isPickedUp;
  }
}
