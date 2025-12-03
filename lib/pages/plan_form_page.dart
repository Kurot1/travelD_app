import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../models/travel_spot.dart';
import '../data/daejeon_spots.dart';
import '../services/gpt_recommendation_service.dart';
import '../services/recommender.dart';
import 'plan_map_page.dart';

// 색상 팔레트 (피그마 스타일)
const _pageBackground = Color(0xFFF3F4FF);
const _cardColor = Color(0xFFFDFDFF);
const _primaryAccent = Color(0xFF5F6AFB);
const _secondaryAccent = Color(0xFFCAD0FF);
const _pillGrey = Color(0xFFE3E6F4);
const _pillGreyDark = Color(0xFFB4B9D5);
const _buttonPink = Color(0xFFFAD6DE);
const _buttonPinkBorder = Color(0xFFF1B9C8);

enum _StartLocationMode { current, manual }

class PlanFormPage extends StatefulWidget {
  const PlanFormPage({super.key});

  @override
  State<PlanFormPage> createState() => _PlanFormPageState();
}

class _PlanFormPageState extends State<PlanFormPage> {
  final DaejeonSpotRepository _repo = DaejeonSpotRepository();
  late Future<List<TravelSpot>> _spotFuture;

  // 코스(스텝) 개수 = Visit Days
  int _count = 3;
  final List<int> _dayOptions = List.generate(5, (index) => index + 1);

  // 스텝별 필터 상태
  late List<StepFilter> _steps = List.generate(
    3,
        (_) => StepFilter(
      envs: {EnvTag.indoor, EnvTag.outdoor},
      cats: {},
      dist: DistPref.near,
    ),
  );
  final TextEditingController _locationController =
  TextEditingController(text: '대전시청');
  _StartLocationMode _startMode = _StartLocationMode.manual;
  NLatLng? _selectedStart;
  bool _isLocating = false;
  String? _locationInfo;


  @override
  void initState() {
    super.initState();
    _spotFuture = _repo.fetch();
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  NLatLng get _effectiveStart =>
      _selectedStart ?? const NLatLng(daejeonCenterLat, daejeonCenterLng);

  // _count 변경될 때 _steps 길이 맞추기
  void _ensureStepLength() {
    if (_steps.length == _count) return;

    if (_steps.length < _count) {
      final last = _steps.isNotEmpty
          ? _steps.last
          : StepFilter(
        envs: {EnvTag.indoor, EnvTag.outdoor},
        cats: {},
        dist: DistPref.near,
      );
      _steps = [
        ..._steps,
        ...List.generate(
          _count - _steps.length,
              (_) => StepFilter(
            envs: {...last.envs},
            cats: {...last.cats},
            dist: last.dist,
            fixedSpot: last.fixedSpot,
          ),
        ),
      ];
    } else {
      _steps = _steps.sublist(0, _count);
    }
  }

  void _reloadSpots() {
    setState(() {
      _spotFuture = _repo.fetch();
    });
  }
  Future<void> _setCurrentLocation() async {
    setState(() {
      _isLocating = true;
      _startMode = _StartLocationMode.current;
      _locationInfo = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationInfo = '위치 서비스를 켜주세요.';
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _locationInfo = '위치 권한이 필요합니다.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _selectedStart = NLatLng(position.latitude, position.longitude);
        _locationInfo = '현재 위치를 출발점으로 사용합니다.';
      });
    } catch (e) {
      setState(() {
        _locationInfo = '현재 위치를 불러오지 못했어요.';
      });
    } finally {
      setState(() {
        _isLocating = false;
      });
    }
  }

