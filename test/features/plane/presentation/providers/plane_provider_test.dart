import 'package:flutter_test/flutter_test.dart';
import 'package:bc_transporter_mobile/features/plane/presentation/providers/plane_provider.dart';

void main() {
  group('PlaneProvider Tests', () {
    late PlaneProvider planeProvider;

    setUp(() {
      planeProvider = PlaneProvider();
    });

    test('Initial state should be correct', () {
      expect(planeProvider.flights, isEmpty);
      expect(planeProvider.isLoading, false);
      expect(planeProvider.selectedFlight, null);
      expect(planeProvider.isArrivalMode, false);
    });

    test('Should toggle arrival mode', () {
      expect(planeProvider.isArrivalMode, false);
      planeProvider.setArrivalMode(true);
      expect(planeProvider.isArrivalMode, true);
    });
    
    test('Should clear selection', () {
       planeProvider.clearAirportSelection();
       expect(planeProvider.selectedAirport, null);
       expect(planeProvider.scheduledFlights, isEmpty);
    });
  });
}
