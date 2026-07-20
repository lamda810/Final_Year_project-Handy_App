import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../../data/models/user_model.dart';
import 'user_event.dart';
import 'user_state.dart';

/// User BLoC for managing user profile state
class UserBloc extends Bloc<UserEvent, UserState> {
  final UserRepository _userRepository;

  CustomerModel? _cachedProfile;
  List<AddressModel> _cachedAddresses = [];

  UserBloc({required UserRepository userRepository})
    : _userRepository = userRepository,
      super(const UserInitial()) {
    on<LoadProfileRequested>(_onLoadProfile);
    on<UpdateProfileRequested>(_onUpdateProfile);
    on<LoadAddressesRequested>(_onLoadAddresses);
    on<AddAddressRequested>(_onAddAddress);
    on<UpdateAddressRequested>(_onUpdateAddress);
    on<DeleteAddressRequested>(_onDeleteAddress);
    on<SetDefaultAddressRequested>(_onSetDefaultAddress);
    on<ClearUserDataRequested>(_onClearUserData);
    on<DeleteAccountRequested>(_onDeleteAccount);
  }

  /// Get cached profile
  CustomerModel? get cachedProfile => _cachedProfile;

  /// Get cached addresses
  List<AddressModel> get cachedAddresses => _cachedAddresses;

  Future<void> _onLoadProfile(
    LoadProfileRequested event,
    Emitter<UserState> emit,
  ) async {
    emit(const UserLoading(message: 'Loading profile...'));

    try {
      final profile = await _userRepository.getProfile();
      _cachedProfile = profile;
      _cachedAddresses = profile.addresses;

      emit(UserProfileLoaded(profile: profile, addresses: profile.addresses));
    } catch (e) {
      emit(UserError(message: ErrorMapper.toUserMessage(e)));
    }
  }

  Future<void> _onUpdateProfile(
    UpdateProfileRequested event,
    Emitter<UserState> emit,
  ) async {
    emit(const UserLoading(message: 'Updating profile...'));

    try {
      final profile = await _userRepository.updateProfile(
        firstName: event.firstName,
        lastName: event.lastName,
        email: event.email,
        contactPhone: event.contactPhone,
        profileImage: event.profileImage,
        preferredLanguage: event.preferredLanguage,
      );
      _cachedProfile = profile;

      emit(UserProfileUpdated(profile: profile));

      // Return to loaded state
      emit(UserProfileLoaded(profile: profile, addresses: _cachedAddresses));
    } catch (e) {
      emit(UserError(message: ErrorMapper.toUserMessage(e)));

      // Return to previous state if profile exists
      if (_cachedProfile != null) {
        emit(
          UserProfileLoaded(
            profile: _cachedProfile!,
            addresses: _cachedAddresses,
          ),
        );
      }
    }
  }

  Future<void> _onLoadAddresses(
    LoadAddressesRequested event,
    Emitter<UserState> emit,
  ) async {
    try {
      final addresses = await _userRepository.getAddresses();
      _cachedAddresses = addresses;

      if (_cachedProfile != null) {
        emit(UserProfileLoaded(profile: _cachedProfile!, addresses: addresses));
      }
    } catch (e) {
      emit(UserError(message: ErrorMapper.toUserMessage(e)));
    }
  }

  Future<void> _onAddAddress(
    AddAddressRequested event,
    Emitter<UserState> emit,
  ) async {
    emit(const UserLoading(message: 'Adding address...'));

    try {
      // Create AddressModel from event fields
      final addressToAdd = AddressModel(
        label: event.label,
        address: event.address,
        city: event.city,
        coordinates: event.lat != null && event.lng != null
            ? CoordinatesModel(lat: event.lat!, lng: event.lng!)
            : null,
        isDefault: event.isDefault,
      );

      _cachedAddresses = await _userRepository.addAddress(addressToAdd);

      emit(
        AddressActionSuccess(
          addresses: _cachedAddresses,
          message: 'Address added successfully',
        ),
      );

      if (_cachedProfile != null) {
        emit(
          UserProfileLoaded(
            profile: _cachedProfile!,
            addresses: _cachedAddresses,
          ),
        );
      }
    } catch (e) {
      emit(UserError(message: ErrorMapper.toUserMessage(e)));
    }
  }

