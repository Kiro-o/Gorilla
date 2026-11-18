import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_storage_service.dart';

class LeaderboardMember {
  final String userId;
  final String userName;
  final String avatar;
  final String roomCode;
  final double maxWeight;
  final double totalVolume;
  final int totalSets;
  final double best1RM;
  final int lastActive;
  final Map<String, dynamic> maxLifts;

  LeaderboardMember({
    required this.userId,
    required this.userName,
    this.avatar = '🦍',
    required this.roomCode,
    required this.maxWeight,
    required this.totalVolume,
    required this.totalSets,
    required this.best1RM,
    required this.lastActive,
    this.maxLifts = const {},
  });

  factory LeaderboardMember.fromMap(Map<String, dynamic> map, String id) {
    return LeaderboardMember(
      userId: map['userId'] as String? ?? id,
      userName: map['userName'] as String? ?? 'Athlete',
      avatar: map['avatar'] as String? ?? '🦍',
      roomCode: map['roomCode'] as String? ?? map['groupId'] as String? ?? 'GORILLA-01',
      maxWeight: (map['maxWeight'] as num?)?.toDouble() ?? 0.0,
      totalVolume: (map['totalVolume'] as num?)?.toDouble() ?? 0.0,
      totalSets: (map['totalSets'] as num?)?.toInt() ?? 0,
      best1RM: (map['best1RM'] as num?)?.toDouble() ?? 0.0,
      lastActive: (map['lastActive'] as num?)?.toInt() ?? 0,
      maxLifts: map['maxLifts'] is Map ? Map<String, dynamic>.from(map['maxLifts'] as Map) : {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'avatar': avatar,
      'roomCode': roomCode,
      'groupId': roomCode,
      'maxWeight': maxWeight,
      'totalVolume': totalVolume,
      'totalSets': totalSets,
      'best1RM': best1RM,
      'lastActive': lastActive,
      'maxLifts': maxLifts,
    };
  }
}

class FirestoreSyncService {
  static const String _keyRoomCode = 'gorilla_room_code';
  static const String defaultRoomCode = 'GORILLA-01';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static final List<LeaderboardMember> seedDemoCrew = [
    LeaderboardMember(
      userId: 'crew_marcus',
      userName: 'Marcus "Titan"',
      avatar: '🦍',
      roomCode: defaultRoomCode,
      maxWeight: 140.0,
      totalVolume: 24850.0,
      totalSets: 54,
      best1RM: 168.0,
      lastActive: DateTime.now().subtract(const Duration(minutes: 12)).millisecondsSinceEpoch,
      maxLifts: {
        'Incline Chest Press': {'weight': 110.0, 'reps': 8, 'est1RM': 139.0},
        '45° Leg Press Machine': {'weight': 340.0, 'reps': 10, 'est1RM': 453.0},
        'Seated Shoulder Press': {'weight': 80.0, 'reps': 8, 'est1RM': 101.0},
      },
    ),
    LeaderboardMember(
      userId: 'crew_sarah',
      userName: 'Sarah "Valkyrie"',
      avatar: '👑',
      roomCode: defaultRoomCode,
      maxWeight: 125.0,
      totalVolume: 21600.0,
      totalSets: 48,
      best1RM: 145.0,
      lastActive: DateTime.now().subtract(const Duration(minutes: 35)).millisecondsSinceEpoch,
      maxLifts: {
        'Incline Chest Press': {'weight': 75.0, 'reps': 10, 'est1RM': 100.0},
        '45° Leg Press Machine': {'weight': 320.0, 'reps': 12, 'est1RM': 448.0},
      },
    ),
    LeaderboardMember(
      userId: 'crew_dave',
      userName: 'Dave "IronBull"',
      avatar: '🐂',
      roomCode: defaultRoomCode,
      maxWeight: 120.0,
      totalVolume: 18900.0,
      totalSets: 42,
      best1RM: 140.0,
      lastActive: DateTime.now().subtract(const Duration(minutes: 85)).millisecondsSinceEpoch,
      maxLifts: {
        'Incline Chest Press': {'weight': 95.0, 'reps': 8, 'est1RM': 120.0},
        '45° Leg Press Machine': {'weight': 280.0, 'reps': 10, 'est1RM': 373.0},
      },
    ),
    LeaderboardMember(
      userId: 'crew_zack',
      userName: 'Zack "Silverback"',
      avatar: '⚡',
      roomCode: defaultRoomCode,
      maxWeight: 115.0,
      totalVolume: 16400.0,
      totalSets: 39,
      best1RM: 132.0,
      lastActive: DateTime.now().subtract(const Duration(minutes: 180)).millisecondsSinceEpoch,
      maxLifts: {
        'Incline Chest Press': {'weight': 85.0, 'reps': 8, 'est1RM': 107.0},
        'Seated Cable Row': {'weight': 90.0, 'reps': 10, 'est1RM': 120.0},
      },
    ),
  ];

