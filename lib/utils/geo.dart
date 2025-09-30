import 'dart:math';
import 'package:flutter_naver_map/flutter_naver_map.dart';

double haversineMeters(NLatLng a, NLatLng b) {
  const R = 6371000.0;
  final dLat = _deg2rad(b.latitude - a.latitude);
  final dLng = _deg2rad(b.longitude - a.longitude);
  final la1 = _deg2rad(a.latitude);
  final la2 = _deg2rad(b.latitude);
  final h = pow(sin(dLat / 2), 2) + cos(la1) * cos(la2) * pow(sin(dLng / 2), 2);
  return 2 * R * asin(sqrt(h));
}

double _deg2rad(double deg) => deg * pi / 180.0;
