import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class FirebaseService {
  // Firebase Auth 인스턴스
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Firestore 인스턴스
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Google Sign In 인스턴스 - 웹용 설정 추가
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // 웹에서 사용할 때만 스코프와 클라이언트 ID 추가
    scopes: [
      'email',
      'profile',
    ],
    clientId: kIsWeb
        ? '97108639991-or1342sfq5sjh72cccvrf6224oosrpe2.apps.googleusercontent.com'
        : null,
  );

  // 현재 로그인한 사용자 가져오기
  User? get currentUser => _auth.currentUser;

  // 인증 상태 변화 감지 스트림
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 이메일/비밀번호로 회원가입
  Future<UserCredential> signUpWithEmail(String email, String password,
      {String? name}) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // 사용자 정보를 Firestore에 저장
      await _saveUserToFirestore(
        userCredential.user,
        displayName: name,
      );

      // 이름이 제공된 경우 Firebase Auth 프로필 업데이트
      if (name != null && name.isNotEmpty) {
        await userCredential.user?.updateDisplayName(name);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // 이메일/비밀번호로 로그인
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Google 계정으로 로그인
  Future<UserCredential> signInWithGoogle() async {
    try {
      print('Google 로그인 시도 중...');

      if (kIsWeb) {
        print('웹 환경용 Google 로그인 사용');

        // Google OAuth 제공자 설정
        GoogleAuthProvider googleProvider = GoogleAuthProvider();

        // 필요한 스코프 추가
        googleProvider.addScope('email');
        googleProvider.addScope('profile');

        // 로그인 UI 언어 설정
        googleProvider
            .setCustomParameters({'locale': 'ko', 'prompt': 'select_account'});

        try {
          // 팝업 방식 사용 (권장)
          print('팝업 방식으로 Google 로그인 시도');
          final userCredential = await _auth.signInWithPopup(googleProvider);
          print('Google 팝업 로그인 성공');

          // 사용자 정보 처리
          await _processUserLogin(userCredential);
          return userCredential;
        } catch (popupError) {
          print('팝업 로그인 실패, 오류: $popupError');

          // 팝업이 차단되었거나 실패한 경우 리디렉션 방식으로 시도
          print('리디렉션 방식으로 전환');

          // 기존 리디렉션 결과 확인 (이전에 리디렉션된 경우)
          try {
            final userCredential = await _auth.getRedirectResult();
            if (userCredential.user != null) {
              print('기존 리디렉션 로그인 결과 사용 (사용자 있음)');
              await _processUserLogin(userCredential);
              return userCredential;
            }
          } catch (redirectResultError) {
            print('기존 리디렉션 결과 없음: $redirectResultError');
          }

          // 리디렉션 시작
          print('새 Google 리디렉션 로그인 시작');
          await _auth.signInWithRedirect(googleProvider);

          // 리디렉션 후에는 페이지가 다시 로드되므로 여기서 오류 발생
          throw Exception('Google 계정으로 로그인 진행 중입니다. 잠시만 기다려주세요...');
        }
      } else {
        // 모바일/데스크톱 앱에서는 기존 방식 사용
        print('모바일/데스크톱 환경용 Google 로그인 사용');

        // Google 로그인 프로세스 시작
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

        if (googleUser == null) {
          throw Exception('Google 로그인이 취소되었습니다.');
        }

        // 인증 정보 가져오기
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        // Firebase 인증 정보 생성
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Firebase에 로그인
        final userCredential = await _auth.signInWithCredential(credential);

        // 사용자 정보 처리
        await _processUserLogin(userCredential);
        return userCredential;
      }
    } catch (e) {
      print('Google 로그인 오류: $e');
      throw Exception('Google 로그인 중 오류가 발생했습니다: $e');
    }
  }

  // 로그인 성공 후 사용자 정보 처리
  Future<void> _processUserLogin(UserCredential userCredential) async {
    if (userCredential.user == null) return;

    print('로그인 성공: ${userCredential.user!.uid}');

    // 신규 사용자인 경우 Firestore에 정보 저장
    if (userCredential.additionalUserInfo?.isNewUser ?? false) {
      await _saveUserToFirestore(userCredential.user);
      print('신규 사용자 정보 저장 완료');
    } else {
      print('기존 사용자 로그인');
      // 마지막 로그인 시간 업데이트
      try {
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('최근 로그인 시간 업데이트 오류: $e');
      }
    }
  }

  // 게스트 로그인
  Future<UserCredential> signInAnonymously() async {
    print('게스트 로그인 시도 중...');
    try {
      // 기존 익명 세션이 있으면 먼저 로그아웃
      if (_auth.currentUser != null && _auth.currentUser!.isAnonymous) {
        print('기존 익명 세션 발견, 로그아웃 시도...');
        await _auth.signOut();
        print('기존 익명 세션 로그아웃 완료');
      }

      // 새 익명 로그인 시도
      UserCredential userCredential = await _auth.signInAnonymously();
      print('익명 로그인 성공: ${userCredential.user?.uid}');

      // 게스트 사용자 정보도 Firestore에 저장
      try {
        await _saveUserToFirestore(userCredential.user, isGuest: true);
        print('게스트 사용자 정보 저장 완료');
      } catch (e) {
        print('Firestore 저장 중 오류 발생: $e');
        // Firestore 저장 실패해도 로그인은 성공한 것으로 처리
      }

      // 로그인 후 상태 확인
      print('최종 로그인 상태: ${_auth.currentUser != null ? "로그인됨" : "로그인되지 않음"}');

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('익명 로그인 실패: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('게스트 로그인 중 예상치 못한 오류: $e');
      throw Exception('게스트 로그인 중 오류가 발생했습니다: $e');
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // 사용자 정보를 Firestore에 저장
  Future<void> _saveUserToFirestore(User? user,
      {bool isGuest = false, String? displayName}) async {
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': displayName ?? user.displayName ?? '',
        'photoURL': user.photoURL ?? '',
        'isGuest': isGuest,
        'lastLogin': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Firestore에 사용자 정보 저장 중 오류: $e');
      // 사용자 정보 저장 실패는 로그인 자체를 실패시키지 않도록 함
    }
  }

  // Firebase 인증 예외 처리
  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return Exception('이미 사용 중인 이메일 주소입니다.');
      case 'invalid-email':
        return Exception('유효하지 않은 이메일 형식입니다.');
      case 'user-disabled':
        return Exception('해당 사용자 계정이 비활성화되었습니다.');
      case 'user-not-found':
        return Exception('해당 이메일로 등록된 사용자가 없습니다.');
      case 'wrong-password':
        return Exception('잘못된 비밀번호입니다.');
      case 'weak-password':
        return Exception('비밀번호가 너무 약합니다.');
      case 'operation-not-allowed':
        return Exception(
            '이 작업은 허용되지 않습니다. Firebase 콘솔에서 익명 로그인이 활성화되어 있는지 확인해주세요.');
      default:
        return Exception('로그인 중 오류가 발생했습니다: ${e.message}');
    }
  }
}
