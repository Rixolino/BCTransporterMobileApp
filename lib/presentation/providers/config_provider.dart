import 'package:flutter/material.dart';
import '../../data/models/transport_config_model.dart';
import '../../data/services/api_service.dart';

class ConfigProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  TransportConfig? _config;
  bool _isLoading = true;
  String _selectedMode = 'train';

  TransportConfig? get config => _config;
  bool get isLoading => _isLoading;
  String get selectedMode => _selectedMode;

  ConfigProvider() {
    init();
  }

  void init() {
    _loadConfig();
  }

  void setMode(String mode) {
    if (_selectedMode != mode) {
      _selectedMode = mode;
      notifyListeners();
    }
  }

  Future<void> _loadConfig() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _config = await _apiService.fetchConfig();
    } catch (e) {
      print("Provider Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshConfig() async {
    await _loadConfig();
  }
}