  Future<String> getRoomCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRoomCode) ?? defaultRoomCode;
  }

  Future<void> setRoomCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRoomCode, code.trim().toUpperCase());
  }

  // --- Sync local logs to Firestore leaderboards & user profile ---
  Future<void> syncLocalStats({
    required LocalStorageService storage,
    String? roomCodeOverride,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final roomCode = roomCodeOverride ?? await getRoomCode();
    final exercises = storage.getExercises();
    final logs = storage.getLogs();

    double maxWeight = 0.0;
    double totalVolume = 0.0;
    double best1RM = 0.0;
    final Map<String, dynamic> maxLifts = {};

    for (final ex in exercises) {
      final exLogs = logs.where((l) => l.exerciseId == ex.id).toList();
      if (exLogs.isNotEmpty) {
        double exMaxW = 0.0;
        int exMaxR = 0;
        double exBest1RM = 0.0;

        for (final l in exLogs) {
          totalVolume += l.volume;
          if (l.weightKg > maxWeight) maxWeight = l.weightKg;
          if (l.weightKg > exMaxW) {
            exMaxW = l.weightKg;
            exMaxR = l.reps;
          }
          final est = l.estimated1RM;
          if (est > best1RM) best1RM = est;
          if (est > exBest1RM) exBest1RM = est;
        }

        maxLifts[ex.name] = {
          'weight': exMaxW,
          'reps': exMaxR,
          'est1RM': exBest1RM,
          'muscle': ex.targetMuscle,
          'date': exLogs.last.dateString,
        };
      }
    }

    final member = LeaderboardMember(
      userId: user.uid,
      userName: user.displayName ?? 'Gorilla Athlete',
      avatar: '🦍',
      roomCode: roomCode,
      maxWeight: maxWeight,
      totalVolume: totalVolume,
      totalSets: logs.length,
      best1RM: best1RM,
      lastActive: DateTime.now().millisecondsSinceEpoch,
      maxLifts: maxLifts,
    );

    try {
      // 1. Sync to leaderboards/{roomCode}/members/{userId}
      await _firestore
          .collection('leaderboards')
          .doc(roomCode)
          .collection('members')
          .doc(user.uid)
          .set(member.toMap(), SetOptions(merge: true));

      // 2. Also sync to users/{userId}
      await _firestore.collection('users').doc(user.uid).set({
        ...member.toMap(),
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));

      // 3. Backward compatible push to gym_groups/{roomCode}/members/{userId}
      await _firestore
          .collection('gym_groups')
          .doc(roomCode)
          .collection('members')
          .doc(user.uid)
          .set(member.toMap(), SetOptions(merge: true));
    } catch (e) {
      // Offline fallback: writes are queued by Firestore offline persistence
    }
  }

  // --- Live Stream of Room Members ---
  Stream<List<LeaderboardMember>> streamRoomMembers(String roomCode) {
    return _firestore
        .collection('leaderboards')
        .doc(roomCode)
        .collection('members')
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        // Fallback to seeded demo members if default room
        if (roomCode == defaultRoomCode) {
          return seedDemoCrew;
        }
        return [];
      }

      final list = snapshot.docs
          .map((doc) => LeaderboardMember.fromMap(doc.data(), doc.id))
          .toList();

      // If default room and user is the only member, merge with seed crew
      if (roomCode == defaultRoomCode) {
        for (final seed in seedDemoCrew) {
          if (!list.any((m) => m.userId == seed.userId)) {
            list.add(seed);
          }
        }
      }

      return list;
    });
  }
}

final firestoreSyncService = FirestoreSyncService();
