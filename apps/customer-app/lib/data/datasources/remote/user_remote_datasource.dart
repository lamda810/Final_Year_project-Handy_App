import '../../models/user_model.dart';

/// User remote data source interface
abstract class UserRemoteDataSource {
  Future<CustomerModel> getProfile();
  Future<CustomerModel> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? contactPhone,
    String? profileImage,
    String? preferredLanguage,
  });
  Future<List<AddressModel>> getAddresses();
  // The backend returns the customer's full, authoritative address list on
  // every mutation (not just the changed one), so these return the whole
  // list rather than a single AddressModel.
  Future<List<AddressModel>> addAddress(AddressModel address);
  Future<List<AddressModel>> updateAddress(String addressId, AddressModel address);
  Future<List<AddressModel>> setDefaultAddress(String addressId);
  Future<void> deleteAddress(String addressId);
  Future<void> deleteAccount();
}
