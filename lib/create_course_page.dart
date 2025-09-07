import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'naver_map_page.dart';

class CreateCoursePage extends StatefulWidget {
  const CreateCoursePage({super.key});

  @override
  State<CreateCoursePage> createState() => _CreateCoursePageState();
}

class _CreateCoursePageState extends State<CreateCoursePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final Completer<NaverMapController> _mapController = Completer();
  final List<TravelSpot> _spots = [];

  Future<NLatLng?> _searchLocation(String query) async {
    if (query.isEmpty) return null;
    const baseUrl =
        'https://naveropenapi.apigw.ntruss.com/map-geocode/v2/geocode';
    final uri = Uri.parse('$baseUrl?query=${Uri.encodeComponent(query)}');

    try {
      final response = await http.get(uri, headers: const {
        'X-NCP-APIGW-API-KEY-ID': 'b3tp7muoxf',
        'X-NCP-APIGW-API-KEY': '4frxYjWKPXqMvDRDML7l8sKbna54vKTgpk7L9TbD',
      });
      debugPrint('Naver geocode response: ' + response.statusCode.toString());

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final addresses = data['addresses'] as List<dynamic>;
        if (addresses.isNotEmpty) {
          final first = addresses.first as Map<String, dynamic>;
          debugPrint('Address match: ' + first.toString());
          final double lat = double.parse(first['y']);
          final double lng = double.parse(first['x']);
          return NLatLng(lat, lng);
        } else {
          _showMessage('해당 주소를 찾을 수 없습니다.');
        }
      } else {
        _showMessage('네이버 API 연결 실패 (code: ${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Naver geocode error: ' + e.toString());
      _showMessage('네이버 API 요청 중 오류가 발생했습니다.');
    }
    return null;
  }

  Future<void> _onMapTap(NPoint point, NLatLng latLng) async {
    final controller = await _mapController.future;
    final marker = NMarker(
      id: 'spot_${_spots.length}',
      position: latLng,
      caption: NOverlayCaption(text: '장소 ${_spots.length + 1}'),
    );
    await controller.addOverlay(marker);
    setState(() {
      _spots.add(TravelSpot('장소 ${_spots.length + 1}', latLng));
    });
  }

  void _saveCourse() {
    final name = _nameController.text.trim();
    if (name.isEmpty || _spots.isEmpty) return;
    travelScenarios[name] = List<TravelSpot>.from(_spots);
    Navigator.pop(context, name);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _onSearch() async {
    final query = _searchController.text.trim();
    final location = await _searchLocation(query);
    if (location == null) return;
    _onMapTap(const NPoint(0, 0), location);
    final controller = await _mapController.future;
    await controller.updateCamera(
      NCameraUpdate.scrollAndZoomTo(target: location, zoom: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('새 코스 만들기')),
      body: Column(
        children: [
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
              onMapTapped: _onMapTap,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: '장소 검색',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _onSearch,
                    ),
                  ),
                  onSubmitted: (_) => _onSearch(),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: '코스 이름'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _saveCourse,
                  child: const Text('저장'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}