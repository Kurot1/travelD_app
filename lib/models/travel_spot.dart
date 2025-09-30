import 'package:flutter_naver_map/flutter_naver_map.dart';

enum EnvTag { indoor, outdoor }
enum CatTag { culture, nature, shopping, cafe, food, kids, night }
enum DistPref { near, far } // near: 1.5km 이내, far: 1.5km 초과

class TravelSpot {
  final String id;
  final String nameKo; // 노출명(한글)
  final String city;   // 도시명
  final double lat;
  final double lng;
  final Set<EnvTag> env;
  final Set<CatTag> cat;

  const TravelSpot({
    required this.id,
    required this.nameKo,
    required this.city,
    required this.lat,
    required this.lng,
    required this.env,
    required this.cat,
  });

  NLatLng get nlatlng => NLatLng(lat, lng);
}
