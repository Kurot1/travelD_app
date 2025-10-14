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
          if (widget.spots.isNotEmpty) _orderLegend(context),
          _segmentButtons(),
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
    // 마커
    for (int i = 0; i < widget.spots.length; i++) {
      final s = widget.spots[i];
      final marker = NMarker(
        id: 'm$i',
        position: s.nlatlng,
        caption: NOverlayCaption(text: '${i + 1}'),
      );
      await _controller.addOverlay(marker);
    }
  }

  Widget _orderLegend(BuildContext context) {
    final total = widget.spots.length;
    if (total == 0) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '방문 순서를 번호로 확인해보세요',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: total,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, index) {
                final spot = widget.spots[index];
                return _OrderBadge(
                  index: index,
                  color: _badgeColor(index, total),
                  label: spot.nameKo,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _badgeColor(int index, int total) {
    const start = Color(0xFF0066FF);
    const end = Color(0xFFFF7043);
    if (total <= 1) return start;
    final t = index / (total - 1);
    return Color.lerp(start, end, t)!;
  }

  Widget _segmentButtons() {
    if (widget.spots.length < 2) return const SizedBox.shrink();
    final totalSegments = widget.spots.length;
    return SizedBox(
      height: 120,
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        scrollDirection: Axis.horizontal,
        itemCount: totalSegments,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final fromLat = i == 0 ? widget.start.latitude : widget.spots[i - 1].lat;
          final fromLng = i == 0 ? widget.start.longitude : widget.spots[i - 1].lng;
          final fromFallback = i == 0 ? '출발지' : widget.spots[i - 1].nameKo;
          final toSpot = widget.spots[i];
          return ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(200, 100)),
            onPressed: () async {
              final startName = await AddressResolver.resolve(
                lat: fromLat,
                lng: fromLng,
                fallback: fromFallback,
              );
              final destName = await AddressResolver.resolve(
                lat: toSpot.lat,
                lng: toSpot.lng,
                fallback: toSpot.nameKo,
              );
              await NaverNav.openWalkRoute(
                slat: fromLat,
                slng: fromLng,
                sname: startName,
                dlat: toSpot.lat,
                dlng: toSpot.lng,
                dname: destName,
              );
            },
            child: Text(
              i == 0
                  ? '출발지 → 1 도보 경로'
                  : '${i} → ${i + 1} 도보 경로',
            ),
          );
        },
      ),
    );
  }
}

class _OrderBadge extends StatelessWidget {
  final int index;
  final Color color;
  final String label;

  const _OrderBadge({
    required this.index,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: color,
          child: Text(
            '${index + 1}',
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 88,
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
