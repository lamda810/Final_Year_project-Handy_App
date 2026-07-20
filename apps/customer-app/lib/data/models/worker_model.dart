import 'package:equatable/equatable.dart';

/// Worker skill model
class WorkerSkill extends Equatable {
  final String category;
  final int experience;
  final double hourlyRate;
  final bool isVerified;

  const WorkerSkill({
    required this.category,
    required this.experience,
    required this.hourlyRate,
    this.isVerified = false,
  });

  factory WorkerSkill.fromJson(Map<String, dynamic> json) {
    return WorkerSkill(
      category: json['category'] ?? '',
      experience: json['experience'] ?? 0,
      hourlyRate: (json['hourlyRate'] ?? 0).toDouble(),
      isVerified: json['isVerified'] ?? false,
    );
  }

  @override
  List<Object?> get props => [category, experience, hourlyRate, isVerified];
}

/// Worker rating model
class WorkerRating extends Equatable {
  final double average;
  final int count;

  const WorkerRating({required this.average, required this.count});

  factory WorkerRating.fromJson(Map<String, dynamic> json) {
    return WorkerRating(
      average: (json['average'] ?? 0).toDouble(),
      count: json['count'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [average, count];
}

/// Worker model for full details
class WorkerModel extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String? profileImage;
  final String cnic;
  final bool cnicVerified;
  final List<WorkerSkill> skills;
  final WorkerRating rating;
  final int trustScore;
  final int totalJobsCompleted;
  final String status;

  const WorkerModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profileImage,
    required this.cnic,
    this.cnicVerified = false,
    this.skills = const [],
    required this.rating,
    this.trustScore = 50,
    this.totalJobsCompleted = 0,
    required this.status,
  });

  factory WorkerModel.fromJson(Map<String, dynamic> json) {
    return WorkerModel(
      id: json['_id'] ?? json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      profileImage: json['profileImage'],
      cnic: json['cnic'] ?? '',
      cnicVerified: json['cnicVerified'] ?? false,
      skills:
          (json['skills'] as List?)
              ?.map((s) => WorkerSkill.fromJson(s))
              .toList() ??
          [],
      rating: WorkerRating.fromJson(json['rating'] ?? {}),
      trustScore: json['trustScore'] ?? 50,
      totalJobsCompleted: json['totalJobsCompleted'] ?? 0,
      status: json['status'] ?? 'INACTIVE',
    );
  }

  String get fullName => '$firstName $lastName';

  @override
  List<Object?> get props => [
    id,
    firstName,
    lastName,
    profileImage,
    cnic,
    cnicVerified,
    skills,
    rating,
    trustScore,
    totalJobsCompleted,
    status,
  ];
}

/// Matched worker model for booking selection
class MatchedWorkerModel extends Equatable {
  final String workerId;
  final String name;
  final String? profileImage;
  final double rating;
  final int ratingCount;
  final int trustScore;
  final double distance;
  final int estimatedArrival;
  final double matchScore;
  final double hourlyRate;
  final List<String> skills;

  const MatchedWorkerModel({
    required this.workerId,
    required this.name,
    this.profileImage,
    required this.rating,
    required this.ratingCount,
    required this.trustScore,
    required this.distance,
    required this.estimatedArrival,
    required this.matchScore,
    required this.hourlyRate,
    this.skills = const [],
  });

  factory MatchedWorkerModel.fromJson(Map<String, dynamic> json) {
    // The backend returns rating as a nested { average, count } object, not
    // a flat number.
    final ratingJson = json['rating'];
    final ratingAverage = ratingJson is Map
        ? (ratingJson['average'] ?? 0)
        : (ratingJson ?? 0);
    final ratingCount = ratingJson is Map
        ? (ratingJson['count'] ?? 0)
        : (json['ratingCount'] ?? 0);

    return MatchedWorkerModel(
      workerId: json['workerId'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      profileImage: json['profileImage'],
      rating: (ratingAverage as num).toDouble(),
      ratingCount: ratingCount as int,
      trustScore: json['trustScore'] ?? 50,
      distance: (json['distance'] ?? 0).toDouble(),
      estimatedArrival: json['estimatedArrival'] ?? 0,
      matchScore: (json['matchScore'] ?? 0).toDouble(),
      hourlyRate: (json['hourlyRate'] ?? 0).toDouble(),
      skills: List<String>.from(json['skills'] ?? []),
    );
  }

  String get trustBadge {
    if (trustScore >= 80) return 'Highly Trusted';
    if (trustScore >= 60) return 'Trusted';
    if (trustScore >= 40) return 'Verified';
    return 'New';
  }

  @override
  List<Object?> get props => [
    workerId,
    name,
    profileImage,
    rating,
    ratingCount,
    trustScore,
    distance,
    estimatedArrival,
    matchScore,
    hourlyRate,
    skills,
  ];
}

/// Worker location response
class WorkerLocationResponse extends Equatable {
  final double lat;
  final double lng;
  final int? etaMinutes;

  const WorkerLocationResponse({
    required this.lat,
    required this.lng,
    this.etaMinutes,
  });

  factory WorkerLocationResponse.fromJson(Map<String, dynamic> json) {
    // Handle both flat and nested { data: { location: {...} } } formats
    final dynamic rawData = json['data'];
    final Map<String, dynamic> source = (rawData is Map)
        ? Map<String, dynamic>.from(rawData)
        : json;
    final dynamic location = source['location'];
    final Map<String, dynamic> loc = (location is Map)
        ? Map<String, dynamic>.from(location)
        : source;
    final dynamic coordinatesRaw = loc['coordinates'];
    final Map<String, dynamic> coordinates = (coordinatesRaw is Map)
        ? Map<String, dynamic>.from(coordinatesRaw)
        : loc;

    double parseLat() {
      final v = coordinates['lat'] ?? loc['lat'] ?? json['lat'];
      if (v is num) return v.toDouble();
      return 0.0;
    }

    double parseLng() {
      final v = coordinates['lng'] ?? loc['lng'] ?? json['lng'];
      if (v is num) return v.toDouble();
      return 0.0;
    }

    return WorkerLocationResponse(
      lat: parseLat(),
      lng: parseLng(),
      etaMinutes: loc['etaMinutes'] ?? json['etaMinutes'],
    );
  }

  @override
  List<Object?> get props => [lat, lng, etaMinutes];
}
