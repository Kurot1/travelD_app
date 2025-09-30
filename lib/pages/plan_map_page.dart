import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import '../models/travel_spot.dart';
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

  @override
  Widget build(BuildContext context) {
    final initial =
    widget.spots.isNotEmpty ? widget.spots.first.nlatlng : widget.start;

    return Scaffold(
      appBar: AppBar(title: Text('추천 코스 (${widget.spots.length})')),
      body: Column(
        children: [
          Expanded(
            child: NaverMap(
              options: NaverMapViewOptions(
                initialCameraPosition:
                NCameraPosition(target: initial, zoom: 13),
                indoorEnable: true,
              ),
              onMapReady: (c) async {
                _controller = c;
                await _drawPath();
              },
            ),
          ),
          _segmentButtons(),
        ],
      ),
      floatingActionButton: widget.spots.isEmpty
          ? null
          : FloatingActionButton.extended(
        icon: const Icon(Icons.navigation),
        label: const Text('첫 목적지로 길안내'),
        onPressed: () {
          final first = widget.spots.first;
          NaverNav.openNavigationTo(
            dlat: first.lat,
            dlng: first.lng,
            dname: first.nameKo,
          );
        },
      ),
    );
  }

  Future<void> _drawPath() async {
    // 마커
    for (int i = 0; i < widget.spots.length; i++) {
      final s = widget.spots[i];
      final marker = NMarker(
        id: 'm$i',
        position: s.nlatlng,
        caption: NOverlayCaption(text: '${i + 1}. ${s.nameKo}'),
      );
      await _controller.addOverlay(marker);
    }

    // 경로
    if (widget.spots.length >= 2) {
      final coords = widget.spots.map((e) => e.nlatlng).toList();
      final path = NPathOverlay(
        id: 'path1',
        coords: coords,
        color: const Color(0xFF0066FF),
        width: 6,
        outlineColor: const Color(0xFFFFFFFF),
        outlineWidth: 2,
      );
      await _controller.addOverlay(path);
    }
  }

  Widget _segmentButtons() {
    if (widget.spots.length < 2) return const SizedBox.shrink();
    return SizedBox(
      height: 120,
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        scrollDirection: Axis.horizontal,
        itemCount: widget.spots.length - 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final a = widget.spots[i];
          final b = widget.spots[i + 1];
          return ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(200, 100)),
            onPressed: () {
              NaverNav.openWalkRoute(
                slat: a.lat,
                slng: a.lng,
                sname: a.nameKo,
                dlat: b.lat,
                dlng: b.lng,
                dname: b.nameKo,
              );
            },
            child: Text('${i + 1} → ${i + 2} 도보 경로'),
          );
        },
      ),
    );
  }
}
