import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/api_constants.dart';
import '../models/transport_config_model.dart';

class ApiService {
  Future<TransportConfig> fetchConfig() async {
    try {
      // Aggiungi timeout di 5 secondi
      final response = await http
          .get(Uri.parse(ApiConstants.configEndpoint))
          .timeout(const Duration(seconds: 5), onTimeout: () {
        throw TimeoutException('Config endpoint timeout');
      });
      
      if (response.statusCode == 200) {
        return TransportConfig.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load configuration: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching config: Exception: $e");
      // Fallback config in case of error - sempre ritorna qualcosa di valido
      return _getDefaultConfig();
    }
  }

  TransportConfig _getDefaultConfig() {
    return TransportConfig(
      transports: [
        TransportSource(
          id: 'default_train',
          name: 'Trainboard',
          type: 'train',
          scope: 'international',
          icon: 'train',
          endpoints: {'stations': ApiConstants.defaultTrainEndpoint},
        ),
        TransportSource(
          id: 'default_bus',
          name: 'AMTAB Bari',
          type: 'bus',
          scope: 'urban',
          icon: 'bus',
          endpoints: {'realtime': ApiConstants.defaultAmtabEndpoint},
        ),
        TransportSource(
          id: 'default_plane',
          name: 'FlightRadar',
          type: 'plane',
          scope: 'global',
          icon: 'plane',
          endpoints: {'realtime': ApiConstants.defaultFlightRadarEndpoint},
        ),
      ],
      systemEndpoints: {},
    );
  }

  // Generic fetch for other endpoints
  Future<dynamic> fetchData(String url) async {
    final response = await http.get(Uri.parse(url)).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('Request timeout'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data from $url');
    }
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}

