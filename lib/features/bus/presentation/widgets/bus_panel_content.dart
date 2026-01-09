import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bus_provider.dart';
import '../../../../presentation/providers/map_state_provider.dart';
import '../../data/models/bus_model.dart';

class BusPanelContent extends StatefulWidget {
  const BusPanelContent({super.key});

  @override
  State<BusPanelContent> createState() => _BusPanelContentState();
}

class _BusPanelContentState extends State<BusPanelContent> {
  final TextEditingController _searchController = TextEditingController();
  bool _expandedCitySelector = true;
  bool _expandedOptions = true;
  bool _expandedResults = true;

  @override
  Widget build(BuildContext context) {
    final busProvider = Provider.of<BusProvider>(context);
    final mapState = Provider.of<MapStateProvider>(context, listen: false);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // City Selector - Expandable
          _buildExpandableSection(
            title: "Seleziona Città / Operatore",
            expanded: _expandedCitySelector,
            onExpanded: (value) => setState(() => _expandedCitySelector = value),
            child: Wrap(
              spacing: 8,
              children: [
                _buildCityChip(context, "Roma", busProvider),
                _buildCityChip(context, "Bari", busProvider),
                _buildCityChip(context, "Emilia-Romagna", busProvider),
                _buildCityChip(context, "Flixbus", busProvider),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Options Section - Expandable
          _buildExpandableSection(
            title: busProvider.selectedCity == "Bari" ? "Pianifica Viaggio" : "Opzioni",
            expanded: _expandedOptions,
            onExpanded: (value) => setState(() => _expandedOptions = value),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (busProvider.selectedCity == "Flixbus") _buildFlixbusSearch(busProvider),
                if (busProvider.selectedCity == "Bari") _buildBariRouting(busProvider),
                if (busProvider.selectedCity != "Flixbus") ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: busProvider.isLoading ? null : () => busProvider.fetchVehicles(),
                      icon: busProvider.isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.refresh),
                      label: const Text("Aggiorna Posizioni"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Results Section - Expandable
          _buildExpandableSection(
            title: "Risultati",
            expanded: _expandedResults,
            onExpanded: (value) => setState(() => _expandedResults = value),
            child: SizedBox(
              height: 300,
              child: _buildResultsList(busProvider, mapState),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required bool expanded,
    required ValueChanged<bool> onExpanded,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        initiallyExpanded: expanded,
        onExpansionChanged: onExpanded,
        collapsedIconColor: Colors.white70,
        iconColor: Colors.white70,
        backgroundColor: Colors.white.withValues(alpha: 0.02),
        collapsedBackgroundColor: Colors.transparent,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildFlixbusSearch(BusProvider busProvider) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: "Cerca città Flixbus...",
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: const Icon(Icons.search, color: Colors.white54),
        suffixIcon: IconButton(
          icon: const Icon(Icons.send, color: Colors.greenAccent),
          onPressed: () => busProvider.searchFlixbus(_searchController.text),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      style: const TextStyle(color: Colors.white),
      onSubmitted: (val) => busProvider.searchFlixbus(val),
    );
  }

  Widget _buildBariRouting(BusProvider busProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Pianifica Viaggio",
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _buildStopSelector("Da", busProvider.selectedFromStop, (BariStop? stop) => busProvider.selectFromStop(stop), busProvider),
        const SizedBox(height: 8),
        _buildStopSelector("A", busProvider.selectedToStop, (BariStop? stop) => busProvider.selectToStop(stop), busProvider),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: (busProvider.selectedFromStop != null && busProvider.selectedToStop != null && !busProvider.isLoadingSolutions)
              ? () => busProvider.fetchBariSolutions()
              : null,
          icon: busProvider.isLoadingSolutions
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.search),
          label: const Text("Cerca Soluzioni"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.greenAccent,
            foregroundColor: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildStopSelector(String label, BariStop? selectedStop, Function(BariStop?) onSelect, BusProvider busProvider) {
    return InkWell(
      onTap: () => _showStopSelectionDialog(context, label, busProvider, onSelect),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(selectedStop != null ? Icons.location_on : Icons.location_searching, color: Colors.white70),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                selectedStop?.stopName ?? "Seleziona fermata $label",
                style: TextStyle(color: selectedStop != null ? Colors.white : Colors.white54),
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  void _showStopSelectionDialog(BuildContext context, String label, BusProvider busProvider, Function(BariStop?) onSelect) {
    if (busProvider.bariStops.isEmpty && !busProvider.isLoadingStops) {
      busProvider.fetchBariStops();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text("Seleziona fermata $label", style: const TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: busProvider.isLoadingStops
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: busProvider.bariStops.length,
                  itemBuilder: (context, index) {
                    final stop = busProvider.bariStops[index];
                    return ListTile(
                      title: Text(stop.stopName, style: const TextStyle(color: Colors.white)),
                      onTap: () {
                        onSelect(stop);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Annulla", style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(BusProvider busProvider, MapStateProvider mapState) {
    if (busProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show Bari solutions if available
    if (busProvider.selectedCity == "Bari" && busProvider.bariSolutions.isNotEmpty) {
      return _buildBariSolutionsList(busProvider, mapState);
    }

    if (busProvider.selectedCity == "Flixbus") {
      return ListView.builder(
        itemCount: busProvider.flixbusStations.length,
        itemBuilder: (context, index) {
          final station = busProvider.flixbusStations[index];
          return ListTile(
            leading: const Icon(Icons.directions_bus, color: Colors.greenAccent),
            title: Text(station['name'] ?? '', style: const TextStyle(color: Colors.white)),
            subtitle: Text(station['country_code'] ?? '', style: const TextStyle(color: Colors.white70)),
            onTap: () {
              final dynamic coords = station['coords'];
              if (coords != null && coords['lat'] != null && coords['lng'] != null) {
                mapState.flyTo(
                  (coords['lat'] as num).toDouble(), 
                  (coords['lng'] as num).toDouble(), 
                  zoom: 14
                );
              }
            },
          );
        },
      );
    }

    if (busProvider.vehicles.isEmpty) {
      return Center(
        child: Text(
          "Nessun autobus trovato per ${busProvider.selectedCity}",
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      itemCount: busProvider.vehicles.length,
      itemBuilder: (context, index) {
        final v = busProvider.vehicles[index];
        return ListTile(
          leading: Icon(Icons.directions_bus, color: _getCityColor(busProvider.selectedCity)),
          title: Text("Linea ${v.line}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text(v.destination ?? 'Destinazione non disponibile', style: const TextStyle(color: Colors.white70)),
          trailing: const Icon(Icons.map, color: Colors.white30),
          onTap: () {
            if (v.latitude != 0) {
              mapState.flyTo(v.latitude, v.longitude, zoom: 15);
            }
          },
        );
      },
    );
  }

  Widget _buildBariSolutionsList(BusProvider busProvider, MapStateProvider mapState) {
    return ListView.builder(
      itemCount: busProvider.bariSolutions.length,
      itemBuilder: (context, index) {
        final solution = busProvider.bariSolutions[index];
        return Card(
          color: Colors.white.withValues(alpha: 0.1),
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ExpansionTile(
            title: Text(
              "${solution.departureTime} - ${solution.arrivalTime}",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "${solution.totalDuration} min, ${solution.transfers} cambi",
              style: const TextStyle(color: Colors.white70),
            ),
            children: solution.legs.map((leg) => ListTile(
              leading: const Icon(Icons.directions_bus, color: Colors.blueAccent),
              title: Text("${leg.fromStop} → ${leg.toStop}", style: const TextStyle(color: Colors.white)),
              subtitle: Text("Linea ${leg.lineCode} - ${leg.duration} min", style: const TextStyle(color: Colors.white70)),
              onTap: () {
                // Could show route on map
              },
            )).toList(),
          ),
        );
      },
    );
  }

  Color _getCityColor(String city) {
    switch (city) {
      case "Roma": return Colors.redAccent;
      case "Bari": return Colors.blueAccent;
      case "Emilia-Romagna": return Colors.orangeAccent;
      default: return Colors.blueAccent;
    }
  }

  Widget _buildCityChip(BuildContext context, String city, BusProvider provider) {
    final isSelected = provider.selectedCity == city;
    return FilterChip(
      label: Text(city),
      selected: isSelected,
      onSelected: (_) => provider.selectCity(city),
      backgroundColor: Colors.white.withValues(alpha: 0.1),
      selectedColor: Colors.blueAccent.withValues(alpha: 0.5),
      labelStyle: const TextStyle(color: Colors.white),
      checkmarkColor: Colors.white,
    );
  }
}
