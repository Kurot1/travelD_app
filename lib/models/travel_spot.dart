import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

enum EnvTag { indoor, outdoor }
enum CatTag { culture, nature, shopping, cafe, food, kids, sleep }
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

  factory TravelSpot.fromFirestore(
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data();

    double? _toDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    final lat = _toDouble(data['lat']);
    final lng = _toDouble(data['lng']);
    if (lat == null || lng == null) {
      throw StateError('위치 정보가 없는 여행지입니다: ${doc.id}');
    }

    final envTags = <String>{
      ..._stringTags(data['env']),
      ..._stringTags(data['envs']),
      ..._stringTags(data['envTags']),
      ..._stringTags(data['tags']),
    };
    final catTags = <String>{
      ..._stringTags(data['cat']),
      ..._stringTags(data['cats']),
      ..._stringTags(data['catTags']),
      ..._stringTags(data['categories']),
      ..._stringTags(data['tags']),
    };

    final env = _envFromStrings(envTags);
    final cat = _catFromStrings(catTags);

    return TravelSpot(
      id: doc.id,
      nameKo: (data['nameKo'] as String?)?.trim().isNotEmpty == true
          ? (data['nameKo'] as String).trim()
          : '이름 없음',
      city: (data['city'] as String?)?.trim() ?? '',
      lat: lat,
      lng: lng,
      env: env.isEmpty ? {EnvTag.indoor, EnvTag.outdoor} : env,
      cat: cat.isEmpty ? CatTag.values.toSet() : cat,
    );
  }

  static Set<String> _stringTags(dynamic value) {
    final result = <String>{};
    if (value is Iterable) {
      for (final v in value) {
        if (v is String && v.trim().isNotEmpty) {
          result.add(v.trim().toLowerCase());
        }
      }
    } else if (value is String && value.trim().isNotEmpty) {
      result.add(value.trim().toLowerCase());
    }
    return result;
  }

  static Set<EnvTag> _envFromStrings(Set<String> values) {
    final result = <EnvTag>{};
    for (final v in values) {
      switch (v) {
        case 'indoor':
          result.add(EnvTag.indoor);
          break;
        case 'outdoor':
          result.add(EnvTag.outdoor);
          break;
      }
    }
    return result;
  }

  static Set<CatTag> _catFromStrings(Set<String> values) {
    final result = <CatTag>{};
    for (final v in values) {
      switch (v) {
        case 'culture':
          result.add(CatTag.culture);
          break;
        case 'nature':
          result.add(CatTag.nature);
          break;
        case 'shopping':
          result.add(CatTag.shopping);
          break;
        case 'cafe':
          result.add(CatTag.cafe);
          break;
        case 'food':
          result.add(CatTag.food);
          break;
        case 'kids':
          result.add(CatTag.kids);
          break;
        case 'sleep':
          result.add(CatTag.sleep);
          break;
      }
    }
    return result;
  }
  }

