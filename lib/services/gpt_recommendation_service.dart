import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_naver_map/flutter_naver_map.dart';

import '../models/travel_spot.dart';
import '../utils/geo.dart';

class GptRecommendationResult {
  final List<TravelSpot> spots;
  final bool usedFallback;

  const GptRecommendationResult({required this.spots, required this.usedFallback});
}

class GptRecommendationService {
  GptRecommendationService({http.Client? client, String? apiKey})
      : _client = client ?? http.Client(),
        _apiKey = (apiKey ?? dotenv.env['OPENAI_API_KEY'])?.trim();

  final http.Client _client;
  final String? _apiKey;

  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;

  Future<GptRecommendationResult> recommendTopSpots({
    required List<TravelSpot> spots,
    required Set<CatTag> tags,
    required NLatLng start,
    required DistPref distPref,
    int limit = 3,
  }) async {
    final filteredByTags = spots
        .where((s) => tags.isEmpty || s.cat.any(tags.contains))
        .toList();
    bool _withinDistance(TravelSpot spot) {
      final distance = haversineMeters(start, spot.nlatlng);
      return distPref == DistPref.near ? distance <= 1500 : distance > 1500;
    }

    final filtered = filteredByTags.where(_withinDistance).toList();

    if (filtered.isEmpty) {
      return const GptRecommendationResult(spots: [], usedFallback: false);
    }

    if (!isConfigured) {
      filtered.sort((a, b) => a.nameKo.compareTo(b.nameKo));
      return GptRecommendationResult(
        spots: filtered.take(limit).toList(),
        usedFallback: true,
      );
    }

    final payload = filtered.map((spot) {
      return {
        'id': spot.id,
        'name': spot.nameKo,
        'city': spot.city,
        'categories': spot.cat.map((c) => c.name).toList(),
      };
    }).toList();

    final userPrompt = '''아래는 대전 여행지 목록이야. 선택된 태그와 가장 잘 맞고, 유명세가 높은 장소 3개를 인기도 순으로 추천해줘.
데이터는 JSON 배열로 되어 있고, 반드시 그 안에 있는 장소만 선택해야 해.

선택된 태그: ${tags.map((e) => e.name).join(', ')}
여행지 데이터: ${jsonEncode(payload)}

결과는 recommendations라는 키를 가진 JSON 객체로만 응답해줘. recommendations 값은 다음 형태의 배열이야:
{
  "recommendations": [
    {
      "id": "여행지 ID",
      "name": "여행지 이름",
      "reason": "짧은 추천 이유"
    }
  ]
}
최대 ${limit}개까지만 응답하고, 다른 텍스트는 쓰지 마.''';

    final body = jsonEncode({
      'model': 'gpt-4o-mini',
      'temperature': 0.2,
      'messages': [
        {
          'role': 'system',
          'content': 'You are a knowledgeable travel curator for Daejeon, South Korea. Always reply with valid JSON that conforms to the provided schema.',
        },
        {
          'role': 'user',
          'content': userPrompt,
        },
      ],
      'response_format': {
        'type': 'json_schema',
        'json_schema': {
          'name': 'travel_recommendations',
          'schema': {
            'type': 'object',
            'properties': {
              'recommendations': {
                'type': 'array',
                'items': {
                  'type': 'object',
                  'properties': {
                    'id': {'type': 'string'},
                    'name': {'type': 'string'},
                    'reason': {'type': 'string'},
                  },
                  'required': ['id'],
                },
              },
            },
            'required': ['recommendations'],
          },
        },
      },
    });

    try {
      final response = await _client.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: body,
      );

      if (response.statusCode >= 400) {
        debugPrint('GPT 응답 오류 ${response.statusCode}: ${response.body}');
        throw Exception('GPT 호출 실패(${response.statusCode})');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = _extractContentText(data);
      if (content == null) {
        throw Exception('GPT 응답에 콘텐츠가 없습니다.');
      }

      final parsed = _tryParseJson(content);
      final entries = parsed is Map<String, dynamic>
          ? parsed['recommendations']
          : parsed;
      if (entries is! List) {
        throw Exception('GPT 응답을 JSON으로 변환할 수 없습니다.');
      }

      final result = <TravelSpot>[];
      for (final item in entries) {
        if (item is! Map) continue;
        final id = item['id'];
        if (id is! String) continue;
        final match = filtered.firstWhere(
              (s) => s.id == id,
          orElse: () => filtered.first,
        );
        if (!result.any((s) => s.id == match.id)) {
          result.add(match);
        }
        if (result.length >= limit) break;
      }

      if (result.isEmpty) {
        filtered.sort((a, b) => a.nameKo.compareTo(b.nameKo));
        return GptRecommendationResult(
          spots: filtered.take(limit).toList(),
          usedFallback: true,
        );
      }

      return GptRecommendationResult(spots: result, usedFallback: false);
    } catch (e) {
      debugPrint('GPT 추천 실패: $e');
      filtered.sort((a, b) => a.nameKo.compareTo(b.nameKo));
      return GptRecommendationResult(
        spots: filtered.take(limit).toList(),
        usedFallback: true,
      );
    }
  }

  String? _extractContentText(Map<String, dynamic> payload) {
    final buffer = StringBuffer();

    final choices = payload['choices'];
    if (choices is List) {
      for (final choice in choices) {
        if (choice is! Map) continue;
        final message = choice['message'];
        if (message is Map) {
          final content = message['content'];
          if (content is String && content.isNotEmpty) {
            buffer.write(content);
          } else if (content is List) {
            for (final part in content) {
              if (part is Map) {
                final text = part['text'];
                if (text is String && text.isNotEmpty) {
                  buffer.write(text);
                }
              } else if (part is String && part.isNotEmpty) {
                buffer.write(part);
              }
            }
          }
        }
      }
      if (buffer.isNotEmpty) {
        return buffer.toString();
      }
    }

    final output = payload['output'];
    if (output is List) {
      for (final chunk in output) {
        if (chunk is! Map) continue;
        final content = chunk['content'];
        if (content is! List) continue;
        for (final part in content) {
          if (part is! Map) continue;
          final type = part['type'];
          final text = part['text'];
          if ((type == 'output_text' || type == 'text') && text is String) {
            buffer.write(text);
          }
        }
      }
      if (buffer.isNotEmpty) {
        return buffer.toString();
      }
    }

    final content = payload['content'];
    if (content is String && content.isNotEmpty) {
      return content;
    }

    return null;
  }

  dynamic _tryParseJson(String content) {
    try {
      return jsonDecode(content);
    } catch (_) {
      final arrayStart = content.indexOf('[');
      final arrayEnd = content.lastIndexOf(']');
      if (arrayStart != -1 && arrayEnd != -1 && arrayEnd > arrayStart) {
        final slice = content.substring(arrayStart, arrayEnd + 1);
        try {
          return jsonDecode(slice);
        } catch (_) {}
      }

      final objectStart = content.indexOf('{');
      final objectEnd = content.lastIndexOf('}');
      if (objectStart != -1 && objectEnd != -1 && objectEnd > objectStart) {
        final slice = content.substring(objectStart, objectEnd + 1);
        try {
          return jsonDecode(slice);
        } catch (_) {}
      }
    }
    return null;
  }
}