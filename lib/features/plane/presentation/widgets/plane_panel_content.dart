import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/plane_provider.dart';
import '../../../../presentation/providers/map_state_provider.dart';

class PlanePanelContent extends StatefulWidget {
  final VoidCallback onRefresh;

  const PlanePanelContent({super.key, required this.onRefresh});

  @override
  State<PlanePanelContent> createState() => _PlanePanelContentState();
}

class _PlanePanelContentState extends State<PlanePanelContent> {
  final TextEditingController _airportController = TextEditingController();
  bool _showSkyscanner = false;
  Timer? _progressTimer;

  @override
  void dispose() {
    _progressTimer?.cancel();
    _airportController.dispose();
    super.dispose();
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final planeProvider = Provider.of<PlaneProvider>(context);
    final mapState = Provider.of<MapStateProvider>(context, listen: false);

    if (planeProvider.selectedFlight != null && _progressTimer == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startProgressTimer());
    } else if (planeProvider.selectedFlight == null && _progressTimer != null) {
      _progressTimer?.cancel();
      _progressTimer = null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _showSkyscanner ? "Ricerca Aeroporti" : "Traffico Aereo",
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Switch(
              value: _showSkyscanner,
              onChanged: (val) => setState(() => _showSkyscanner = val),
              activeColor: Colors.blueAccent,
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (!_showSkyscanner) ...[
          const Text(
            "Monitora i voli in tempo reale nell'area visibile.",
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: planeProvider.isLoading ? null : widget.onRefresh,
            icon: planeProvider.isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.radar),
            label: const Text("Scansiona Area"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
            ),
          ),
        ] else ...[
          _buildAirportSearch(planeProvider),
        ],
        const SizedBox(height: 20),
        Expanded(
          child: planeProvider.selectedFlight != null 
            ? _buildFlightDetail(planeProvider)
            : (_showSkyscanner ? _buildSkyscannerResults(planeProvider, mapState) : _buildRealtimeList(planeProvider, mapState)),
        ),
      ],
    );
  }

  Widget _buildFlightDetail(PlaneProvider planeProvider) {
    final f = planeProvider.selectedFlight!;
    final dep = f.estimatedDeparture ?? f.scheduledDeparture;
    final arr = f.estimatedArrival ?? f.scheduledArrival;
    
    double progress = 0.0;
    if (dep != null && arr != null) {
      final now = DateTime.now();
      if (now.isAfter(arr)) {
        progress = 1.0;
      } else if (now.isAfter(dep)) {
        final total = arr.difference(dep).inSeconds;
        final elapsed = now.difference(dep).inSeconds;
        progress = (elapsed / total).clamp(0.0, 1.0);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => planeProvider.clearFlightSelection(),
          ),
          Center(
            child: Column(
              children: [
                Text(
                  f.flightNumber,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  f.airline,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("ORIGINE", style: TextStyle(color: Colors.white38, fontSize: 10)),
                          Text(f.origin, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(_formatTime(f.scheduledDeparture), style: const TextStyle(color: Colors.white70)),
                          if (f.estimatedDeparture != null && f.estimatedDeparture != f.scheduledDeparture)
                            Text(
                              "Est: ${_formatTime(f.estimatedDeparture)}", 
                              style: const TextStyle(color: Colors.orangeAccent, fontSize: 12)
                            ),
                        ],
                      ),
                    ),
                    const Icon(Icons.flight_takeoff, color: Colors.blueAccent),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text("DESTINAZIONE", style: TextStyle(color: Colors.white38, fontSize: 10)),
                          Text(f.destination, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(_formatTime(f.scheduledArrival), style: const TextStyle(color: Colors.white70)),
                          if (f.estimatedArrival != null && f.estimatedArrival != f.scheduledArrival)
                            Text(
                              "Est: ${_formatTime(f.estimatedArrival)}", 
                              style: const TextStyle(color: Colors.orangeAccent, fontSize: 12)
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                // Progress Bar
                SizedBox(
                  height: 40,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background line
                      Container(
                        height: 4,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Progress line
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Colors.blueAccent, Colors.cyanAccent]),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      // Airplane icon
                      Align(
                        alignment: Alignment(progress * 2 - 1, 0),
                        child: const RotatedBox(
                          quarterTurns: 1, // Rotates 90 degrees clockwise (Up -> Right)
                          child: Icon(Icons.airplanemode_active, color: Colors.white, size: 24),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "${(progress * 100).toInt()}% del viaggio completato",
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow("Status", f.statusLocalized ?? f.status),
                      _buildDetailRow("Callsign", f.callsign),
                      _buildDetailRow("Tipo", f.type == "arrival" ? "Arrivo" : "Partenza"),
                      if (f.terminal != null) _buildDetailRow("Terminal", f.terminal!),
                      if (f.gate != null) _buildDetailRow("Gate", f.gate!),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAirportSearch(PlaneProvider planeProvider) {
    return Column(
      children: [
        TextField(
          controller: _airportController,
          decoration: InputDecoration(
            hintText: "Cerca aeroporto (es. Roma, LHR)...",
            hintStyle: const TextStyle(color: Colors.white54),
            prefixIcon: const Icon(Icons.flight_takeoff, color: Colors.white54),
            suffixIcon: planeProvider.selectedAirport != null 
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white54),
                  onPressed: () {
                    _airportController.clear();
                    planeProvider.clearAirportSelection();
                  },
                )
              : null,
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: (val) {
            if (val.length > 2) planeProvider.searchAirports(val);
          },
        ),
        if (planeProvider.selectedAirport != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text("Partenze"),
                  selected: !planeProvider.isArrivalMode,
                  onSelected: (val) => planeProvider.setArrivalMode(false),
                  backgroundColor: Colors.white10,
                  selectedColor: Colors.blueAccent,
                  labelStyle: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text("Arrivi"),
                  selected: planeProvider.isArrivalMode,
                  onSelected: (val) => planeProvider.setArrivalMode(true),
                  backgroundColor: Colors.white10,
                  selectedColor: Colors.blueAccent,
                  labelStyle: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSkyscannerResults(PlaneProvider planeProvider, MapStateProvider mapState) {
    if (planeProvider.isLoadingAirports) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show suggestions if we are typing and haven't selected an airport yet
    if (planeProvider.airportSuggestions.isNotEmpty) {
      return ListView.builder(
        itemCount: planeProvider.airportSuggestions.length,
        itemBuilder: (context, index) {
          final a = planeProvider.airportSuggestions[index];
          return ListTile(
            leading: const Icon(Icons.location_city, color: Colors.blueAccent),
            title: Text(a.name, style: const TextStyle(color: Colors.white)),
            subtitle: Text("${a.iata} - ${a.country}", style: const TextStyle(color: Colors.white70)),
            onTap: () {
               planeProvider.selectAirport(a);
               _airportController.text = a.name;
               // Focus map on airport (MapState internally handles flyTo)
               mapState.flyTo(a.lat, a.lng, zoom: 12);
            },
          );
        },
      );
    }

    if (planeProvider.selectedAirport != null) {
      if (planeProvider.scheduledFlights.isEmpty) {
        return const Center(child: Text("Nessun volo trovato", style: TextStyle(color: Colors.white54)));
      }
      return ListView.builder(
        itemCount: planeProvider.scheduledFlights.length,
        itemBuilder: (context, index) {
          final f = planeProvider.scheduledFlights[index];
          final isDeparture = !planeProvider.isArrivalMode;
          return ListTile(
            leading: const Icon(Icons.event, color: Colors.orangeAccent),
            title: Text(
              f.airline.isEmpty ? f.callsign : f.airline,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
            ),
            subtitle: Text(
              "${isDeparture ? "Per: ${f.destination}" : "Da: ${f.origin}"}\n${f.flightNumber} | ${f.statusLocalized ?? 'Programmato'}", 
              style: const TextStyle(color: Colors.white70)
            ),
            isThreeLine: true,
            trailing: Text(
              _formatTime(isDeparture ? f.scheduledDeparture : f.scheduledArrival),
              style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
            ),
            onTap: () => planeProvider.selectFlight(f),
          );
        },
      );
    }

    return const Center(
      child: Text(
        "Cerca un aeroporto per vedere il tabellone orari", 
        style: TextStyle(color: Colors.white30)
      )
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return "--:--";
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  Widget _buildRealtimeList(PlaneProvider planeProvider, MapStateProvider mapState) {
    return ListView.builder(
      itemCount: planeProvider.flights.length,
      itemBuilder: (context, index) {
        final f = planeProvider.flights[index];
        return ListTile(
          leading: const Icon(Icons.flight, color: Colors.yellowAccent),
          title: Text(f.callsign, style: const TextStyle(color: Colors.white)),
          subtitle: Text("${f.origin} -> ${f.destination}", style: const TextStyle(color: Colors.white70)),
          trailing: Text("${(f.altitude ?? 0).toInt()} ft", style: const TextStyle(color: Colors.white54, fontSize: 12)),
          onTap: () {
            if (f.latitude != null && f.longitude != null) {
              mapState.flyTo(f.latitude!, f.longitude!, zoom: 10);
            }
          },
        );
      },
    );
  }
}