  Future<void> _setManualLocation() async {
    final keyword = _locationController.text.trim();
    if (keyword.isEmpty) {
      setState(() {
        _locationInfo = '주소나 지명을 입력해주세요.';
      });
      return;
    }

    setState(() {
      _isLocating = true;
      _startMode = _StartLocationMode.manual;
      _locationInfo = null;
    });

    try {
      final results = await locationFromAddress(keyword);
      if (results.isEmpty) {
        setState(() {
          _locationInfo = '입력한 위치를 찾지 못했어요.';
        });
        return;
      }

      final target = results.first;
      setState(() {
        _selectedStart = NLatLng(target.latitude, target.longitude);
        _locationInfo = '"$keyword"을(를) 출발점으로 설정했어요.';
      });
    } catch (e) {
      setState(() {
        _locationInfo = '위치를 불러오지 못했어요.';
      });
    } finally {
      setState(() {
        _isLocating = false;
      });
    }
  }

  Widget _buildStateMessage(String message) {
    return Container(
      color: _pageBackground,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF4B5563),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: _reloadSpots,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('다시 시도'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<TravelSpot> spots, NLatLng center) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 상단 타이틀 배너
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: _secondaryAccent),
                    ),
                    child: const Text(
                      'Travel Planning',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // city + Visit Days
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'city : Daejeon',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                    DropdownButtonHideUnderline(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _secondaryAccent),
                        ),
                        child: DropdownButton<int>(
                          value: _count,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF111827),
                          ),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _count = value;
                              _ensureStepLength();
                            });
                          },
                          items: _dayOptions
                              .map(
                                (d) => DropdownMenuItem<int>(
                              value: d,
                                  child: Text('여행지 $d개'),
                            ),
                          )
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // recommended 텍스트 + 구분선
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '출발 위치를 선택하세요',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _secondaryAccent),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('지금 위치'),
                            selected: _startMode == _StartLocationMode.current,
                            onSelected: _isLocating
                                ? null
                                : (_) => _setCurrentLocation(),
                          ),
                          ChoiceChip(
                            label: const Text('직접 설정'),
                            selected: _startMode == _StartLocationMode.manual,
                            onSelected: (v) {
                              if (v) {
                                setState(() {
                                  _startMode = _StartLocationMode.manual;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_startMode == _StartLocationMode.manual) ...[
                        const Text(
                          '주소나 지명을 입력하세요',
                          style: TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _locationController,
                                decoration: InputDecoration(
                                  isDense: true,
                                  hintText: '예) 대전시청',
                                  filled: true,
                                  fillColor: _pillGrey,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _isLocating ? null : _setManualLocation,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryAccent,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(64, 42),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('설정'),
                            ),
                          ],
                        ),
                      ] else ...[
                        const Text(
                          '현재 위치를 불러와 출발점으로 사용할게요.',
                          style: TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _isLocating ? null : _setCurrentLocation,
                          icon: const Icon(Icons.my_location_rounded, size: 16),
                          label: const Text('현재 위치로 설정'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _buttonPink,
                            foregroundColor: const Color(0xFF111827),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: _buttonPinkBorder),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (_isLocating)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          if (_isLocating) const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _locationInfo ?? '기본값: 대전 중심 좌표에서 출발합니다.',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '현재 적용 좌표: ${_effectiveStart.latitude.toStringAsFixed(5)}, ${_effectiveStart.longitude.toStringAsFixed(5)}',
                        style: const TextStyle(fontSize: 10, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 코스(스텝) 카드들 (Column + for 문)
                for (int index = 0; index < _count; index++) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Course ${index + 1}.',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _pillGrey.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: _StepCard(
                      index: index,
                      value: _steps[index],
                      allSpots: spots,
                      start: _effectiveStart,
                      onChanged: (nf) =>
                          setState(() => _steps[index] = nf),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 8),

                // Making Course 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final start = _selectedStart ?? center;
                      final input = FilterInput(
                        count: _count,
                        start: start,
                        steps: _steps,
                      );
                      final r = Recommender(spots).recommend(input);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PlanMapPage(start: start, spots: r.spots),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _buttonPink,
                      foregroundColor: const Color(0xFF111827),
                      elevation: 0,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: const BorderSide(color: _buttonPinkBorder),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome_rounded, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Making Course',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const center = NLatLng(daejeonCenterLat, daejeonCenterLng);
    _ensureStepLength();

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: FutureBuilder<List<TravelSpot>>(
          future: _spotFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _buildStateMessage(
                '여행지를 불러오지 못했어요.\n네트워크 상태를 확인한 뒤 다시 시도해주세요.',
              );
            }
            final spots = snapshot.data ?? [];
            if (spots.isEmpty) {
              return _buildStateMessage(
                '등록된 여행지가 없습니다.\n파이어베이스에 데이터를 추가한 뒤 새로고침해주세요.',
              );
            }
            return _buildContent(spots, center);
          },
        ),
      ),
    );
  }
}

