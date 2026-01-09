class BusVehicle {
  final String id;
  final String line;
  final String? destination;
  final double latitude;
  final double longitude;
  final String? heading; 
  final String? speed;
  final String? provider; // Bari, Roma, ER, Flixbus
  
  BusVehicle({
    required this.id, 
    required this.line, 
    this.destination,
    required this.latitude, 
    required this.longitude,
    this.heading,
    this.speed,
    this.provider
  });

  factory BusVehicle.fromRomeJson(Map<String, dynamic> json) {
    final vehicle = json['vehicle'] ?? {};
    final position = vehicle['position'] ?? {};
    final trip = vehicle['trip'] ?? {};
    
    return BusVehicle(
      id: vehicle['id']?.toString() ?? json['id']?.toString() ?? '?',
      line: trip['routeId']?.toString() ?? '?',
      latitude: position['latitude']?.toDouble() ?? 0.0,
      longitude: position['longitude']?.toDouble() ?? 0.0,
      heading: position['bearing']?.toString(),
      speed: position['speed']?.toString(),
      provider: 'Roma',
    );
  }

  factory BusVehicle.fromBariJson(Map<String, dynamic> json) {
    // Handle new format: {"id": "3202", "vehicle": {...}}
    if (json['vehicle'] != null) {
      final v = json['vehicle'];
      final pos = v['position'] ?? {};
      final trip = v['trip'] ?? {};
      final vehicle = v['vehicle'] ?? {};
      
      return BusVehicle(
        id: vehicle['id']?.toString() ?? json['id']?.toString() ?? '?',
        line: trip['routeId']?.toString() ?? '?',
        latitude: pos['latitude']?.toDouble() ?? 0.0,
        longitude: pos['longitude']?.toDouble() ?? 0.0,
        heading: pos['bearing']?.toString(),
        speed: pos['speed']?.toString(),
        provider: 'Bari',
      );
    }
    
    // Fallback to old format: {"Vehicle": {...}}
    final v = json['Vehicle'] ?? {};
    final pos = v['Position'] ?? {};
    final trip = v['Trip'] ?? {};
    
    return BusVehicle(
      id: v['Id']?.toString() ?? json['id']?.toString() ?? '?',
      line: trip['RouteId']?.toString() ?? '?',
      latitude: pos['Latitude']?.toDouble() ?? 0.0,
      longitude: pos['Longitude']?.toDouble() ?? 0.0,
      heading: pos['Bearing']?.toString(),
      speed: pos['Speed']?.toString(),
      provider: 'Bari',
    );
  }

  factory BusVehicle.fromERJson(Map<String, dynamic> json) {
    // TperHellobus format
    return BusVehicle(
      id: json['CodiceBus']?.toString() ?? '?',
      line: json['NumeroLinea']?.toString() ?? '?',
      destination: json['DenominazioneFermata'],
      latitude: json['Latitude']?.toDouble() ?? 0.0,
      longitude: json['Longitude']?.toDouble() ?? 0.0,
      provider: 'Emilia-Romagna',
    );
  }

  factory BusVehicle.fromFlixbusJson(Map<String, dynamic> json) {
    return BusVehicle(
      id: json['id']?.toString() ?? '?',
      line: json['lineCode']?.toString() ?? 'FLX',
      destination: json['direction'],
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      provider: 'Flixbus',
    );
  }
}

class BusTripUpdate {
  final String stopId;
  final String stopName;
  final String expectedTime;
  final int? delay; // in minutes

  BusTripUpdate({
    required this.stopId,
    required this.stopName,
    required this.expectedTime,
    this.delay,
  });

  factory BusTripUpdate.fromJson(Map<String, dynamic> json) {
    return BusTripUpdate(
      stopId: json['stopId']?.toString() ?? '',
      stopName: json['stopName'] ?? '',
      expectedTime: json['time'] ?? '',
      delay: json['delay'],
    );
  }
}

class BariStop {
  final String stopId;
  final String stopName;
  final double latitude;
  final double longitude;

  BariStop({
    required this.stopId,
    required this.stopName,
    required this.latitude,
    required this.longitude,
  });

  factory BariStop.fromJson(Map<String, dynamic> json) {
    return BariStop(
      stopId: json['stop_id']?.toString() ?? '',
      stopName: json['stop_name'] ?? '',
      latitude: double.tryParse(json['stop_lat']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['stop_lon']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class BariRouteLeg {
  final String fromStop;
  final String toStop;
  final String routeId;
  final String lineCode;
  final String departureTime;
  final String arrivalTime;
  final int duration; // in minutes
  final String? vehicleType;
  final String? operator;

  BariRouteLeg({
    required this.fromStop,
    required this.toStop,
    required this.routeId,
    required this.lineCode,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    this.vehicleType,
    this.operator,
  });

  factory BariRouteLeg.fromJson(Map<String, dynamic> json) {
    return BariRouteLeg(
      fromStop: json['LocalitaSalita']?['Descrizione'] ?? 'Sconosciuto',
      toStop: json['LocalitaDiscesa']?['Descrizione'] ?? 'Sconosciuto',
      routeId: json['Linea']?['Codice'] ?? json['Corsa']?['CodiceInfoUtenza'] ?? 'N/A',
      lineCode: json['Linea']?['Codice'] ?? 'N/A',
      departureTime: json['OraPartenza'] ?? '',
      arrivalTime: json['OraArrivo'] ?? '',
      duration: json['Durata'] ?? 0,
      vehicleType: json['TipoMezzo'],
      operator: json['CodiceAzienda'] ?? json['Linea']?['CodiceAzienda'] ?? json['Corsa']?['CodiceAzienda'],
    );
  }
}

class BariRouteSolution {
  final String id;
  final List<BariRouteLeg> legs;
  final String departureTime;
  final String arrivalTime;
  final int totalDuration; // in minutes
  final int transfers;
  final String? price;
  final String? currency;

  BariRouteSolution({
    required this.id,
    required this.legs,
    required this.departureTime,
    required this.arrivalTime,
    required this.totalDuration,
    required this.transfers,
    this.price,
    this.currency,
  });

  factory BariRouteSolution.fromJson(Map<String, dynamic> json) {
    final tratte = json['Tratte'] ?? [];
    final List<dynamic> tratteList = tratte is List ? tratte : [];
    final legs = tratteList.map((t) => BariRouteLeg.fromJson(t)).toList();

    return BariRouteSolution(
      id: json['IdSoluzione']?.toString() ?? '',
      legs: legs,
      departureTime: json['OraPartenza'] ?? '',
      arrivalTime: json['OraArrivo'] ?? '',
      totalDuration: json['DurataTotale'] ?? 0,
      transfers: json['NumeroCambi'] ?? 0,
      price: json['Prezzo']?['Valore']?.toString(),
      currency: json['Prezzo']?['Valuta'],
    );
  }
}
