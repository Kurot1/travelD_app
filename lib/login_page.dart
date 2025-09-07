import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'naver_map_page.dart';
import 'register_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController idController = TextEditingController();
    final TextEditingController pwController = TextEditingController();

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/KakaoTalk_20250526_020250084.png',
                width: 200,
                height: 200,
              ),
              const SizedBox(height: 30),
              TextField(
                controller: idController,
                decoration: const InputDecoration(labelText: "이메일"),
              ),
              TextField(
                controller: pwController,
                decoration: const InputDecoration(labelText: "비밀번호"),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await FirebaseAuth.instance.signInWithEmailAndPassword(
                      email: idController.text.trim(),
                      password: pwController.text.trim(),
                    );
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const NaverMapPage()),
                    );
                  } catch (e) {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("로그인 실패"),
                        content: Text(e.toString()),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("확인"),
                          ),
                        ],
                      ),
                    );
                  }
                },
                child: const Text("로그인"),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  );
                },
                child: const Text("회원가입"),
              ),
              const Divider(height: 40),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
                    if (googleUser == null) return; // 로그인 취소됨

                    final GoogleSignInAuthentication googleAuth =
                    await googleUser.authentication;

                    final credential = GoogleAuthProvider.credential(
                      accessToken: googleAuth.accessToken,
                      idToken: googleAuth.idToken,
                    );

                    await FirebaseAuth.instance.signInWithCredential(credential);

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const NaverMapPage()),
                    );
                  } catch (e) {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Google 로그인 실패"),
                        content: Text(e.toString()),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("확인"),
                          ),
                        ],
                      ),
                    );
                  }
                },
                child: const Text("Google 계정으로 로그인"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}