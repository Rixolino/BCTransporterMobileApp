import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/api_constants.dart';
import '../models/train_model.dart';

class TrainRepository {
  static const String baseUrl = "https://prod.cuzimmartin.dev/api";
  static const String falBaseUrl = "https://fal.ferrovieappulolucane.it"; 

  Future<List<TrainStation>> searchStations(String query, {String country = 'IT', String service = 'trainboardeu'}) async {
    // If service is Direct and country is IT, use local proxy/JSON logic
    if (service == 'direct' && country == 'IT') {
      final url = "${ApiConstants.baseUrl}/proxy/viaggiatreno?q=${Uri.encodeComponent(query)}";
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          // Viaggiatreno format from our proxy: [{ "nomestazione": "NAME", "codStazione": "ID" }]
          return data.map((e) => TrainStation(
            id: e['codStazione'].toString(), 
            name: e['nomestazione'].toString(),
            country: 'IT'
          )).toList();
        }
      } catch (e) {
        print("Direct IT search error: $e");
      }
    }

    // Default to Trainboard logic (even for direct other countries, it's our best source)
    String url;
    final String tbUrl = "https://prod.cuzimmartin.dev/api"; // Always use direct trainboard URL for TB service
    
    if (country == 'UK_LONDON') {
        url = "$tbUrl/gb/london/stations?query=${Uri.encodeComponent(query)}";
    } else if (country == 'FAL') {
        url = "$tbUrl/it/stations?query=${Uri.encodeComponent(query)}&limit=10";
    } else {
        url = "$tbUrl/$country/stations?query=${Uri.encodeComponent(query)}&limit=10";
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final dynamic jsonResponse = json.decode(response.body);
        final List<dynamic> data = (jsonResponse is Map && jsonResponse.containsKey('data')) 
            ? jsonResponse['data'] 
            : (jsonResponse is List ? jsonResponse : []);
            
        return data.map((e) {
          if (e is Map<String, dynamic>) e['country'] = country; 
          return TrainStation.fromJson(e);
        }).toList();
      }
      return [];
    } catch (e) {
      print("Error searching stations: $e");
      return [];
    }
  }

  Future<List<TrainDeparture>> fetchDepartures(String stationId, {String country = 'IT', String service = 'trainboardeu', bool isArrival = false}) async {
    if (country == 'FAL') return fetchFALDepartures(stationId);

    String url;
    final String tbUrl = "https://prod.cuzimmartin.dev/api";

    if (service == 'direct' && country == 'IT') {
       // Direct Italy uses our server proxy to RFI
       final endpoint = isArrival ? "rfi-arrivals" : "rfi-departures";
       url = "${ApiConstants.baseUrl}/api/$endpoint?placeId=$stationId";
    } else {
       final endpoint = isArrival ? "arrivals" : "departures";
       if (country == 'UK_LONDON') {
           url = "$tbUrl/gb/london/$endpoint?stationId=$stationId";
       } else {
           url = "$tbUrl/$country/$endpoint?stationId=$stationId";
       }
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final dynamic jsonResponse = json.decode(response.body);
        final List<dynamic> data = (jsonResponse is Map && jsonResponse.containsKey('data')) 
            ? jsonResponse['data'] 
            : (jsonResponse is List ? jsonResponse : []);
            
        return data.map((e) => TrainDeparture.fromJson(e, isDeparture: !isArrival)).toList();
      }
      return [];
    } catch (e) {
       print("Error fetching departures: $e");
       return [];
    }
  }

  Future<TrainDeparture?> fetchTrainDetails(String trainNumber, String stationId, {String country = 'IT', String service = 'trainboardeu'}) async {
    String url;
    final String tbUrl = "https://prod.cuzimmartin.dev/api";

    if (service == 'direct' && country == 'IT') {
      url = "${ApiConstants.baseUrl}/api/rfi-train/$trainNumber";
    } else {
      url = "$tbUrl/$country/details?trainNumber=$trainNumber&stationId=$stationId";
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        return TrainDeparture.fromJson(data);
      }
    } catch (e) {
      print("Error fetching train details: $e");
    }
    return null;
  }

  Future<TrainDeparture?> fetchTrip(String tripId, {String country = 'IT', String service = 'trainboardeu'}) async {
    final encodedTripId = Uri.encodeComponent(tripId);
    String url;
    final String tbUrl = "https://prod.cuzimmartin.dev/api";

    if (service == 'direct' && country == 'IT') {
      // For RFI direct, tripId might be different or we need separate structure
      url = "${ApiConstants.baseUrl}/api/rfi-train-progress?trainNumber=$tripId"; // Fallback placeholder
    } else {
      url = "$tbUrl/$country/trip?tripId=$encodedTripId";
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        final dynamic tripData = (data is Map && data.containsKey('data')) ? data['data'] : data;
        return TrainDeparture.fromJson(tripData);
      }
    } catch (e) {
      print("Error fetching trip details: $e");
    }
    return null;
  }

  Future<List<TrainDeparture>> fetchFALDepartures(String stationId) async {
    final url = "${ApiConstants.baseUrl}/api/fal/stop-updates?stationId=$stationId";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final dynamic jsonObject = json.decode(response.body);
        
        // L'API FAL restituisce una mappa dove le chiavi sono i nomi delle destinazioni
        // e i valori sono liste di fermate (trip + stopInfo).
        if (jsonObject is Map && jsonObject.containsKey('grouped')) {
           final Map<String, dynamic> grouped = jsonObject['grouped'];
           List<TrainDeparture> departures = [];
           
           grouped.forEach((dest, list) {
             if (list is List) {
               for (var item in list) {
                 final trip = item['trip'] ?? {};
                 final stop = item['stopInfo'] ?? {};
                 departures.add(TrainDeparture(
                   trainNumber: trip['LineCode'] ?? trip['id_documento']?.toString(),
                   category: trip['type'] == 'bus' ? 'FAL (BUS)' : 'FAL',
                   destination: dest,
                   scheduledTime: DateTime.tryParse(stop['expected_passing_date'] ?? ''),
                   estimatedTime: (stop['passing_date'] != null && stop['passing_date'] != 'null') ? DateTime.tryParse(stop['passing_date']) : null,
                   status: (stop['ritardo'] != null && stop['ritardo'] != 0) ? "${stop['ritardo']}'" : 'In orario',
                   delayMinutes: stop['ritardo'] is int ? stop['ritardo'] : 0,
                 ));
               }
             }
           });
           
           // Ordina per orario
           departures.sort((a, b) => (a.scheduledTime ?? DateTime.now()).compareTo(b.scheduledTime ?? DateTime.now()));
           return departures;
        }
        return [];
      }
      return [];
    } catch (e) {
      print("Error fetching FAL departures: $e");
      return [];
    }
  }

  Future<List<dynamic>> searchTrainByNumber(String query) async {
    final url = "https://data.cuzimmartin.dev/train-map?north=85&south=-5&east=91&west=-64&duration=300&results=1000&polylines=false";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> movements = data['movements'] ?? [];
        
        final searchTerm = query.toLowerCase();
        return movements.where((m) {
          final name = (m['line']?['name'] ?? '').toString().toLowerCase();
          final id = (m['line']?['id'] ?? '').toString().toLowerCase();
          return name.contains(searchTerm) || id.contains(searchTerm);
        }).toList();
      }
      return [];
    } catch (e) {
      print("Error searching train by number: $e");
      return [];
    }
  }
}

