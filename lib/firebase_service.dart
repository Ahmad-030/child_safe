// lib/firebase_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'app_models.dart';

class FirebaseService {
  static final FirebaseFirestore db = FirebaseFirestore.instance;
  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final FirebaseStorage storage = FirebaseStorage.instance;
  static final FirebaseMessaging messaging = FirebaseMessaging.instance;

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

  // ─── MISSING ALERTS ────────────────────────────────────────────────────────
  static Future<String> createMissingAlert(MissingAlert alert) async {
    final ref = await db.collection('missing_alerts').add(alert.toMap());
    await updateChildProfile(alert.childId, {'status': 'missing'});
    return ref.id;
  }

  static Future<void> updateAlertStatus(String alertId, String status,
      {String? resolvedBy}) async {
    final data = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp()
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

  // ─── IMAGE UPLOAD ──────────────────────────────────────────────────────────
  static Future<String> uploadImage(File file, String path) async {
    final ref = storage.ref().child(path);
    final task = await ref.putFile(file);
    return await task.ref.getDownloadURL();
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

  // ─── SEND LOCAL NOTIFICATION ───────────────────────────────────────────────
  static Future<void> sendLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'childsafe_channel',
      'ChildSafe Alerts',
      channelDescription: 'Missing child alerts and updates',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    const NotificationDetails details =
    NotificationDetails(android: androidDetails, iOS: iosDetails);

    // import main to access plugin instance
    // We'll use a static reference
  }
}