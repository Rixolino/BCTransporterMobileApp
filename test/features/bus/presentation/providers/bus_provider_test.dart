import 'package:flutter_test/flutter_test.dart';
import 'package:bc_transporter_mobile/features/bus/presentation/providers/bus_provider.dart';

void main() {
  group('BusProvider Tests', () {
    late BusProvider busProvider;

    setUp(() {
      busProvider = BusProvider();
    });

    test('Initial state should be correct', () {
      expect(busProvider.selectedCity, 'Roma');
      expect(busProvider.vehicles, isEmpty);
      expect(busProvider.isLoading, false);
    });

    // Note: Testing fetch methods requires dependency injection refactoring
    // to mock the repository. For now we test state properties.
    
    test('Should report correct loading state', () {
      // Since we can't easily trigger the real fetch in test environment (http calls),
      // we verify the initial state is not loading.
      expect(busProvider.isLoading, false);
    });
  });
}
