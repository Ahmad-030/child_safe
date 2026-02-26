// lib/app_models.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String? photoUrl;
  final int points;
  final String? fcmToken;
  final DateTime? createdAt;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.photoUrl,
    this.points = 0,
    this.fcmToken,
    this.createdAt,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> m) => AppUser(
    uid: uid,
    name: m['name'] ?? '',
    email: m['email'] ?? '',
    phone: m['phone'] ?? '',
    role: m['role'] ?? 'volunteer',
    photoUrl: m['photoUrl'],
    points: (m['points'] ?? 0).toInt(),
    fcmToken: m['fcmToken'],
    createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'phone': phone,
    'role': role,
    'photoUrl': photoUrl,
    'points': points,
    'fcmToken': fcmToken,
    'createdAt': FieldValue.serverTimestamp(),
  };

  String get roleLabel {
    switch (role) {
      case 'parent':
        return 'Parent/Guardian';
      case 'authority':
        return 'Authority';
      default:
        return 'Volunteer';
    }
  }

  String get badge {
    if (points >= 1000) return 'Hero';
    if (points >= 500) return 'Guardian';
    if (points >= 200) return 'Helper';
    if (points >= 50) return 'Supporter';
    return 'Newcomer';
  }
}

class ChildProfile {
  final String id;
  final String parentUid;
  final String name;
  final int age;
  final String gender;
  final String? photoUrl;
  final String bloodGroup;
  final String description;
  final String emergencyContact;
  final List<String> medicalConditions;
  final String status;
  final DateTime? createdAt;
  // Geofence fields
  final double? safeZoneLat;
  final double? safeZoneLng;
  final double safeZoneRadius; // in meters

  ChildProfile({
    required this.id,
    required this.parentUid,
    required this.name,
    required this.age,
    required this.gender,
    this.photoUrl,
    required this.bloodGroup,
    required this.description,
    required this.emergencyContact,
    this.medicalConditions = const [],
    this.status = 'safe',
    this.createdAt,
    this.safeZoneLat,
    this.safeZoneLng,
    this.safeZoneRadius = 500,
  });

  factory ChildProfile.fromMap(String id, Map<String, dynamic> m) =>
      ChildProfile(
        id: id,
        parentUid: m['parentUid'] ?? '',
        name: m['name'] ?? '',
        age: (m['age'] ?? 0).toInt(),
        gender: m['gender'] ?? 'Unknown',
        photoUrl: m['photoUrl'],
        bloodGroup: m['bloodGroup'] ?? 'Unknown',
        description: m['description'] ?? '',
        emergencyContact: m['emergencyContact'] ?? '',
        medicalConditions: List<String>.from(m['medicalConditions'] ?? []),
        status: m['status'] ?? 'safe',
        createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
        safeZoneLat: (m['safeZoneLat'] as num?)?.toDouble(),
        safeZoneLng: (m['safeZoneLng'] as num?)?.toDouble(),
        safeZoneRadius: (m['safeZoneRadius'] as num?)?.toDouble() ?? 500,
      );

  Map<String, dynamic> toMap() => {
    'parentUid': parentUid,
    'name': name,
    'age': age,
    'gender': gender,
    'photoUrl': photoUrl,
    'bloodGroup': bloodGroup,
    'description': description,
    'emergencyContact': emergencyContact,
    'medicalConditions': medicalConditions,
    'status': status,
    'createdAt': FieldValue.serverTimestamp(),
    'safeZoneLat': safeZoneLat,
    'safeZoneLng': safeZoneLng,
    'safeZoneRadius': safeZoneRadius,
  };

  bool get hasSafeZone => safeZoneLat != null && safeZoneLng != null;
}

class MissingAlert {
  final String id;
  final String childId;
  final String childName;
  final int childAge;
  final String? childPhotoUrl;
  final String reportedBy;
  final String reporterName;
  final String lastSeenLocation;
  final double? lastSeenLat;
  final double? lastSeenLng;
  final String description;
  final String clothingDescription;
  final String status;
  final DateTime reportedAt;
  final DateTime? foundAt;
  final int sightingCount;
  final String? resolvedBy;
  final String emergencyContact;
  final bool isEmergency;

  MissingAlert({
    required this.id,
    required this.childId,
    required this.childName,
    required this.childAge,
    this.childPhotoUrl,
    required this.reportedBy,
    required this.reporterName,
    required this.lastSeenLocation,
    this.lastSeenLat,
    this.lastSeenLng,
    required this.description,
    required this.clothingDescription,
    required this.status,
    required this.reportedAt,
    this.foundAt,
    this.sightingCount = 0,
    this.resolvedBy,
    this.emergencyContact = '',
    this.isEmergency = false,
  });

