import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import '../models/travel_spot.dart';
import '../services/address_resolver.dart';
import '../services/naver_navigation.dart';

class PlanMapPage extends StatefulWidget {
  final NLatLng start;
  final List<TravelSpot> spots;
  const PlanMapPage({super.key, required this.start, required this.spots});

  @override
  State<PlanMapPage> createState() => _PlanMapPageState();
}

class _PlanMapPageState extends State<PlanMapPage> {
  late NaverMapController _controller;

  // 새 핀 이미지 (카카오톡으로 받은 4개 PNG를 assets 폴더에 저장했다고 가정)
  // 파일 이름은 pubspec.yaml 의 assets 경로와 반드시 일치해야 합니다.
  static const List<String> _pinAssets = [
    'assets/pin_red.png', // 1번 (빨강)
    'assets/pin_orange.png', // 2번 (오렌지)
    'assets/pin_green.png', // 3번 (초록)
    'assets/pin_blue.png', // 4번 (파랑)
  ];

  // 마커 순서 레전드 색상도 핀 색과 맞춰서 조정
  static const List<Color> _badgeColors = [
    Color(0xFFF48484), // 레드
    Color(0xFFF7B86B), // 오렌지
    Color(0xFFB6E58C), // 그린
    Color(0xFFA8B3FF), // 블루
  ];

  String _pinAssetForIndex(int index) {
    return _pinAssets[index % _pinAssets.length];
  }

  Color _badgeColor(int index, int total) {
    return _badgeColors[index % _badgeColors.length];
  }

  @override
  Widget build(BuildContext context) {
    final initial =
    widget.spots.isNotEmpty ? widget.spots.first.nlatlng : widget.start;

    return Scaffold(
      appBar:
      AppBar(title: Text('추천 코스 (${widget.spots.length} spot)')),
      body: Column(
        children: [
          Expanded(
            child: NaverMap(
              options: NaverMapViewOptions(
                initialCameraPosition:
                NCameraPosition(target: initial, zoom: 13),
              ),
              onMapReady: (controller) async {
                _controller = controller;
                await _drawPath();
              },
            ),
          ),
          _orderLegend(context),
        ],
      ),
      floatingActionButton: widget.spots.isEmpty
          ? null
          : FloatingActionButton.extended(
        icon: const Icon(Icons.navigation),
        label: const Text('첫 목적지로 길안내'),
        onPressed: () async {
          final first = widget.spots.first;
          final destName = await AddressResolver.resolve(
            lat: first.lat,
            lng: first.lng,
            fallback: first.nameKo,
          );
          await NaverNav.openNavigationTo(
            dlat: first.lat,
            dlng: first.lng,
            dname: destName,
          );
        },
      ),
    );
  }

  Future<void> _drawPath() async {
    for (int i = 0; i < widget.spots.length; i++) {
      final s = widget.spots[i];

      final marker = NMarker(
        id: 'm$i',
        position: s.nlatlng,
        icon: NOverlayImage.fromAssetImage(
          _pinAssetForIndex(i),
        ),
        anchor: const NPoint(0.5, 1.0),
      );

      await _controller.addOverlay(marker);
    }

    if (widget.spots.length >= 2) {
      final path = NPolylineOverlay(
        id: 'course_path',
        coords: widget.spots.map((e) => e.nlatlng).toList(),
        width: 4,
        color: const Color(0xFF111827),
      );
      await _controller.addOverlay(path);
    }
  }

  Widget _orderLegend(BuildContext context) {
    final total = widget.spots.length;
    if (total == 0) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (int i = 0; i < total; i++)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _badgeColor(i, total),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${i + 1}. ${widget.spots[i].nameKo}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black87,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
