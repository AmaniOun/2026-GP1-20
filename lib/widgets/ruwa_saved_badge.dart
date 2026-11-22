import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A single Firestore listener shared by all saved-status badges.
/// Null means the saved list has not been verified; never show a false badge.
class RuwaSavedPlantsStatus {
  RuwaSavedPlantsStatus._();
  static final RuwaSavedPlantsStatus instance = RuwaSavedPlantsStatus._();

  final ValueNotifier<Set<String>?> savedIds = ValueNotifier<Set<String>?>(null);
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _plantsSubscription;
  String? _listeningUid;
  bool _started = false;

  void ensureStarted() {
    if (_started) return;
    _started = true;
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      _listenForUser,
      onError: (Object error) {
        debugPrint('Saved plants auth listener error: $error');
        savedIds.value = null;
      },
    );
    _listenForUser(FirebaseAuth.instance.currentUser);
  }

  void _listenForUser(User? user) {
    final uid = user?.uid;
    if (uid == _listeningUid) return;
    _listeningUid = uid;
    savedIds.value = null;
    unawaited(_plantsSubscription?.cancel());
    _plantsSubscription = null;
    if (uid == null) return;
    _plantsSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('savedPlants')
        .snapshots()
        .listen(
      (snapshot) {
        if (_listeningUid != uid) return;
        savedIds.value = snapshot.docs
            .map((doc) => doc.data()['plantId'])
            .whereType<String>()
            .toSet();
      },
      onError: (Object error) {
        if (_listeningUid != uid) return;
        debugPrint('Saved plants status error: $error');
        savedIds.value = null;
      },
    );
  }
}

/// Non-interactive saved marker. Only appears after a confirmed savedPlants read.
class RuwaSavedBadge extends StatelessWidget {
  const RuwaSavedBadge({
    super.key,
    required this.plantId,
    this.compact = false,
  });

  final String plantId;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final status = RuwaSavedPlantsStatus.instance;
    status.ensureStarted();
    return ValueListenableBuilder<Set<String>?>(
      valueListenable: status.savedIds,
      builder: (context, ids, _) {
        if (ids == null || !ids.contains(plantId)) {
          return const SizedBox.shrink();
        }
        return Semantics(
          label: 'محفوظ في نباتاتي',
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 7 : 10,
              vertical: compact ? 4 : 6,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFE1F2DE),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFC5DFC0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded,
                    size: 15, color: Color(0xFF315B32)),
                const SizedBox(width: 4),
                Text(
                  compact ? 'محفوظ' : 'محفوظ في نباتاتي',
                  maxLines: 1,
                  style: GoogleFonts.cairo(
                    fontSize: compact ? 11 : 12,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF234525),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
