import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/travel_spot.dart';

const daejeonCenterLat = 36.3504;
const daejeonCenterLng = 127.3845;

class DaejeonSpotRepository {
  DaejeonSpotRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<TravelSpot>> fetch({String city = 'Daejeon'}) async {
    final query = await _firestore
        .collection('travel_spots')
        .where('city', isEqualTo: city)
        .get();

    final spots = <TravelSpot>[];
    for (final doc in query.docs) {
      try {
        spots.add(TravelSpot.fromFirestore(doc));
      } catch (e) {
        debugPrint('여행지 변환 실패(${doc.id}): $e');
      }
    }
    return spots;
  }
}
