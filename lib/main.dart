import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FlutterNaverMap().init(
    clientId: 'b3tp7muoxf',
    onAuthFailed: (ex) => switch (ex) {
      NQuotaExceededException(:final message) =>
          print("사용량 초과 (message: $message)"),
      NUnauthorizedClientException() ||
      NClientUnspecifiedException() ||
      NAnotherAuthFailedException() =>
          print("인증 실패: $ex"),
    },
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: LoginPage(),
    );
  }
}