  Future<void> _onUpdateAddress(
    UpdateAddressRequested event,
    Emitter<UserState> emit,
  ) async {
    emit(const UserLoading(message: 'Updating address...'));

    try {
      // Find existing address to merge with updates
      final existingAddress = _cachedAddresses.firstWhere(
        (addr) => addr.id == event.addressId,
        orElse: () => AddressModel(
          id: event.addressId,
          label: event.label ?? '',
          address: event.address ?? '',
          city: event.city ?? '',
        ),
      );

      // Create updated AddressModel with merged values
      final addressToUpdate = existingAddress.copyWith(
        label: event.label,
        address: event.address,
        city: event.city,
      );

      _cachedAddresses = await _userRepository.updateAddress(
        event.addressId,
        addressToUpdate,
      );

      emit(
        AddressActionSuccess(
          addresses: _cachedAddresses,
          message: 'Address updated successfully',
        ),
      );

      if (_cachedProfile != null) {
        emit(
          UserProfileLoaded(
            profile: _cachedProfile!,
            addresses: _cachedAddresses,
          ),
        );
      }
    } catch (e) {
      emit(UserError(message: ErrorMapper.toUserMessage(e)));
    }
  }

  Future<void> _onDeleteAddress(
    DeleteAddressRequested event,
    Emitter<UserState> emit,
  ) async {
    emit(const UserLoading(message: 'Deleting address...'));

    try {
      await _userRepository.deleteAddress(event.addressId);

      _cachedAddresses = _cachedAddresses
          .where((addr) => addr.id != event.addressId)
          .toList();

      emit(
        AddressActionSuccess(
          addresses: _cachedAddresses,
          message: 'Address deleted successfully',
        ),
      );

      if (_cachedProfile != null) {
        emit(
          UserProfileLoaded(
            profile: _cachedProfile!,
            addresses: _cachedAddresses,
          ),
        );
      }
    } catch (e) {
      emit(UserError(message: ErrorMapper.toUserMessage(e)));
    }
  }

  Future<void> _onSetDefaultAddress(
    SetDefaultAddressRequested event,
    Emitter<UserState> emit,
  ) async {
    emit(const UserLoading(message: 'Setting default address...'));

    try {
      _cachedAddresses = await _userRepository.setDefaultAddress(
        event.addressId,
      );

      emit(
        AddressActionSuccess(
          addresses: _cachedAddresses,
          message: 'Default address updated',
        ),
      );

      if (_cachedProfile != null) {
        emit(
          UserProfileLoaded(
            profile: _cachedProfile!,
            addresses: _cachedAddresses,
          ),
        );
      }
    } catch (e) {
      emit(UserError(message: ErrorMapper.toUserMessage(e)));

      if (_cachedProfile != null) {
        emit(
          UserProfileLoaded(
            profile: _cachedProfile!,
            addresses: _cachedAddresses,
          ),
        );
      }
    }
  }

  Future<void> _onClearUserData(
    ClearUserDataRequested event,
    Emitter<UserState> emit,
  ) async {
    _cachedProfile = null;
    _cachedAddresses = [];
    emit(const UserInitial());
  }

  Future<void> _onDeleteAccount(
    DeleteAccountRequested event,
    Emitter<UserState> emit,
  ) async {
    emit(const UserLoading(message: 'Deleting account...'));

    try {
      await _userRepository.deleteAccount();
      _cachedProfile = null;
      _cachedAddresses = [];
      emit(const AccountDeleted());
    } catch (e) {
      emit(UserError(message: ErrorMapper.toUserMessage(e)));

      // Return to previous state if profile exists
      if (_cachedProfile != null) {
        emit(
          UserProfileLoaded(
            profile: _cachedProfile!,
            addresses: _cachedAddresses,
          ),
        );
      }
    }
  }
}
