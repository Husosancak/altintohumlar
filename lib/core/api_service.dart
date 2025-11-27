import 'package:dio/dio.dart';
import '../models/haber.dart';

class ApiService {
  final Dio _dio = Dio();
  final String _baseUrl = 'https://apiservice.istib.org.tr/api/altintohumlar';

  Future<List<Haber>> fetchHaberler() async {
    try {
      final response = await _dio.get(_baseUrl);
      final data = response.data as List;
      return data.map((item) => Haber.fromJson(item)).toList();
    } catch (e) {
      print('API Hatası: \$e');
      return [];
    }
  }
}
