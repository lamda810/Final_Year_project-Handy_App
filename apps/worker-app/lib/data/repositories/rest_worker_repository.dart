import 'package:dio/dio.dart';
import '../../domain/repositories/worker_repository.dart';
import '../../core/constants/api_endpoints.dart';
import '../../data/models/worker_model.dart';

/// REST implementation of WorkerRepository for the Worker app
class RestWorkerRepository implements WorkerRepository {
  final Dio _dio;

  RestWorkerRepository({required Dio dio}) : _dio = dio;

  @override
  Future<WorkerModel> getProfile() async {
    try {
      final response = await _dio.get(ApiEndpoints.workerProfile);
      return WorkerModel.fromJson(response.data['data'] ?? response.data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<WorkerModel> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? contactPhone,
    String? profileImage,
    List<SkillModel>? skills,
    double? serviceRadius,
    WorkerAvailability? availability,
    BankDetails? bankDetails,
  }) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.workerProfile,
        data: {
          if (firstName != null) 'firstName': firstName,
          if (lastName != null) 'lastName': lastName,
          if (email != null) 'email': email,
          if (contactPhone != null) 'contactPhone': contactPhone,
          if (profileImage != null) 'profileImage': profileImage,
          if (skills != null) 'skills': skills.map((s) => s.toJson()).toList(),
          if (serviceRadius != null) 'serviceRadius': serviceRadius,
          if (availability != null) 'availability': availability.toString(),
          if (bankDetails != null) 'bankDetails': bankDetails.toJson(),
        },
      );
      return WorkerModel.fromJson(response.data['data'] ?? response.data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateLocation(double lat, double lng) async {
    await _dio.put(
      ApiEndpoints.updateLocation,
      data: {
        'coordinates': {'lat': lat, 'lng': lng},
      },
    );
  }

  @override
  Future<bool> updateAvailability(bool isAvailable) async {
    final response = await _dio.put(
      ApiEndpoints.updateAvailability,
      data: {'isAvailable': isAvailable},
    );
    final data = response.data['data'] ?? response.data;
    return (data['isAvailable'] as bool?) ?? isAvailable;
  }

  @override
  Future<String> uploadDocument(String type, String filePath) async {
    // TODO: The backend's POST /users/worker/documents expects a hosted
    // {type, url} — there is no file storage endpoint yet to upload to.
    throw UnsupportedError('Document upload is not available yet');
  }

  @override
  Future<String> uploadProfileImage(String filePath) async {
    // TODO: No backend storage endpoint exists yet for profile images.
    throw UnsupportedError('Profile photo upload is not available yet');
  }

  @override
  Future<Map<String, dynamic>> getEarnings({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.workerEarnings,
      queryParameters: {
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      },
    );
    return (response.data['data'] ?? response.data) as Map<String, dynamic>;
  }
}
