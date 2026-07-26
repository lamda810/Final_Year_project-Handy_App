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

  /// Uploads the local file to the generic file-storage endpoint (the same
  /// one customer-app uses for booking photos) and returns its public URL.
  Future<String> _uploadFile(String filePath) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.post('/uploads', data: formData);
    final data = response.data['data'] ?? response.data;
    return data['url'] as String;
  }

  @override
  Future<String> uploadDocument(String type, String filePath) async {
    final url = await _uploadFile(filePath);
    await _dio.post(ApiEndpoints.uploadDocuments, data: {'type': type, 'url': url});
    return url;
  }

  @override
  Future<String> uploadProfileImage(String filePath) async {
    final url = await _uploadFile(filePath);
    await _dio.post(
      ApiEndpoints.uploadDocuments,
      data: {'type': 'profile_photo', 'url': url},
    );
    return url;
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
