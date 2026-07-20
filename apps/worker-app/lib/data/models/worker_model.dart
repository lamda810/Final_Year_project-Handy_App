import 'user_model.dart';

class SkillModel {
  final String category;
  final int experience;
  final double hourlyRate;
  final bool isVerified;

  SkillModel({
    required this.category,
    required this.experience,
    required this.hourlyRate,
    required this.isVerified,
  });

  factory SkillModel.fromJson(Map<String, dynamic> json) {
    return SkillModel(
      category: json['category'] ?? '',
      experience: json['experience'] ?? 0,
      hourlyRate: (json['hourlyRate'] ?? 0).toDouble(),
      isVerified: json['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'experience': experience,
      'hourlyRate': hourlyRate,
      'isVerified': isVerified,
    };
  }
}

class AvailabilitySchedule {
  final String day;
  final String startTime;
  final String endTime;

  AvailabilitySchedule({
    required this.day,
    required this.startTime,
    required this.endTime,
  });

  factory AvailabilitySchedule.fromJson(Map<String, dynamic> json) {
    return AvailabilitySchedule(
      day: json['day'] ?? '',
      startTime: json['startTime'] ?? '08:00',
      endTime: json['endTime'] ?? '20:00',
    );
  }

  Map<String, dynamic> toJson() {
    return {'day': day, 'startTime': startTime, 'endTime': endTime};
  }
}

class WorkerAvailability {
  final bool isAvailable;
  final List<AvailabilitySchedule> schedule;

  WorkerAvailability({required this.isAvailable, required this.schedule});

  factory WorkerAvailability.fromJson(Map<String, dynamic> json) {
    return WorkerAvailability(
      isAvailable: json['isAvailable'] ?? false,
      schedule:
          (json['schedule'] as List<dynamic>?)
              ?.map((e) => AvailabilitySchedule.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isAvailable': isAvailable,
      'schedule': schedule.map((e) => e.toJson()).toList(),
    };
  }
}

class WorkerRating {
  final double average;
  final int count;

  WorkerRating({required this.average, required this.count});

  factory WorkerRating.fromJson(Map<String, dynamic> json) {
    return WorkerRating(
      average: (json['average'] ?? 0).toDouble(),
      count: json['count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'average': average, 'count': count};
  }
}

class BankDetails {
  final String accountTitle;
  final String accountNumber;
  final String bankName;

  BankDetails({
    required this.accountTitle,
    required this.accountNumber,
    required this.bankName,
  });

  factory BankDetails.fromJson(Map<String, dynamic> json) {
    return BankDetails(
      accountTitle: json['accountTitle'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      bankName: json['bankName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accountTitle': accountTitle,
      'accountNumber': accountNumber,
      'bankName': bankName,
    };
  }
}

class Coordinates {
  final double lat;
  final double lng;

  Coordinates({required this.lat, required this.lng});

  factory Coordinates.fromJson(Map<String, dynamic> json) {
    return Coordinates(
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'lat': lat, 'lng': lng};
  }
}

class WorkerModel {
  final String id;
  final UserModel user;
  final String firstName;
  final String lastName;
  final String? profileImage;
  final String? contactPhone;
  final String cnic;
  final bool cnicVerified;
  final String? cnicFrontImage;
  final String? cnicBackImage;

  /// Per-document verification status: 'pending', 'verified', 'rejected'
  final String cnicFrontStatus;
  final String cnicBackStatus;
  final String profilePhotoStatus;

  /// Admin feedback when documents are rejected
  final String? verificationNotes;
  final List<SkillModel> skills;
  final Coordinates? currentLocation;
  final double serviceRadius;
  final WorkerAvailability availability;
  final WorkerRating rating;
  final int trustScore;
  final int totalJobsCompleted;
  final double totalEarnings;
  final BankDetails? bankDetails;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  WorkerModel({
    required this.id,
    required this.user,
    required this.firstName,
    required this.lastName,
    this.profileImage,
    this.contactPhone,
    required this.cnic,
    required this.cnicVerified,
    this.cnicFrontImage,
    this.cnicBackImage,
    this.cnicFrontStatus = 'pending',
    this.cnicBackStatus = 'pending',
    this.profilePhotoStatus = 'pending',
    this.verificationNotes,
    required this.skills,
    this.currentLocation,
    required this.serviceRadius,
    required this.availability,
    required this.rating,
    required this.trustScore,
    required this.totalJobsCompleted,
    required this.totalEarnings,
    this.bankDetails,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WorkerModel.fromJson(Map<String, dynamic> json) {
    return WorkerModel(
      id: json['_id'] ?? json['id'] ?? '',
      user: UserModel.fromJson(json['user'] ?? {}),
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      profileImage: json['profileImage'],
      contactPhone: json['contactPhone'],
      cnic: json['cnic'] ?? '',
      cnicVerified: json['cnicVerified'] ?? false,
      cnicFrontImage: json['cnicFrontImage'],
      cnicBackImage: json['cnicBackImage'],
      cnicFrontStatus: json['cnicFrontStatus'] ?? 'pending',
      cnicBackStatus: json['cnicBackStatus'] ?? 'pending',
      profilePhotoStatus: json['profilePhotoStatus'] ?? 'pending',
      verificationNotes: json['verificationNotes'],
      skills:
          (json['skills'] as List<dynamic>?)
              ?.map((e) => SkillModel.fromJson(e))
              .toList() ??
          [],
      currentLocation: json['currentLocation'] != null
          ? Coordinates.fromJson(json['currentLocation'])
          : null,
      serviceRadius: (json['serviceRadius'] ?? 10).toDouble(),
      availability: WorkerAvailability.fromJson(json['availability'] ?? {}),
      rating: WorkerRating.fromJson(json['rating'] ?? {}),
      trustScore: json['trustScore'] ?? 50,
      totalJobsCompleted: json['totalJobsCompleted'] ?? 0,
      totalEarnings: (json['totalEarnings'] ?? 0).toDouble(),
      bankDetails: json['bankDetails'] != null
          ? BankDetails.fromJson(json['bankDetails'])
          : null,
      status: json['status'] ?? 'PENDING_VERIFICATION',
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  String get fullName => '$firstName $lastName';

  bool get isActive => status == 'ACTIVE';

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user': user.toJson(),
      'firstName': firstName,
      'lastName': lastName,
      'profileImage': profileImage,
      'contactPhone': contactPhone,
      'cnic': cnic,
      'cnicVerified': cnicVerified,
      'cnicFrontImage': cnicFrontImage,
      'cnicBackImage': cnicBackImage,
      'cnicFrontStatus': cnicFrontStatus,
      'cnicBackStatus': cnicBackStatus,
      'profilePhotoStatus': profilePhotoStatus,
      'verificationNotes': verificationNotes,
      'skills': skills.map((e) => e.toJson()).toList(),
      'currentLocation': currentLocation?.toJson(),
      'serviceRadius': serviceRadius,
      'availability': availability.toJson(),
      'rating': rating.toJson(),
      'trustScore': trustScore,
      'totalJobsCompleted': totalJobsCompleted,
      'totalEarnings': totalEarnings,
      'bankDetails': bankDetails?.toJson(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