// ───────────────── StepCard (기능 유지, 스타일만 변경) ─────────────────

class _StepCard extends StatefulWidget {
  final int index;
  final StepFilter value;
  final List<TravelSpot> allSpots;
  final ValueChanged<StepFilter> onChanged;
  final NLatLng start;
  final GptRecommendationService? gptService;

  const _StepCard({
    required this.index,
    required this.value,
    required this.allSpots,
    required this.onChanged,
    required this.start,
    this.gptService,
  });

  @override
  State<_StepCard> createState() => _StepCardState();
}

class _StepCardState extends State<_StepCard> {
  late Set<EnvTag> _envs;
  late Set<CatTag> _cats;
  late DistPref _dist;
  TravelSpot? _selectedSpot;
  List<TravelSpot> _recommendations = [];
  bool _isLoading = false;
  String? _infoMessage;
  late final GptRecommendationService _gptService;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _gptService = widget.gptService ?? GptRecommendationService();
    _syncFromWidget();
    if (_cats.isNotEmpty) {
      _fetchRecommendations();
    }
  }

  @override
  void didUpdateWidget(covariant _StepCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final catsChanged = !setEquals(oldWidget.value.cats, widget.value.cats);
    final fixedChanged =
        oldWidget.value.fixedSpot?.id != widget.value.fixedSpot?.id;
    final startChanged = oldWidget.start != widget.start;
    if (catsChanged || fixedChanged) {
      _syncFromWidget();
      if (catsChanged) {
        _fetchRecommendations();
      } else {
        setState(() {});
      }
    } else if (startChanged && _cats.isNotEmpty) {
      _fetchRecommendations();
    }
  }

  void _syncFromWidget() {
    _envs = {...widget.value.envs};
    _cats = {...widget.value.cats};
    _dist = widget.value.dist;
    final fixed = widget.value.fixedSpot;
    if (fixed != null) {
      _selectedSpot = widget.allSpots.firstWhere(
            (s) => s.id == fixed.id,
        orElse: () => fixed,
      );
    } else {
      _selectedSpot = null;
    }
  }

  Future<void> _fetchRecommendations() async {
    if (_cats.isEmpty) {
      _requestId++;
      setState(() {
        _isLoading = false;
        _recommendations = [];
        _selectedSpot = null;
        _infoMessage = null;
      });
      _emit();
      return;
    }

    final requestKey = ++_requestId;
    setState(() {
      _isLoading = true;
      _infoMessage = null;
    });

    final result = await _gptService.recommendTopSpots(
      spots: widget.allSpots,
      tags: _cats,
      start: widget.start,
      distPref: _dist,
      limit: 3,
    );

    if (!mounted || requestKey != _requestId) {
      return;
    }

    setState(() {
      _isLoading = false;
      _recommendations = result.spots
          .where((s) => _cats.every((tag) => s.cat.contains(tag)))
          .toList();
      if (result.usedFallback && !_gptService.isConfigured) {
        _infoMessage = 'OPENAI API Key가 없어 기본 인기순으로 추천했어요.';
      } else if (result.usedFallback) {
        _infoMessage = 'GPT 추천이 실패하여 기본 인기순으로 대체했어요.';
      } else {
        _infoMessage = null;
      }

      if (_recommendations.isEmpty) {
        _selectedSpot = null;
      } else if (_selectedSpot == null ||
          !_recommendations.any((s) => s.id == _selectedSpot!.id)) {
        _selectedSpot = _recommendations.first;
      }
    });

    _emit();
  }

  void _emit() {
    widget.onChanged(
      StepFilter(
        envs: {..._envs},
        cats: {..._cats},
        dist: _dist,
        fixedSpot: _selectedSpot,
      ),
    );
  }

  String _catLabel(CatTag c) {
    return switch (c) {
      CatTag.culture => '문화생활',
      CatTag.nature => '자연',
      CatTag.shopping => '쇼핑',
      CatTag.cafe => '카페',
      CatTag.food => '식당',
      CatTag.kids => '키즈',
      CatTag.sleep => '숙소',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // inside / outside 토글
        Row(
          children: EnvTag.values.map((e) {
            final sel = _envs.contains(e);
            final label = e == EnvTag.indoor ? 'inside' : 'outside';
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (sel) {
                        _envs.remove(e);
                      } else {
                        _envs.add(e);
                      }
                      if (_envs.isEmpty) {
                        _envs = {EnvTag.indoor, EnvTag.outdoor};
                      }
                    });
                    _emit();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 10),
                    decoration: BoxDecoration(
                      color: sel ? _primaryAccent : _pillGrey,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : const Color(0xFF4B5563),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),

        // 카테고리/거리 선택을 피그마처럼 "블록" 느낌으로
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // 카테고리 블록들
            ...CatTag.values.map((c) {
              final sel = _cats.contains(c);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (sel) {
                      _cats.remove(c);
                    } else {
                      _cats.add(c);
                    }
                    if (_cats.isEmpty) {
                      _selectedSpot = null;
                    } else if (_selectedSpot != null &&
                        !_cats.every((tag) => _selectedSpot!.cat.contains(tag))) {
                      _selectedSpot = null;
                    }
                  });
                  _emit();
                  _fetchRecommendations();
                },
                child: Container(
                  width: 70,
                  height: 26,
                  decoration: BoxDecoration(
                    color: sel ? _pillGreyDark : _pillGrey,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _catLabel(c),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ),
              );
            }),

            // 거리 선호 두 칸
            ...DistPref.values.map((d) {
              final isSel = _dist == d;
              final label = d == DistPref.near ? 'short' : 'long';
              return GestureDetector(
                onTap: () {
                  setState(() => _dist = d);
                  _emit();
                },
                child: Container(
                  width: 70,
                  height: 26,
                  decoration: BoxDecoration(
                    color:
                    isSel ? _primaryAccent.withOpacity(0.9) : _pillGrey,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                      isSel ? FontWeight.w600 : FontWeight.normal,
                      color: isSel
                          ? Colors.white
                          : const Color(0xFF4B5563),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),

        const SizedBox(height: 10),

        if (_cats.isEmpty)
          Text(
            '태그를 선택하면 GPT가 여행지를 추천해줘요.',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 11,
            ),
          )
        else ...[
          Row(
            children: [
              const Text(
                'GPT 추천',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              if (_isLoading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          if (_infoMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                _infoMessage!,
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontSize: 10,
                ),
              ),
            ),
          if (!_isLoading && _recommendations.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '해당 태그에 맞는 여행지가 없어요.',
                style: TextStyle(
                  color: Colors.red.shade400,
                  fontSize: 10,
                ),
              ),
            ),
          ..._recommendations.map((spot) {
            final categories = spot.cat.map(_catLabel).join(', ');
            return RadioListTile<String>(
              dense: true,
              visualDensity:
              const VisualDensity(horizontal: -4, vertical: -4),
              contentPadding: EdgeInsets.zero,
              value: spot.id,
              groupValue: _selectedSpot?.id,
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedSpot =
                      _recommendations.firstWhere((s) => s.id == value);
                });
                _emit();
              },
              title: Text(
                spot.nameKo,
                style: const TextStyle(fontSize: 12),
              ),
              subtitle: Text(
                '카테고리: $categories',
                style: const TextStyle(fontSize: 10),
              ),
            );
          }),
        ],
      ],
    );
  }
}
