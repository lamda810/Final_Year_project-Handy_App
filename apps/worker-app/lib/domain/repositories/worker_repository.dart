import '../../data/models/worker_model.dart';

/// Abstract contract for worker-profile operations.
///
/// Depend on this interface in BLoCs / use-cases so the presentation layer
/// stays decoupled from the Appwrite SDK.
abstract class WorkerRepository {
  /// Fetch the authenticated worker's full profile.
  Future<WorkerModel> getProfile();

  /// Partially update the worker profile. Only non-null fields are changed.
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
  });

  /// Push a GPS coordinate update for the authenticated worker.
  Future<void> updateLocation(double lat, double lng);

  /// Toggle online / offline status. Returns the new value.
  Future<bool> updateAvailability(bool isAvailable);

  /// Upload a verification document (CNIC front/back, certificate, etc.).
  /// Returns the public URL of the uploaded file.
  Future<String> uploadDocument(String type, String url);

  /// Upload a profile image. Returns the public URL.
  Future<String> uploadProfileImage(String filePath);

  /// Fetch earnings summary between optional date bounds.
  ///
  /// The returned map typically contains `totalEarnings`, `breakdown`, etc.
  Future<Map<String, dynamic>> getEarnings({
    DateTime? startDate,
    DateTime? endDate,
  });
}
