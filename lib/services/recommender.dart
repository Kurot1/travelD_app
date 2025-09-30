import 'dart:math';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import '../models/travel_spot.dart';
import '../utils/geo.dart';

class StepFilter {
  final Set<EnvTag> envs;   // 비어있으면 전체 허용
  final Set<CatTag> cats;   // 비어있으면 전체 허용
  final DistPref dist;      // near(≤1.5km) / far(>1.5km)

  const StepFilter({
    required this.envs,
    required this.cats,
    required this.dist,
  });

  StepFilter copyWith({Set<EnvTag>? envs, Set<CatTag>? cats, DistPref? dist}) {
    return StepFilter(
      envs: envs ?? this.envs,
      cats: cats ?? this.cats,
      dist: dist ?? this.dist,
    );
  }
}

class FilterInput {
  final int count;               // 추천 개수
  final NLatLng start;           // 출발 기준점
  final List<StepFilter> steps;  // 스텝별 필터(길이는 count 이상이면 됨)

  const FilterInput({
    required this.count,
    required this.start,
    required this.steps,
  });
}

class RecommendResult {
  final List<TravelSpot> spots;
  const RecommendResult(this.spots);
}

class Recommender {
  final List<TravelSpot> pool;
  final Random _rng;

  Recommender(this.pool, {int? seed})
      : _rng = Random(seed ?? DateTime.now().millisecondsSinceEpoch);

  RecommendResult recommend(FilterInput input) {
    if (pool.isEmpty || input.count <= 0) return const RecommendResult([]);

    final List<TravelSpot> path = [];
    NLatLng anchor = input.start;

    for (int i = 0; i < input.count; i++) {
      final step = input.steps[i];

      bool _envOk(TravelSpot s) =>
          step.envs.isEmpty || s.env.any(step.envs.contains);
      bool _catOk(TravelSpot s) =>
          step.cats.isEmpty || s.cat.any(step.cats.contains);
      bool _distOk(TravelSpot s) {
        final d = haversineMeters(anchor, s.nlatlng);
        return step.dist == DistPref.near ? d <= 1500 : d > 1500;
      }

      List<TravelSpot> base = pool.where((s) => !path.any((p) => p.id == s.id)).toList();

      // 1차: env+cat+dist
      var cand = base.where((s) => _envOk(s) && _catOk(s) && _distOk(s)).toList();

      // 2차: env+cat (거리 완화)
      if (cand.isEmpty) cand = base.where((s) => _envOk(s) && _catOk(s)).toList();

      // 3차: cat만
      if (cand.isEmpty) cand = base.where((s) => _catOk(s)).toList();

      // 4차: 아무거나
      if (cand.isEmpty) cand = base;

      if (cand.isEmpty) break;

      // 거리 기준 정렬 후 가까운 상위 K개에서 랜덤
      cand.sort((a, b) {
        final da = haversineMeters(anchor, a.nlatlng);
        final db = haversineMeters(anchor, b.nlatlng);
        return da.compareTo(db);
      });
      final k = cand.length < 5 ? cand.length : 5;
      final chosen = cand[_rng.nextInt(k)];

      path.add(chosen);
      anchor = chosen.nlatlng;
    }

    return RecommendResult(path);
  }
}
