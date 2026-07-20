import 'package:equatable/equatable.dart';

/// User role enum
enum UserRole { customer, worker, admin }

/// Customer model
class CustomerModel extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String? profileImage;
  final String? contactPhone;
  final List<AddressModel> addresses;
  final String preferredLanguage;
  final int totalBookings;

  const CustomerModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profileImage,
    this.contactPhone,
    this.addresses = const [],
    this.preferredLanguage = 'en',
    this.totalBookings = 0,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['_id'] ?? json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      profileImage: json['profileImage'],
      contactPhone: json['contactPhone'],
      addresses:
          (json['addresses'] as List?)
              ?.map((a) => AddressModel.fromJson(a))
              .toList() ??
          [],
      preferredLanguage: json['preferredLanguage'] ?? 'en',
      totalBookings: json['totalBookings'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'firstName': firstName,
      'lastName': lastName,
      'profileImage': profileImage,
      'contactPhone': contactPhone,
      'addresses': addresses.map((a) => a.toJson()).toList(),
      'preferredLanguage': preferredLanguage,
      'totalBookings': totalBookings,
    };
  }

  String get fullName => '$firstName $lastName';

  CustomerModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? profileImage,
    String? contactPhone,
    List<AddressModel>? addresses,
    String? preferredLanguage,
    int? totalBookings,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      profileImage: profileImage ?? this.profileImage,
      contactPhone: contactPhone ?? this.contactPhone,
      addresses: addresses ?? this.addresses,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      totalBookings: totalBookings ?? this.totalBookings,
    );
  }

  @override
  List<Object?> get props => [
    id,
    firstName,
    lastName,
    profileImage,
    contactPhone,
    addresses,
    preferredLanguage,
    totalBookings,
  ];
}

/// Address model
class AddressModel extends Equatable {
  final String? id;
  final String label;
  final String address;
  final String city;
  final CoordinatesModel? coordinates;
  final bool isDefault;

  const AddressModel({
    this.id,
    required this.label,
    required this.address,
    required this.city,
    this.coordinates,
    this.isDefault = false,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['_id'],
      label: json['label'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      coordinates: json['coordinates'] != null
          ? CoordinatesModel.fromJson(json['coordinates'])
          : null,
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'label': label,
      'address': address,
      'city': city,
      if (coordinates != null) 'coordinates': coordinates!.toJson(),
      'isDefault': isDefault,
    };
  }

  AddressModel copyWith({
    String? id,
    String? label,
    String? address,
    String? city,
    CoordinatesModel? coordinates,
    bool? isDefault,
  }) {
    return AddressModel(
      id: id ?? this.id,
      label: label ?? this.label,
      address: address ?? this.address,
      city: city ?? this.city,
      coordinates: coordinates ?? this.coordinates,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  List<Object?> get props => [id, label, address, city, coordinates, isDefault];
}

/// Coordinates model
class CoordinatesModel extends Equatable {
  final double lat;
  final double lng;

  const CoordinatesModel({required this.lat, required this.lng});

  factory CoordinatesModel.fromJson(Map<String, dynamic> json) {
    return CoordinatesModel(
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'lat': lat, 'lng': lng};
  }

  @override
  List<Object?> get props => [lat, lng];
}

/// User model containing auth info and profile
class UserModel extends Equatable {
  final String id;
  final UserRole role;
  final String email;
  final String? phone;
  final bool isVerified;
  final bool isActive;
  final CustomerModel? customer;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    required this.role,
    required this.email,
    this.phone,
    this.isVerified = false,
    this.isActive = true,
    this.customer,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      role: _parseRole(json['role']),
      email: json['email'] ?? '',
      phone: json['phone'],
      isVerified: json['isVerified'] ?? false,
      isActive: json['isActive'] ?? true,
      customer: json['customer'] != null
          ? CustomerModel.fromJson(json['customer'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  static UserRole _parseRole(String? role) {
    switch (role?.toLowerCase()) {
      case 'customer':
        return UserRole.customer;
      case 'worker':
        return UserRole.worker;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.customer;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'role': role.name.toUpperCase(),
      'email': email,
      'phone': phone,
      'isVerified': isVerified,
      'isActive': isActive,
      'customer': customer?.toJson(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  String get displayName => customer?.fullName ?? email;

  UserModel copyWith({
    String? id,
    UserRole? role,
    String? email,
    String? phone,
    bool? isVerified,
    bool? isActive,
    CustomerModel? customer,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      role: role ?? this.role,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      customer: customer ?? this.customer,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    role,
    email,
    phone,
    isVerified,
    isActive,
    customer,
    createdAt,
    updatedAt,
  ];
}
