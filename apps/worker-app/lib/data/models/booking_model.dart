import 'worker_model.dart';

class BookingAddress {
  final String full;
  final String city;
  final Coordinates coordinates;

  BookingAddress({
    required this.full,
    required this.city,
    required this.coordinates,
  });

  factory BookingAddress.fromJson(Map<String, dynamic> json) {
    return BookingAddress(
      full: json['full'] ?? '',
      city: json['city'] ?? '',
      coordinates: Coordinates.fromJson(json['coordinates'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {'full': full, 'city': city, 'coordinates': coordinates.toJson()};
  }
}

class BookingPricing {
  final double? estimatedPrice;
  final double? finalPrice;
  final double? laborCost;
  final double? materialsCost;
  final double? platformFee;
  final double? discount;

  BookingPricing({
    this.estimatedPrice,
    this.finalPrice,
    this.laborCost,
    this.materialsCost,
    this.platformFee,
    this.discount,
  });

  factory BookingPricing.fromJson(Map<String, dynamic> json) {
    return BookingPricing(
      estimatedPrice: (json['estimatedPrice'] ?? 0).toDouble(),
      finalPrice: (json['finalPrice'] ?? 0).toDouble(),
      laborCost: (json['laborCost'] ?? 0).toDouble(),
      materialsCost: (json['materialsCost'] ?? 0).toDouble(),
      platformFee: (json['platformFee'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'estimatedPrice': estimatedPrice,
      'finalPrice': finalPrice,
      'laborCost': laborCost,
      'materialsCost': materialsCost,
      'platformFee': platformFee,
      'discount': discount,
    };
  }
}

class BookingTimeline {
  final String status;
  final DateTime timestamp;
  final String? note;

  BookingTimeline({required this.status, required this.timestamp, this.note});

  factory BookingTimeline.fromJson(Map<String, dynamic> json) {
    return BookingTimeline(
      status: json['status'] ?? '',
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'note': note,
    };
  }
}

class CustomerInfo {
  final String id;
  final String firstName;
  final String lastName;
  final String? profileImage;
  final String phone;
  final String? contactPhone;

  CustomerInfo({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profileImage,
    required this.phone,
    this.contactPhone,
  });

  factory CustomerInfo.fromJson(Map<String, dynamic> json) {
    // `user` is populated as a full object by some endpoints (e.g. booking
    // details) but left as a raw ObjectId string by others (e.g. accept,
    // which only populates 'user firstName lastName' without expanding
    // the user ref) — guard against both shapes.
    final userField = json['user'];
    final userPhone = userField is Map ? userField['phone'] : null;
    return CustomerInfo(
      id: json['_id'] ?? json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      profileImage: json['profileImage'],
      phone: userPhone ?? json['phone'] ?? '',
      contactPhone: json['contactPhone'],
    );
  }

  String get fullName => '$firstName $lastName';

  /// Prefer the customer's optional alternate contact number over their
  /// login phone for calling purposes.
  String? get callablePhone =>
      (contactPhone != null && contactPhone!.isNotEmpty) ? contactPhone : phone;

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'firstName': firstName,
      'lastName': lastName,
      'profileImage': profileImage,
      'phone': phone,
      'contactPhone': contactPhone,
    };
  }
}

class BookingModel {
  final String id;
  final String bookingNumber;
  final CustomerInfo customer;
  final String? workerId;
  final String serviceCategory;
  final String problemDescription;
  final List<String>? aiDetectedServices;
  final BookingAddress address;
  final DateTime scheduledDateTime;
  final bool isUrgent;
  final String status;
  final BookingPricing pricing;
  final int? estimatedDuration;
  final int? actualDuration;
  final List<BookingTimeline> timeline;
  final List<String>? beforeImages;
  final List<String>? afterImages;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookingModel({
    required this.id,
    required this.bookingNumber,
    required this.customer,
    this.workerId,
    required this.serviceCategory,
    required this.problemDescription,
    this.aiDetectedServices,
    required this.address,
    required this.scheduledDateTime,
    required this.isUrgent,
    required this.status,
    required this.pricing,
    this.estimatedDuration,
    this.actualDuration,
    required this.timeline,
    this.beforeImages,
    this.afterImages,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['_id'] ?? json['id'] ?? '',
      bookingNumber: json['bookingNumber'] ?? '',
      customer: CustomerInfo.fromJson(json['customer'] ?? {}),
      // `worker` is a populated object on some endpoints and a raw ObjectId
      // string on others (e.g. the accept response) — only ever store the id.
      workerId: json['worker'] is Map
          ? (json['worker']['_id'] ?? json['worker']['id'])
          : json['worker'],
      serviceCategory: json['serviceCategory'] ?? '',
      problemDescription: json['problemDescription'] ?? '',
      aiDetectedServices: (json['aiDetectedServices'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      address: BookingAddress.fromJson(json['address'] ?? {}),
      scheduledDateTime: DateTime.parse(
        json['scheduledDateTime'] ?? DateTime.now().toIso8601String(),
      ),
      isUrgent: json['isUrgent'] ?? false,
      status: json['status'] ?? 'PENDING',
      pricing: BookingPricing.fromJson(json['pricing'] ?? {}),
      estimatedDuration: json['estimatedDuration'],
      actualDuration: json['actualDuration'],
      timeline:
          (json['timeline'] as List<dynamic>?)
              ?.map((e) => BookingTimeline.fromJson(e))
              .toList() ??
          [],
      beforeImages: (json['images']?['before'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      afterImages: (json['images']?['after'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  bool get isPending => status == 'PENDING';
  bool get isAccepted => status == 'ACCEPTED';
  bool get isInProgress => status == 'IN_PROGRESS';
  bool get isCompleted => status == 'COMPLETED';
  bool get isCancelled => status == 'CANCELLED';

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'bookingNumber': bookingNumber,
      'customer': customer.toJson(),
      'worker': workerId,
      'serviceCategory': serviceCategory,
      'problemDescription': problemDescription,
      'aiDetectedServices': aiDetectedServices,
      'address': address.toJson(),
      'scheduledDateTime': scheduledDateTime.toIso8601String(),
      'isUrgent': isUrgent,
      'status': status,
      'pricing': pricing.toJson(),
      'estimatedDuration': estimatedDuration,
      'actualDuration': actualDuration,
      'timeline': timeline.map((e) => e.toJson()).toList(),
      'images': {'before': beforeImages, 'after': afterImages},
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
