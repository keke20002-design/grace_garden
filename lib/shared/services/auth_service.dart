import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<User?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = cred.user!;
    await user.updateDisplayName(displayName);

    // Firestore에 유저 프로필 생성
    await _db.collection('users').doc(user.uid).set({
      'displayName': displayName,
      'email': email,
      'totalTalents': 0,
      'treeStage': 0,
      'qtStreak': 0,
      'totalQtCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return user;
  }

  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
  }

  Future<void> signOut() => _auth.signOut();

  /// 익명 로그인 (main.dart 부트스트랩용)
  Future<User?> signInAnonymously() async {
    final cred = await _auth.signInAnonymously();
    return cred.user;
  }

  /// 익명 계정을 이메일/비밀번호 계정으로 업그레이드
  /// UID가 보존되므로 기존 QT 기록이 유지됨
  Future<User?> linkAnonymousAccount({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final user = _auth.currentUser;
    if (user == null || !user.isAnonymous) throw Exception('No anonymous user');
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    final linked = await user.linkWithCredential(credential);
    final linkedUser = linked.user!;
    await linkedUser.updateDisplayName(displayName);
    await _db.collection('users').doc(linkedUser.uid).set({
      'displayName': displayName,
      'email': email,
      'totalTalents': 0,
      'treeStage': 0,
      'qtStreak': 0,
      'totalQtCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return linkedUser;
  }
}
