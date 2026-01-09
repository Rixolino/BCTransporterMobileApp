import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Impostazioni',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildSectionTitle('Aggiornamento Automatico'),
              const SizedBox(height: 16),
              
              _buildRefreshSlider(
                context, 
                'Treni', 
                Icons.train, 
                settings.trainRefreshSeconds,
                (val) => settings.setTrainRefreshSeconds(val.toInt())
              ).animate().fadeIn(delay: 100.ms).slideX(),

              const SizedBox(height: 24),
              
              _buildRefreshSlider(
                context, 
                'Autobus', 
                Icons.directions_bus, 
                settings.busRefreshSeconds,
                (val) => settings.setBusRefreshSeconds(val.toInt())
              ).animate().fadeIn(delay: 200.ms).slideX(),

              const SizedBox(height: 24),
              
              _buildRefreshSlider(
                context, 
                'Aerei', 
                Icons.flight, 
                settings.planeRefreshSeconds,
                (val) => settings.setPlaneRefreshSeconds(val.toInt())
              ).animate().fadeIn(delay: 300.ms).slideX(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: Colors.white.withOpacity(0.5),
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildRefreshSlider(
    BuildContext context, 
    String label, 
    IconData icon, 
    int currentValue, 
    Function(double) onChanged
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: currentValue > 0 ? Colors.blueAccent.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  currentValue > 0 ? '${currentValue}s' : 'Off',
                  style: TextStyle(
                    color: currentValue > 0 ? Colors.blueAccent : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.blueAccent,
              inactiveTrackColor: Colors.white.withOpacity(0.1),
              thumbColor: Colors.white,
              overlayColor: Colors.blueAccent.withOpacity(0.2),
              trackHeight: 4.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
            ),
            child: Slider(
              value: currentValue.toDouble(),
              min: 0,
              max: 300,
              divisions: 20, // 0, 15, 30... 300
              label: currentValue > 0 ? '$currentValue sec' : 'Disabilitato',
              onChanged: onChanged,
            ),
          ),
          Padding(
             padding: const EdgeInsets.symmetric(horizontal: 4),
             child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Text('Off', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10)),
                 Text('5m', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10)),
               ],
             ),
          )
        ],
      ),
    );
  }
}
