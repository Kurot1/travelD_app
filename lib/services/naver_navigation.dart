import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

class NaverNav {
  // 네 앱의 applicationId와 동일하게 맞춰라 (예: com.example.traveltest2)
  static const _appName = 'com.example.test2';

  static Future<void> openNavigationTo({
    required double dlat,
    required double dlng,
    required String dname,
  }) async {
    final uri = Uri.parse(
      'nmap://navigation?dlat=$dlat&dlng=$dlng&dname=${Uri.encodeComponent(dname)}&appname=$_appName',
    );
    await _launchOrStore(uri);
  }

  static Future<void> openWalkRoute({
    required double slat, required double slng, required String sname,
    required double dlat, required double dlng, required String dname,
  }) async {
    final uri = Uri.parse(
      'nmap://route/walk?slat=$slat&slng=$slng&sname=${Uri.encodeComponent(sname)}'
          '&dlat=$dlat&dlng=$dlng&dname=${Uri.encodeComponent(dname)}&appname=$_appName',
    );
    await _launchOrStore(uri);
  }

  static Future<void> openCarRoute({
    required double slat, required double slng, required String sname,
    required double dlat, required double dlng, required String dname,
  }) async {
    final uri = Uri.parse(
      'nmap://route/car?slat=$slat&slng=$slng&sname=${Uri.encodeComponent(sname)}'
          '&dlat=$dlat&dlng=$dlng&dname=${Uri.encodeComponent(dname)}&appname=$_appName',
    );
    await _launchOrStore(uri);
  }

  static Future<void> _launchOrStore(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (Platform.isAndroid) {
        final market = Uri.parse('market://details?id=com.nhn.android.nmap');
        await launchUrl(market, mode: LaunchMode.externalApplication);
      } else if (Platform.isIOS) {
        final appStore = Uri.parse('https://apps.apple.com/app/id311867728');
        await launchUrl(appStore, mode: LaunchMode.externalApplication);
      }
    }
  }
}