  factory MissingAlert.fromMap(String id, Map<String, dynamic> m) =>
      MissingAlert(
        id: id,
        childId: m['childId'] ?? '',
        childName: m['childName'] ?? '',
        childAge: (m['childAge'] ?? 0).toInt(),
        childPhotoUrl: m['childPhotoUrl'],
        reportedBy: m['reportedBy'] ?? '',
        reporterName: m['reporterName'] ?? '',
        lastSeenLocation: m['lastSeenLocation'] ?? '',
        lastSeenLat: (m['lastSeenLat'] as num?)?.toDouble(),
        lastSeenLng: (m['lastSeenLng'] as num?)?.toDouble(),
        description: m['description'] ?? '',
        clothingDescription: m['clothingDescription'] ?? '',
        status: m['status'] ?? 'active',
        reportedAt:
        (m['reportedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        foundAt: (m['foundAt'] as Timestamp?)?.toDate(),
        sightingCount: (m['sightingCount'] ?? 0).toInt(),
        resolvedBy: m['resolvedBy'],
        emergencyContact: m['emergencyContact'] ?? '',
        isEmergency: m['isEmergency'] ?? false,
      );

  Map<String, dynamic> toMap() => {
    'childId': childId,
    'childName': childName,
    'childAge': childAge,
    'childPhotoUrl': childPhotoUrl,
    'reportedBy': reportedBy,
    'reporterName': reporterName,
    'lastSeenLocation': lastSeenLocation,
    'lastSeenLat': lastSeenLat,
    'lastSeenLng': lastSeenLng,
    'description': description,
    'clothingDescription': clothingDescription,
    'status': status,
    'reportedAt': FieldValue.serverTimestamp(),
    'sightingCount': sightingCount,
    'resolvedBy': resolvedBy,
    'emergencyContact': emergencyContact,
    'isEmergency': isEmergency,
  };

  String get timeAgo {
    final diff = DateTime.now().difference(reportedAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class Sighting {
  final String id;
  final String alertId;
  final String reportedBy;
  final String reporterName;
  final String location;
  final double? lat;
  final double? lng;
  final String description;
  final String? photoUrl;
  final DateTime reportedAt;

  Sighting({
    required this.id,
    required this.alertId,
    required this.reportedBy,
    required this.reporterName,
    required this.location,
    this.lat,
    this.lng,
    required this.description,
    this.photoUrl,
    required this.reportedAt,
  });

  factory Sighting.fromMap(String id, Map<String, dynamic> m) => Sighting(
    id: id,
    alertId: m['alertId'] ?? '',
    reportedBy: m['reportedBy'] ?? '',
    reporterName: m['reporterName'] ?? '',
    location: m['location'] ?? '',
    lat: (m['lat'] as num?)?.toDouble(),
    lng: (m['lng'] as num?)?.toDouble(),
    description: m['description'] ?? '',
    photoUrl: m['photoUrl'],
    reportedAt:
    (m['reportedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'alertId': alertId,
    'reportedBy': reportedBy,
    'reporterName': reporterName,
    'location': location,
    'lat': lat,
    'lng': lng,
    'description': description,
    'photoUrl': photoUrl,
    'reportedAt': FieldValue.serverTimestamp(),
  };
}

class LocationUpdate {
  final String childId;
  final double lat;
  final double lng;
  final DateTime? timestamp;

  LocationUpdate({
    required this.childId,
    required this.lat,
    required this.lng,
    this.timestamp,
  });

  factory LocationUpdate.fromMap(Map<String, dynamic> m) => LocationUpdate(
    childId: m['childId'] ?? '',
    lat: (m['lat'] as num?)?.toDouble() ?? 0,
    lng: (m['lng'] as num?)?.toDouble() ?? 0,
    timestamp: (m['timestamp'] as Timestamp?)?.toDate(),
  );
}

class AlertComment {
  final String id;
  final String alertId;
  final String authorUid;
  final String authorName;
  final String? authorPhotoUrl;
  final String text;
  final DateTime createdAt;

  AlertComment({
    required this.id,
    required this.alertId,
    required this.authorUid,
    required this.authorName,
    this.authorPhotoUrl,
    required this.text,
    required this.createdAt,
  });

  factory AlertComment.fromMap(String id, Map<String, dynamic> m) =>
      AlertComment(
        id: id,
        alertId: m['alertId'] ?? '',
        authorUid: m['authorUid'] ?? '',
        authorName: m['authorName'] ?? '',
        authorPhotoUrl: m['authorPhotoUrl'],
        text: m['text'] ?? '',
        createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
    'alertId': alertId,
    'authorUid': authorUid,
    'authorName': authorName,
    'authorPhotoUrl': authorPhotoUrl,
    'text': text,
    'createdAt': FieldValue.serverTimestamp(),
  };
}

class AppNotification {
  final String id;
  final String recipientUid;
  final String title;
  final String body;
  final String type;
  final String? relatedId;
  final bool read;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.recipientUid,
    required this.title,
    required this.body,
    required this.type,
    this.relatedId,
    this.read = false,
    required this.createdAt,
  });

  factory AppNotification.fromMap(String id, Map<String, dynamic> m) =>
      AppNotification(
        id: id,
        recipientUid: m['recipientUid'] ?? '',
        title: m['title'] ?? '',
        body: m['body'] ?? '',
        type: m['type'] ?? 'system',
        relatedId: m['relatedId'],
        read: m['read'] ?? false,
        createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
    'recipientUid': recipientUid,
    'title': title,
    'body': body,
    'type': type,
    'relatedId': relatedId,
    'read': read,
    'createdAt': FieldValue.serverTimestamp(),
  };
}

/// Geofence / Safe Zone event log
class GeofenceEvent {
  final String id;
  final String childId;
  final String childName;
  final String parentUid;
  final String eventType; // 'exit' or 'enter'
  final double lat;
  final double lng;
  final DateTime timestamp;

  GeofenceEvent({
    required this.id,
    required this.childId,
    required this.childName,
    required this.parentUid,
    required this.eventType,
    required this.lat,
    required this.lng,
    required this.timestamp,
  });

  factory GeofenceEvent.fromMap(String id, Map<String, dynamic> m) =>
      GeofenceEvent(
        id: id,
        childId: m['childId'] ?? '',
        childName: m['childName'] ?? '',
        parentUid: m['parentUid'] ?? '',
        eventType: m['eventType'] ?? 'exit',
        lat: (m['lat'] as num?)?.toDouble() ?? 0,
        lng: (m['lng'] as num?)?.toDouble() ?? 0,
        timestamp: (m['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
    'childId': childId,
    'childName': childName,
    'parentUid': parentUid,
    'eventType': eventType,
    'lat': lat,
    'lng': lng,
    'timestamp': FieldValue.serverTimestamp(),
  };
}