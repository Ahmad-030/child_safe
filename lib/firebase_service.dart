// lib/firebase_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'app_models.dart';

class FirebaseService {
  static final FirebaseFirestore db = FirebaseFirestore.instance;
  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final FirebaseMessaging messaging = FirebaseMessaging.instance;

  // ─── CLOUDINARY CONFIG ─────────────────────────────────────────────────────
  static const String _cloudinaryCloudName = 'dyl2toyfl';
  static const String _cloudinaryUploadPreset = 'Child_safety';

  // ─── AUTH ──────────────────────────────────────────────────────────────────
  static User? get currentUser => auth.currentUser;
  static String? get currentUid => auth.currentUser?.uid;

  static Future<UserCredential> signIn(String email, String password) =>
      auth.signInWithEmailAndPassword(email: email, password: password);

  static Future<UserCredential> signUp(String email, String password) =>
      auth.createUserWithEmailAndPassword(email: email, password: password);

  static Future<void> signOut() => auth.signOut();

  static Future<void> sendPasswordReset(String email) =>
      auth.sendPasswordResetEmail(email: email);

  // ─── USER PROFILE ──────────────────────────────────────────────────────────
  static Future<void> createUserProfile(AppUser user) =>
      db.collection('users').doc(user.uid).set(user.toMap());

  static Future<AppUser?> getUserProfile(String uid) async {
    final doc = await db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(uid, doc.data()!);
  }

  static Future<void> updateUserProfile(
      String uid, Map<String, dynamic> data) =>
      db.collection('users').doc(uid).update(data);

  static Stream<AppUser?> userStream(String uid) =>
      db.collection('users').doc(uid).snapshots().map(
              (doc) => doc.exists ? AppUser.fromMap(uid, doc.data()!) : null);

  // ─── CHILD PROFILES ────────────────────────────────────────────────────────
  static Future<String> addChildProfile(ChildProfile child) async {
    final ref = await db.collection('children').add(child.toMap());
    return ref.id;
  }

  static Future<void> updateChildProfile(
      String id, Map<String, dynamic> data) =>
      db.collection('children').doc(id).update(data);

  static Future<void> deleteChildProfile(String id) =>
      db.collection('children').doc(id).delete();

  static Stream<List<ChildProfile>> childrenStream(String parentUid) =>
      db
          .collection('children')
          .where('parentUid', isEqualTo: parentUid)
          .snapshots()
          .map((s) =>
          s.docs.map((d) => ChildProfile.fromMap(d.id, d.data())).toList());

  static Future<ChildProfile?> getChildProfile(String id) async {
    final doc = await db.collection('children').doc(id).get();
    if (!doc.exists) return null;
    return ChildProfile.fromMap(id, doc.data()!);
  }

  // ─── SAFE ZONE / GEOFENCE ──────────────────────────────────────────────────
  static Future<void> setSafeZone(
      String childId, double lat, double lng, double radiusMeters) {
    return db.collection('children').doc(childId).update({
      'safeZoneLat': lat,
      'safeZoneLng': lng,
      'safeZoneRadius': radiusMeters,
    });
  }

  static Future<void> clearSafeZone(String childId) {
    return db.collection('children').doc(childId).update({
      'safeZoneLat': FieldValue.delete(),
      'safeZoneLng': FieldValue.delete(),
      'safeZoneRadius': 500,
    });
  }

  static Future<void> checkGeofenceAndNotify({
    required ChildProfile child,
    required double lat,
    required double lng,
  }) async {
    if (!child.hasSafeZone) return;

    final distanceMeters = _haversineDistance(
      child.safeZoneLat!,
      child.safeZoneLng!,
      lat,
      lng,
    );

    final isOutside = distanceMeters > child.safeZoneRadius;
    if (isOutside) {
      await db.collection('geofence_events').add(GeofenceEvent(
        id: '',
        childId: child.id,
        childName: child.name,
        parentUid: child.parentUid,
        eventType: 'exit',
        lat: lat,
        lng: lng,
        timestamp: DateTime.now(),
      ).toMap());

      await saveNotification(AppNotification(
        id: '',
        recipientUid: child.parentUid,
        title: '⚠️ Safe Zone Alert — ${child.name}',
        body:
        '${child.name} has left the designated safe zone! Current location: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
        type: 'geofence',
        relatedId: child.id,
        createdAt: DateTime.now(),
      ));
    }
  }

  static Stream<List<GeofenceEvent>> geofenceEventsStream(String childId) =>
      db
          .collection('geofence_events')
          .where('childId', isEqualTo: childId)
          .orderBy('timestamp', descending: true)
          .limit(20)
          .snapshots()
          .map((s) =>
          s.docs.map((d) => GeofenceEvent.fromMap(d.id, d.data())).toList());

