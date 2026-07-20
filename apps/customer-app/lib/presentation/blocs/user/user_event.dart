import 'package:equatable/equatable.dart';

/// User profile events
abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

/// Load user profile event
class LoadProfileRequested extends UserEvent {
  const LoadProfileRequested();
}

/// Update user profile event
class UpdateProfileRequested extends UserEvent {
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? contactPhone;
  final String? profileImage;
  final String? preferredLanguage;

  const UpdateProfileRequested({
    this.firstName,
    this.lastName,
    this.email,
    this.contactPhone,
    this.profileImage,
    this.preferredLanguage,
  });

  @override
  List<Object?> get props => [
    firstName,
    lastName,
    email,
    contactPhone,
    profileImage,
    preferredLanguage,
  ];
}

/// Load addresses event
class LoadAddressesRequested extends UserEvent {
  const LoadAddressesRequested();
}

/// Add address event
class AddAddressRequested extends UserEvent {
  final String label;
  final String address;
  final String city;
  final double? lat;
  final double? lng;
  final bool isDefault;

  const AddAddressRequested({
    required this.label,
    required this.address,
    required this.city,
    this.lat,
    this.lng,
    this.isDefault = false,
  });

  @override
  List<Object?> get props => [label, address, city, lat, lng, isDefault];
}

/// Update address event
class UpdateAddressRequested extends UserEvent {
  final String addressId;
  final String? label;
  final String? address;
  final String? city;

  const UpdateAddressRequested({
    required this.addressId,
    this.label,
    this.address,
    this.city,
  });

  @override
  List<Object?> get props => [addressId, label, address, city];
}

/// Delete address event
class DeleteAddressRequested extends UserEvent {
  final String addressId;

  const DeleteAddressRequested({required this.addressId});

  @override
  List<Object?> get props => [addressId];
}

/// Set default address event
class SetDefaultAddressRequested extends UserEvent {
  final String addressId;

  const SetDefaultAddressRequested({required this.addressId});

  @override
  List<Object?> get props => [addressId];
}

/// Clear user data event (on logout)
class ClearUserDataRequested extends UserEvent {
  const ClearUserDataRequested();
}

/// Delete account event
class DeleteAccountRequested extends UserEvent {
  const DeleteAccountRequested();
}
