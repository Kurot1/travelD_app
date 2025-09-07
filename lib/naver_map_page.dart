import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'create_course_page.dart';

class TravelSpot {
  final String name;
  final NLatLng location;

  TravelSpot(this.name, this.location);
}

final Map<String, List<TravelSpot>> travelScenarios = {
  '서울 여행': [
    TravelSpot('경복궁', NLatLng(37.5796, 126.9770)),
    TravelSpot('남산타워', NLatLng(37.5512, 126.9882)),
    TravelSpot('롯데월드', NLatLng(37.5110, 127.0980)),
  ],
  '대전 여행': [
    TravelSpot('계족산 황톳길', NLatLng(36.3751, 127.4691)),
    TravelSpot('국립중앙과학관', NLatLng(36.3755, 127.3869)),
    TravelSpot('대전시립미술관', NLatLng(36.3630, 127.3875)),
  ],
};

class NaverMapPage extends StatefulWidget {
  const NaverMapPage({super.key});

  @override
  State<NaverMapPage> createState() => _NaverMapPageState();
}

class _NaverMapPageState extends State<NaverMapPage> {
  final Completer<NaverMapController> _mapController = Completer();
  String _selectedScenario = '서울 여행';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadScenario(_selectedScenario);
    });
  }

  Future<void> _loadScenario(String scenario) async {
    final controller = await _mapController.future;
    await controller.clearOverlays();

    final spots = List<TravelSpot>.from(travelScenarios[scenario]!);
    final start = spots.first.location;

    spots.sort((a, b) {
      final distA = (a.location.latitude - start.latitude).abs() +
          (a.location.longitude - start.longitude).abs();
      final distB = (b.location.latitude - start.latitude).abs() +
          (b.location.longitude - start.longitude).abs();
      return distA.compareTo(distB);
    });

    List<NLatLng> pathPoints = [];

    for (var spot in spots) {
      final marker = NMarker(
        id: spot.name,
        position: spot.location,
        caption: NOverlayCaption(
          text: spot.name,
          color: Colors.blue,
          textSize: 14,
        ),
      );
      await controller.addOverlay(marker);
      pathPoints.add(spot.location);
    }

    final path = NPathOverlay(
      id: 'path_$scenario',
      coords: pathPoints,
      width: 4,
    );
    await controller.addOverlay(path);

    await controller.updateCamera(
      NCameraUpdate.scrollAndZoomTo(
        target: pathPoints[0],
        zoom: 13,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("여행 시나리오 지도")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: _selectedScenario,
              items: travelScenarios.keys.map((scenario) {
                return DropdownMenuItem(
                  value: scenario,
                  child: Text(scenario),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedScenario = value;
                  });
                  _loadScenario(value);
                }
              },
            ),
          ),
          Expanded(
            child: NaverMap(
              options: const NaverMapViewOptions(
                initialCameraPosition: NCameraPosition(
                  target: NLatLng(37.5665, 126.9780),
                  zoom: 12,
                ),
              ),
              onMapReady: (controller) {
                _mapController.complete(controller);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newScenario = await Navigator.push<String>(
            context,
            MaterialPageRoute(builder: (_) => const CreateCoursePage()),
          );
          if (newScenario != null && travelScenarios.containsKey(newScenario)) {
            setState(() {
              _selectedScenario = newScenario;
            });
            _loadScenario(newScenario);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}