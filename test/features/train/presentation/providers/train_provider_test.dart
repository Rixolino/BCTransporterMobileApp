import 'package:flutter_test/flutter_test.dart';
import 'package:bc_transporter_mobile/features/train/presentation/providers/train_provider.dart';

void main() {
  group('TrainProvider Tests', () {
    late TrainProvider trainProvider;

    setUp(() {
      trainProvider = TrainProvider();
    });

    test('Initial state should be correct', () {
      expect(trainProvider.searchResults, isEmpty);
      expect(trainProvider.isLoading, false);
      expect(trainProvider.selectedStation, null);
    });

    // We can test clear functionality
    test('clearAll should reset state', () {
      trainProvider.clearAll();
      expect(trainProvider.stationSuggestions, isEmpty);
      expect(trainProvider.searchResults, isEmpty);
      expect(trainProvider.selectedStation, null);
    });
  });
}