  static double _haversineDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final phi1 = lat1 * pi / 180;
    final phi2 = lat2 * pi / 180;
    final dPhi = (lat2 - lat1) * pi / 180;
    final dLam = (lon2 - lon1) * pi / 180;
    final a = sin(dPhi / 2) * sin(dPhi / 2) +
        cos(phi1) * cos(phi2) * sin(dLam / 2) * sin(dLam / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  // ─── MISSING ALERTS ────────────────────────────────────────────────────────
  static Future<String> createMissingAlert(MissingAlert alert) async {
    final ref = await db.collection('missing_alerts').add(alert.toMap());
    if (alert.childId.isNotEmpty) {
      await updateChildProfile(alert.childId, {'status': 'missing'});
    }
    await _notifyAllUsers(
      title: '🚨 Missing Child Alert — ${alert.childName}',
      body:
      'Age ${alert.childAge} last seen at ${alert.lastSeenLocation}. Tap to view details.',
      type: 'alert',
      relatedId: ref.id,
    );
    return ref.id;
  }

  static Future<String> createEmergencyAlert(MissingAlert alert) async {
    final ref = await db.collection('missing_alerts').add({
      ...alert.toMap(),
      'isEmergency': true,
      'reporterName': 'Emergency Report (No Login)',
    });
    await _notifyAllUsers(
      title: '🆘 EMERGENCY — Missing Child: ${alert.childName}',
      body:
      'Emergency report filed. Age ${alert.childAge}, last seen: ${alert.lastSeenLocation}',
      type: 'alert',
      relatedId: ref.id,
    );
    return ref.id;
  }

  static Future<void> updateAlertStatus(String alertId, String status,
      {String? resolvedBy, required String foundPhotoUrl}) async {
    final data = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (resolvedBy != null) data['resolvedBy'] = resolvedBy;
    if (status == 'found') data['foundAt'] = FieldValue.serverTimestamp();
    await db.collection('missing_alerts').doc(alertId).update(data);
  }

  static Stream<List<MissingAlert>> activeMissingAlertsStream() =>
      db
          .collection('missing_alerts')
          .where('status', isEqualTo: 'active')
          .orderBy('reportedAt', descending: true)
          .snapshots()
          .map((s) =>
          s.docs.map((d) => MissingAlert.fromMap(d.id, d.data())).toList());

  static Stream<List<MissingAlert>> allAlertsStream() =>
      db
          .collection('missing_alerts')
          .orderBy('reportedAt', descending: true)
          .snapshots()
          .map((s) =>
          s.docs.map((d) => MissingAlert.fromMap(d.id, d.data())).toList());

  static Stream<List<MissingAlert>> myAlertsStream(String parentUid) =>
      db
          .collection('missing_alerts')
          .where('reportedBy', isEqualTo: parentUid)
          .orderBy('reportedAt', descending: true)
          .snapshots()
          .map((s) =>
          s.docs.map((d) => MissingAlert.fromMap(d.id, d.data())).toList());

  static Future<MissingAlert?> getAlert(String alertId) async {
    final doc = await db.collection('missing_alerts').doc(alertId).get();
    if (!doc.exists) return null;
    return MissingAlert.fromMap(alertId, doc.data()!);
  }

  // ─── SIGHTINGS ─────────────────────────────────────────────────────────────
  static Future<void> addSighting(Sighting sighting) async {
    await db.collection('sightings').add(sighting.toMap());
    await db.collection('missing_alerts').doc(sighting.alertId).update({
      'sightingCount': FieldValue.increment(1),
    });
    await addPoints(sighting.reportedBy, 10);
  }

  static Stream<List<Sighting>> sightingsStream(String alertId) =>
      db
          .collection('sightings')
          .where('alertId', isEqualTo: alertId)
          .orderBy('reportedAt', descending: true)
          .snapshots()
          .map((s) =>
          s.docs.map((d) => Sighting.fromMap(d.id, d.data())).toList());

  // ─── LOCATION TRACKING ─────────────────────────────────────────────────────
  static Future<void> updateChildLocation(
      String childId, double lat, double lng) =>
      db.collection('child_locations').doc(childId).set({
        'childId': childId,
        'lat': lat,
        'lng': lng,
        'timestamp': FieldValue.serverTimestamp(),
      });

  static Stream<LocationUpdate?> childLocationStream(String childId) =>
      db.collection('child_locations').doc(childId).snapshots().map(
              (doc) => doc.exists ? LocationUpdate.fromMap(doc.data()!) : null);

  static Future<void> addLocationHistory(
      String childId, double lat, double lng) =>
      db.collection('location_history').add({
        'childId': childId,
        'lat': lat,
        'lng': lng,
        'timestamp': FieldValue.serverTimestamp(),
      });

  static Stream<List<Map<String, dynamic>>> locationHistoryStream(
      String childId) =>
      db
          .collection('location_history')
          .where('childId', isEqualTo: childId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots()
          .map((s) => s.docs.map((d) => d.data()).toList());

  // ─── CHILD SOS ─────────────────────────────────────────────────────────────
  static Future<void> triggerChildSOS({
    required String childId,
    required String childName,
    required String parentUid,
    required double lat,
    required double lng,
  }) async {
    await db.collection('sos_events').add({
      'childId': childId,
      'childName': childName,
      'parentUid': parentUid,
      'lat': lat,
      'lng': lng,
      'timestamp': FieldValue.serverTimestamp(),
      'resolved': false,
    });

    await saveNotification(AppNotification(
      id: '',
      recipientUid: parentUid,
      title: '🆘 SOS from $childName!',
      body:
      '$childName has triggered an SOS alert! Location: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}. Please respond immediately!',
      type: 'sos',
      relatedId: childId,
      createdAt: DateTime.now(),
    ));
  }

  // ─── REWARDS / POINTS ──────────────────────────────────────────────────────
  static Future<void> addPoints(String uid, int points) =>
      db.collection('users').doc(uid).update({
        'points': FieldValue.increment(points),
      });

  static Stream<List<AppUser>> leaderboardStream() =>
      db
          .collection('users')
          .orderBy('points', descending: true)
          .limit(20)
          .snapshots()
          .map((s) =>
          s.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList());

  // ─── COMMENTS ──────────────────────────────────────────────────────────────
  static Future<void> addComment(AlertComment comment) =>
      db.collection('alert_comments').add(comment.toMap());

  static Stream<List<AlertComment>> commentsStream(String alertId) =>
      db
          .collection('alert_comments')
          .where('alertId', isEqualTo: alertId)
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map((s) =>
          s.docs.map((d) => AlertComment.fromMap(d.id, d.data())).toList());

  // ─── NOTIFICATIONS ─────────────────────────────────────────────────────────
  static Future<void> saveNotification(AppNotification notification) =>
      db.collection('notifications').add(notification.toMap());

  static Future<void> _notifyAllUsers({
    required String title,
    required String body,
    required String type,
    required String relatedId,
  }) async {
    final users = await db.collection('users').get();
    final batch = db.batch();
    for (final doc in users.docs) {
      final ref = db.collection('notifications').doc();
      batch.set(ref, {
        'recipientUid': doc.id,
        'title': title,
        'body': body,
        'type': type,
        'relatedId': relatedId,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  static Stream<List<AppNotification>> notificationsStream(String uid) =>
      db
          .collection('notifications')
          .where('recipientUid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .map((s) => s.docs
          .map((d) => AppNotification.fromMap(d.id, d.data()))
          .toList());

  static Future<void> markNotificationRead(String notifId) =>
      db.collection('notifications').doc(notifId).update({'read': true});

  static Future<void> markAllNotificationsRead(String uid) async {
    final batch = db.batch();
    final snap = await db
        .collection('notifications')
        .where('recipientUid', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .get();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  static Stream<int> unreadCountStream(String uid) =>
      db
          .collection('notifications')
          .where('recipientUid', isEqualTo: uid)
          .where('read', isEqualTo: false)
          .snapshots()
          .map((s) => s.docs.length);

  // ─── IMAGE UPLOAD (CLOUDINARY) ─────────────────────────────────────────────
  /// Uploads [file] to Cloudinary under [folder] and returns the secure URL.
  /// The URL is then stored directly in Firestore (photoUrl fields).
  static Future<String> uploadImage(File file, String folder) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _cloudinaryUploadPreset
      ..fields['folder'] = folder
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await request.send();

    if (streamedResponse.statusCode != 200) {
      throw Exception(
          'Cloudinary upload failed with status: ${streamedResponse.statusCode}');
    }

    final responseBody = await streamedResponse.stream.bytesToString();
    final json = jsonDecode(responseBody) as Map<String, dynamic>;

    final secureUrl = json['secure_url'] as String?;
    if (secureUrl == null || secureUrl.isEmpty) {
      throw Exception('Cloudinary returned no URL. Response: $responseBody');
    }

    return secureUrl;
  }

  // ─── STATS ─────────────────────────────────────────────────────────────────
  static Future<Map<String, int>> getStats() async {
    final active = await db
        .collection('missing_alerts')
        .where('status', isEqualTo: 'active')
        .count()
        .get();
    final found = await db
        .collection('missing_alerts')
        .where('status', isEqualTo: 'found')
        .count()
        .get();
    final users = await db.collection('users').count().get();
    final children = await db.collection('children').count().get();
    return {
      'active': active.count ?? 0,
      'found': found.count ?? 0,
      'users': users.count ?? 0,
      'children': children.count ?? 0,
    };
  }

  // ─── FCM TOKEN ─────────────────────────────────────────────────────────────
  static Future<void> saveFcmToken(String uid) async {
    try {
      final token = await messaging.getToken();
      if (token != null) {
        await db.collection('users').doc(uid).update({'fcmToken': token});
      }
    } catch (_) {}
  }
}