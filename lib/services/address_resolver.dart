import 'package:geocoding/geocoding.dart';

/// 간단한 역지오코딩 유틸리티.
///
/// 네이버 지도 URL 스킴 호출 시에는 위도/경도뿐 아니라
/// 사람이 읽을 수 있는 출발지, 도착지 이름을 넘겨야 화면에서
/// 주소가 정상적으로 표시된다. 이 클래스는 좌표를 주소 문자열로
/// 변환하고, 여러 번 호출될 때는 캐시된 값을 재사용한다.
class AddressResolver {
  AddressResolver._();

  static final Map<String, String> _cache = {};

  /// [lat], [lng] 좌표를 한국어 주소 문자열로 변환한다.
  ///
  /// 변환에 실패하면 [fallback] 값을 사용하고, 그것조차 없으면
  /// 빈 문자열을 반환한다.
  static Future<String> resolve({
    required double lat,
    required double lng,
    String? fallback,
  }) async {
    final key = '${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';
    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    String resolved = fallback ?? '';
    try {
      final placemarks = await placemarkFromCoordinates(
        lat,
        lng,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = <String?>[
          place.administrativeArea,
          place.locality,
          place.subLocality,
          place.thoroughfare,
          place.subThoroughfare,
        ]
            .where((e) => e != null && e.trim().isNotEmpty)
            .map((e) => e!.trim())
            .toList();

        if (parts.isNotEmpty) {
          resolved = parts.join(' ');
        } else if (place.name != null && place.name!.trim().isNotEmpty) {
          resolved = place.name!.trim();
        }
      }
    } catch (_) {
      // 네트워크 오류나 지원하지 않는 위치일 때는 fallback 사용
    }

    resolved = resolved.replaceFirst(RegExp(r'^대한민국\s*'), '');

    if (resolved.isEmpty && fallback != null) {
      resolved = fallback;
    }

    _cache[key] = resolved;
    return resolved;
  }
}