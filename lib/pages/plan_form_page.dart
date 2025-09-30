import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import '../models/travel_spot.dart';
import '../data/daejeon_spots.dart';
import '../services/recommender.dart';
import 'plan_map_page.dart';

class PlanFormPage extends StatefulWidget {
  const PlanFormPage({super.key});
  @override
  State<PlanFormPage> createState() => _PlanFormPageState();
}

class _PlanFormPageState extends State<PlanFormPage> {
  int _count = 5;

  // 스텝별 필터 상태
  late List<StepFilter> _steps = List.generate(
    _count,
        (_) => StepFilter(envs: {EnvTag.indoor, EnvTag.outdoor}, cats: {}, dist: DistPref.near),
  );

  void _ensureStepLength() {
    if (_steps.length == _count) return;
    if (_steps.length < _count) {
      final last = _steps.isNotEmpty
          ? _steps.last
          : StepFilter(envs: {EnvTag.indoor, EnvTag.outdoor}, cats: {}, dist: DistPref.near);
      _steps = [
        ..._steps,
        ...List.generate(_count - _steps.length, (_) => last),
      ];
    } else {
      _steps = _steps.sublist(0, _count);
    }
  }

  @override
  Widget build(BuildContext context) {
    const center = NLatLng(daejeonCenterLat, daejeonCenterLng);
    _ensureStepLength();

    return Scaffold(
      appBar: AppBar(title: const Text('대전 코스 추천(스텝별 태그)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('여행지 갯수: $_count'),
              Slider(
                min: 2, max: 8, divisions: 6,
                value: _count.toDouble(),
                label: '$_count',
                onChanged: (v) => setState(() => _count = v.toInt()),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('각 스텝(1번→N번)의 태그와 거리 선호를 설정하세요.',
              style: TextStyle(color: Colors.grey)),

          const SizedBox(height: 8),
          for (int i = 0; i < _count; i++)
            _StepCard(
              index: i,
              value: _steps[i],
              onChanged: (nf) => setState(() => _steps[i] = nf),
            ),

          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.auto_awesome),
            label: const Text('추천 만들기'),
            onPressed: () {
              final input = FilterInput(
                count: _count,
                start: center,
                steps: _steps,
              );
              final r = Recommender(daejeonSpots).recommend(input);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlanMapPage(start: center, spots: r.spots),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatefulWidget {
  final int index;
  final StepFilter value;
  final ValueChanged<StepFilter> onChanged;
  const _StepCard({required this.index, required this.value, required this.onChanged});

  @override
  State<_StepCard> createState() => _StepCardState();
}

class _StepCardState extends State<_StepCard> {
  late Set<EnvTag> _envs = {...widget.value.envs};
  late Set<CatTag> _cats = {...widget.value.cats};
  late DistPref _dist = widget.value.dist;

  void _emit() => widget.onChanged(
    StepFilter(envs: _envs, cats: _cats, dist: _dist),
  );

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${widget.index + 1}번 여행지', style: const TextStyle(fontWeight: FontWeight.bold)),

          const SizedBox(height: 8),
          const Text('환경(복수 선택 가능)'),
          Wrap(
            spacing: 8,
            children: EnvTag.values.map((e) {
              final sel = _envs.contains(e);
              return FilterChip(
                label: Text(e == EnvTag.indoor ? '실내' : '실외'),
                selected: sel,
                onSelected: (_) {
                  setState(() {
                    sel ? _envs.remove(e) : _envs.add(e);
                    if (_envs.isEmpty) _envs = {EnvTag.indoor, EnvTag.outdoor}; // 최소 전체 허용
                  });
                  _emit();
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 8),
          const Text('카테고리(복수 선택 가능)'),
          Wrap(
            spacing: 8,
            children: CatTag.values.map((c) {
              final sel = _cats.contains(c);
              return FilterChip(
                label: Text(switch (c) {
                  CatTag.culture => '문화생활',
                  CatTag.nature => '자연',
                  CatTag.shopping => '쇼핑',
                  CatTag.cafe => '카페',
                  CatTag.food => '식당',
                  CatTag.kids => '키즈',
                  CatTag.night => '야간',
                }),
                selected: sel,
                onSelected: (_) {
                  setState(() {
                    sel ? _cats.remove(c) : _cats.add(c);
                  });
                  _emit();
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 8),
          const Text('거리 선호'),
          Wrap(
            spacing: 8,
            children: DistPref.values.map((d) {
              final isSel = _dist == d;
              return ChoiceChip(
                label: Text(d == DistPref.near ? '가까운(≤1.5km)' : '먼(>1.5km)'),
                selected: isSel,
                onSelected: (_) {
                  setState(() => _dist = d);
                  _emit();
                },
              );
            }).toList(),
          ),
        ]),
      ),
    );
  }
}
