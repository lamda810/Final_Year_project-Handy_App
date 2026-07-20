import 'package:dio/dio.dart';
import '../../../core/error/exceptions.dart';
import '../../models/user_model.dart';
import 'user_remote_datasource.dart';

/// REST implementation of UserRemoteDataSource using Dio
class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final Dio _dio;

  UserRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<CustomerModel> getProfile() async {
    try {
      final response = await _dio.get('/users/customer/profile');
      return CustomerModel.fromJson(response.data['data'] ?? response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<CustomerModel> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? contactPhone,
    String? profileImage,
    String? preferredLanguage,
  }) async {
    try {
      // Backend only registers PUT for this route (router.put('/profile', ...))
      // — PATCH 404s silently, which had made this endpoint a no-op.
      final response = await _dio.put(
        '/users/customer/profile',
        data: {
          if (firstName != null) 'firstName': firstName,
          if (lastName != null) 'lastName': lastName,
          if (email != null) 'email': email,
          if (contactPhone != null) 'contactPhone': contactPhone,
          if (profileImage != null) 'profileImage': profileImage,
          if (preferredLanguage != null) 'preferredLanguage': preferredLanguage,
        },
      );
      return CustomerModel.fromJson(response.data['data'] ?? response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<AddressModel>> getAddresses() async {
    try {
      final response = await _dio.get('/users/customer/addresses');
      final list = (response.data['data'] ?? response.data) as List;
      return list.map((e) => AddressModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<AddressModel>> addAddress(AddressModel address) async {
    try {
      final response = await _dio.post(
        '/users/customer/addresses',
        data: address.toJson(),
      );
      final list = (response.data['data'] ?? response.data) as List;
      return list.map((e) => AddressModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<AddressModel>> updateAddress(String addressId, AddressModel address) async {
    try {
      final response = await _dio.put(
        '/users/customer/addresses/$addressId',
        data: address.toJson(),
      );
      final list = (response.data['data'] ?? response.data) as List;
      return list.map((e) => AddressModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<AddressModel>> setDefaultAddress(String addressId) async {
    try {
      // There is no dedicated "set default" endpoint; it's just an update
      // with isDefault: true (the backend unsets all other defaults).
      final response = await _dio.put(
        '/users/customer/addresses/$addressId',
        data: {'isDefault': true},
      );
      final list = (response.data['data'] ?? response.data) as List;
      return list.map((e) => AddressModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> deleteAddress(String addressId) async {
    try {
      await _dio.delete('/users/customer/addresses/$addressId');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await _dio.delete('/users/customer/account');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      final message = data is Map ? data['message'] ?? 'Server error' : 'Server error';
      return ServerException(
        message: message,
        statusCode: e.response!.statusCode,
        data: data,
      );
    }
    return const ServerException(message: 'Unexpected network error');
  }
}
