import 'package:equatable/equatable.dart';
import 'user_model.dart';

/// Booking status enum
enum BookingStatus {
  pending,
  accepted,
  inProgress,
  completed,
  cancelled,
  disputed,
}

/// Payment status enum
enum PaymentStatus { pending, completed, refunded }

/// Payment method enum
enum PaymentMethod { cash, wallet, card }

/// Booking model
class BookingModel extends Equatable {
  final String id;
  final String bookingNumber;
  final String customerId;
  final String? workerId;
  final String serviceCategory;
  final String problemDescription;
  final List<String> aiDetectedServices;
  final BookingAddress address;
  final DateTime scheduledDateTime;
  final bool isUrgent;
  final BookingStatus status;
  final BookingPricing pricing;
  final int? estimatedDuration;
  final int? actualDuration;
  final List<BookingTimeline> timeline;
  final BookingPayment? payment;
  final BookingRating? rating;
  final BookingImages? images;
  final BookingCancellation? cancellation;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Populated fields
  final CustomerModel? customer;
  final WorkerBasicInfo? worker;

  const BookingModel({
    required this.id,
    required this.bookingNumber,
    required this.customerId,
    this.workerId,
    required this.serviceCategory,
    required this.problemDescription,
    this.aiDetectedServices = const [],
    required this.address,
    required this.scheduledDateTime,
    this.isUrgent = false,
    required this.status,
    required this.pricing,
    this.estimatedDuration,
    this.actualDuration,
    this.timeline = const [],
    this.payment,
    this.rating,
    this.images,
    this.cancellation,
    required this.createdAt,
    required this.updatedAt,
    this.customer,
    this.worker,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['_id'] ?? json['id'] ?? '',
      bookingNumber: json['bookingNumber'] ?? '',
      customerId: json['customer'] is String
          ? json['customer']
          : json['customer']?['_id'] ?? '',
      workerId: json['worker'] is String
          ? json['worker']
          : json['worker']?['_id'],
      serviceCategory: json['serviceCategory'] ?? '',
      problemDescription: json['problemDescription'] ?? '',
      aiDetectedServices: List<String>.from(json['aiDetectedServices'] ?? []),
      address: BookingAddress.fromJson(json['address'] ?? {}),
      scheduledDateTime: json['scheduledDateTime'] != null
          ? DateTime.parse(json['scheduledDateTime'])
          : DateTime.now(),
      isUrgent: json['isUrgent'] ?? false,
      status: _parseStatus(json['status']),
      pricing: BookingPricing.fromJson(json['pricing'] ?? {}),
      estimatedDuration: json['estimatedDuration'],
      actualDuration: json['actualDuration'],
      timeline:
          (json['timeline'] as List?)
              ?.map((t) => BookingTimeline.fromJson(t))
              .toList() ??
          [],
      payment: json['payment'] != null
          ? BookingPayment.fromJson(json['payment'])
          : null,
      rating: json['rating'] != null
          ? BookingRating.fromJson(json['rating'])
          : null,
      images: json['images'] != null
          ? BookingImages.fromJson(json['images'])
          : null,
      cancellation: json['cancellation'] != null
          ? BookingCancellation.fromJson(json['cancellation'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      customer: json['customer'] is Map
          ? CustomerModel.fromJson(json['customer'])
          : null,
      worker: json['worker'] is Map
          ? WorkerBasicInfo.fromJson(json['worker'])
          : null,
    );
  }

  static BookingStatus _parseStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'PENDING':
        return BookingStatus.pending;
      case 'ACCEPTED':
        return BookingStatus.accepted;
      case 'IN_PROGRESS':
        return BookingStatus.inProgress;
      case 'COMPLETED':
        return BookingStatus.completed;
      case 'CANCELLED':
        return BookingStatus.cancelled;
      case 'DISPUTED':
        return BookingStatus.disputed;
      default:
        return BookingStatus.pending;
    }
  }

  String get statusDisplayName {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.accepted:
        return 'Accepted';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.disputed:
        return 'Disputed';
    }
  }

  @override
  List<Object?> get props => [
    id,
    bookingNumber,
    customerId,
    workerId,
    serviceCategory,
    problemDescription,
    status,
    scheduledDateTime,
  ];
}

/// Booking address
class BookingAddress extends Equatable {
  final String full;
  final String city;
  final CoordinatesModel? coordinates;

  const BookingAddress({
    required this.full,
    required this.city,
    this.coordinates,
  });

  factory BookingAddress.fromJson(Map<String, dynamic> json) {
    return BookingAddress(
      full: json['full'] ?? '',
      city: json['city'] ?? '',
      coordinates: json['coordinates'] != null
          ? CoordinatesModel.fromJson(json['coordinates'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full': full,
      'city': city,
      if (coordinates != null) 'coordinates': coordinates!.toJson(),
    };
  }

  @override
  List<Object?> get props => [full, city, coordinates];
}

/// Booking pricing
class BookingPricing extends Equatable {
  final double? estimatedPrice;
  final double? finalPrice;
  final double? laborCost;
  final double? materialsCost;
  final double? platformFee;
  final double? discount;

  const BookingPricing({
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
      finalPrice: json['finalPrice']?.toDouble(),
      laborCost: json['laborCost']?.toDouble(),
      materialsCost: json['materialsCost']?.toDouble(),
      platformFee: json['platformFee']?.toDouble(),
      discount: json['discount']?.toDouble(),
    );
  }

  double get total => finalPrice ?? estimatedPrice ?? 0;

  @override
  List<Object?> get props => [
    estimatedPrice,
    finalPrice,
    laborCost,
    materialsCost,
    platformFee,
    discount,
  ];
}

/// Booking timeline entry
class BookingTimeline extends Equatable {
  final String status;
  final DateTime timestamp;
  final String? note;

  const BookingTimeline({
    required this.status,
    required this.timestamp,
    this.note,
  });

  factory BookingTimeline.fromJson(Map<String, dynamic> json) {
    return BookingTimeline(
      status: json['status'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      note: json['note'],
    );
  }

  @override
  List<Object?> get props => [status, timestamp, note];
}

/// Booking payment info
class BookingPayment extends Equatable {
  final PaymentMethod method;
  final PaymentStatus status;
  final String? transactionId;

  const BookingPayment({
    required this.method,
    required this.status,
    this.transactionId,
  });

  factory BookingPayment.fromJson(Map<String, dynamic> json) {
    return BookingPayment(
      method: _parsePaymentMethod(json['method']),
      status: _parsePaymentStatus(json['status']),
      transactionId: json['transactionId'],
    );
  }

  static PaymentMethod _parsePaymentMethod(String? method) {
    switch (method?.toUpperCase()) {
      case 'WALLET':
        return PaymentMethod.wallet;
      case 'CARD':
        return PaymentMethod.card;
      default:
        return PaymentMethod.cash;
    }
  }

  static PaymentStatus _parsePaymentStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'COMPLETED':
        return PaymentStatus.completed;
      case 'REFUNDED':
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.pending;
    }
  }

  @override
  List<Object?> get props => [method, status, transactionId];
}

/// Booking rating
class BookingRating extends Equatable {
  final int score;
  final String? review;
  final DateTime? createdAt;

  const BookingRating({required this.score, this.review, this.createdAt});

  factory BookingRating.fromJson(Map<String, dynamic> json) {
    return BookingRating(
      score: _parseIntSafe(json['score']) ?? 0,
      review: json['review'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  static int? _parseIntSafe(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  @override
  List<Object?> get props => [score, review, createdAt];
}

/// Booking images
class BookingImages extends Equatable {
  final List<String> before;
  final List<String> after;

  const BookingImages({this.before = const [], this.after = const []});

  factory BookingImages.fromJson(Map<String, dynamic> json) {
    return BookingImages(
      before: List<String>.from(json['before'] ?? []),
      after: List<String>.from(json['after'] ?? []),
    );
  }

  @override
  List<Object?> get props => [before, after];
}

/// Booking cancellation info
class BookingCancellation extends Equatable {
  final String cancelledBy;
  final String reason;
  final DateTime timestamp;

  const BookingCancellation({
    required this.cancelledBy,
    required this.reason,
    required this.timestamp,
  });

  factory BookingCancellation.fromJson(Map<String, dynamic> json) {
    return BookingCancellation(
      cancelledBy: json['cancelledBy'] ?? '',
      reason: json['reason'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [cancelledBy, reason, timestamp];
}

/// Worker basic info for booking display
class WorkerBasicInfo extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String? profileImage;
  final String? phone;
  final String? contactPhone;
  final double rating;
  final int totalJobs;

  const WorkerBasicInfo({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profileImage,
    this.phone,
    this.contactPhone,
    this.rating = 0,
    this.totalJobs = 0,
  });

  factory WorkerBasicInfo.fromJson(Map<String, dynamic> json) {
    final ratingData = json['rating'] ?? {};
    return WorkerBasicInfo(
      id: json['_id'] ?? json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      profileImage: json['profileImage'],
      phone: json['user']?['phone'] ?? json['phone'],
      contactPhone: json['contactPhone'],
      rating: (ratingData['average'] ?? 0).toDouble(),
      totalJobs: json['totalJobsCompleted'] ?? 0,
    );
  }

  String get fullName => '$firstName $lastName';

  /// Prefer the worker's optional alternate contact number over their
  /// login phone for calling purposes.
  String? get callablePhone =>
      (contactPhone != null && contactPhone!.isNotEmpty) ? contactPhone : phone;

  @override
  List<Object?> get props => [
    id,
    firstName,
    lastName,
    profileImage,
    phone,
    contactPhone,
    rating,
    totalJobs,
  ];
}

/// Booking create request
class BookingCreateRequest extends Equatable {
  final String serviceCategory;
  final String problemDescription;
  final BookingAddress address;
  final DateTime scheduledDateTime;
  final bool isUrgent;
  final List<String>? images;
  final String paymentMethod; // CASH, WALLET, CARD

  const BookingCreateRequest({
    required this.serviceCategory,
    required this.problemDescription,
    required this.address,
    required this.scheduledDateTime,
    this.isUrgent = false,
    this.images,
    this.paymentMethod = 'CASH',
  });

  Map<String, dynamic> toJson() {
    return {
      'serviceCategory': serviceCategory,
      'problemDescription': problemDescription,
      'address': address.toJson(),
      'scheduledDateTime': scheduledDateTime.toIso8601String(),
      'isUrgent': isUrgent,
      'paymentMethod': paymentMethod,
      if (images != null) 'images': images,
    };
  }

  BookingCreateRequest copyWith({
    String? serviceCategory,
    String? problemDescription,
    BookingAddress? address,
    DateTime? scheduledDateTime,
    bool? isUrgent,
    List<String>? images,
    String? paymentMethod,
  }) {
    return BookingCreateRequest(
      serviceCategory: serviceCategory ?? this.serviceCategory,
      problemDescription: problemDescription ?? this.problemDescription,
      address: address ?? this.address,
      scheduledDateTime: scheduledDateTime ?? this.scheduledDateTime,
      isUrgent: isUrgent ?? this.isUrgent,
      images: images ?? this.images,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  @override
  List<Object?> get props => [
    serviceCategory,
    problemDescription,
    address,
    scheduledDateTime,
    isUrgent,
    images,
    paymentMethod,
  ];
}
