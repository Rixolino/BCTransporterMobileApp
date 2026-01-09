import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/train_provider.dart';
import '../../../../presentation/providers/map_state_provider.dart';
import 'train_details_sheet.dart';
import 'package:intl/intl.dart';

class TrainPanelContent extends StatefulWidget {
  const TrainPanelContent({super.key});

  @override
  State<TrainPanelContent> createState() => _TrainPanelContentState();
}

class _TrainPanelContentState extends State<TrainPanelContent> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCountry = 'IT';

  // Mappa dei fusi orari (Offset rispetto a UTC)
  final Map<String, int> countryTimezoneOffsets = {
    'IT': 1, 'FR': 1, 'DE': 1, 'AT': 1, 'CH': 1, 'ES': 1,
    'GB': 0, 'NL': 1, 'BE': 1, 'LU': 1, 'CZ': 1, 'PL': 1,
    'HU': 1, 'RO': 2, 'GR': 2, 'SE': 1, 'NO': 1, 'DK': 1,
  };

  // Helper per formattare l'orario nel fuso della stazione
  String _formatStationTime(DateTime? date, String countryCode) {
    if (date == null) return '--:--';
    final int offset = countryTimezoneOffsets[countryCode] ?? 1;
    final stationTime = date.toUtc().add(Duration(hours: offset));
    return DateFormat('HH:mm').format(stationTime);
  }

  final List<Map<String, String>> _countries = [
    {'code': 'IT', 'name': 'Italia'},
    {'code': 'DE', 'name': 'Germania'},
    {'code': 'CH', 'name': 'Svizzera'},
    {'code': 'FR', 'name': 'Francia'},
    {'code': 'FAL', 'name': 'Puglia (FAL)'},
    {'code': 'EU', 'name': 'Continentale (Realtime)'},
    {'code': 'UK_LONDON', 'name': 'Regno Unito'},
    {'code': 'AT', 'name': 'Austria'},
  ];

  @override
  Widget build(BuildContext context) {
    final trainProvider = Provider.of<TrainProvider>(context);

    // Dynamic country list based on service
    List<Map<String, String>> displayedCountries = _countries;
    if (trainProvider.selectedService == 'direct') {
      displayedCountries = _countries.where((c) => ['IT', 'FAL', 'EU'].contains(c['code'])).toList();
      if (!['IT', 'FAL', 'EU'].contains(_selectedCountry)) {
         _selectedCountry = 'IT';
      }
    }

    final station = trainProvider.selectedStation;

    // View 1: Results (Timetable)
    if (station != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  trainProvider.clearSelection();
                },
              ),
              Expanded(
                child: Text(
                   "${station.name} (${trainProvider.isArrivalMode ? 'Arrivi' : 'Partenze'})",
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white24),
          Expanded(
            child: trainProvider.isLoadingDepartures
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: trainProvider.departures.length,
                    itemBuilder: (context, index) {
                      final dep = trainProvider.departures[index];
                      final isArrival = trainProvider.isArrivalMode;
                      
                      return Card(
                        color: Colors.white.withOpacity(0.05),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                             final String? targetId = dep.tripId;
                             final String? targetNum = dep.trainNumber;
                             
                             // Fetch details if empty
                             if (dep.stops == null) {
                                trainProvider.expandTrainDetails(index);
                             }
                             
                             showModalBottomSheet(
                               context: context, 
                               isScrollControlled: true,
                               backgroundColor: Colors.transparent,
                               barrierColor: Colors.black54,
                               builder: (ctx) => Consumer<TrainProvider>(
                                 builder: (context, provider, child) {
                                   // Trova il treno aggiornato cercando per ID o numero treno
                                   // Invece di usare l'indice che può cambiare nel tempo
                                   final updatedDep = provider.departures.firstWhere(
                                     (d) => (targetId != null && d.tripId == targetId) || 
                                            (d.trainNumber == targetNum && d.destination == dep.destination),
                                     orElse: () => dep,
                                   );

                                   return FractionallySizedBox(
                                     heightFactor: 0.85,
                                     child: TrainDetailsSheet(
                                       departure: updatedDep,
                                       isArrivalMode: isArrival,
                                     ),
                                   );
                                 },
                               )
                             );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                // Time Column
                                Column(
                                  children: [
                                    Text(
                                      dep.scheduledTime != null ? _formatStationTime(dep.scheduledTime!, station.country) : '--:--',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                    ),
                                    if (dep.isDelayed)
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          "+${dep.delayMinutes}'",
                                          style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                
                                // Info Column
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${dep.category ?? ''} ${dep.trainNumber ?? ''}",
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(isArrival ? Icons.arrow_back : Icons.arrow_forward, color: Colors.white54, size: 12),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              isArrival ? (dep.origin ?? '') : (dep.destination ?? ''),
                                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Binario: ${dep.platform ?? '?'}",
                                        style: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Action Icon
                                const Icon(Icons.info_outline, color: Colors.blueAccent),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
    }

    // View 2: Search Form & Suggestions
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Cerca Stazione",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            // Selettore Servizio (Direct vs Trainboard)
            DropdownButton<String>(
              value: trainProvider.selectedService,
              dropdownColor: Colors.black87,
              icon: const Icon(Icons.settings, color: Colors.blueAccent, size: 20),
              underline: const SizedBox(),
              style: const TextStyle(color: Colors.blueAccent, fontSize: 13),
              items: const [
                DropdownMenuItem(value: 'direct', child: Text("BC. Transporter")),
                DropdownMenuItem(value: 'trainboardeu', child: Text("Trainboard.eu (Beta)")),
              ],
              onChanged: (val) {
                if (val != null) trainProvider.setService(val);
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Toggle Partenze / Arrivi
        Row(
          children: [
            _buildModeToggle(context, "Partenze", !trainProvider.isArrivalMode, () => trainProvider.setArrivalMode(false)),
            const SizedBox(width: 8),
            _buildModeToggle(context, "Arrivi", trainProvider.isArrivalMode, () => trainProvider.setArrivalMode(true)),
          ],
        ),
        const SizedBox(height: 15),
        if (trainProvider.selectedService == 'trainboardeu' || _selectedCountry != 'IT')
          DropdownButton<String>(
            value: _selectedCountry,
            dropdownColor: Colors.black87,
            style: const TextStyle(color: Colors.white),
            items: displayedCountries.map((c) => DropdownMenuItem(
              value: c['code'],
              child: Text(c['name']!),
            )).toList(),
            onChanged: (val) {
              setState(() => _selectedCountry = val!);
            },
          ),
        const SizedBox(height: 10),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: "Nome stazione...",
            hintStyle: const TextStyle(color: Colors.white54),
            prefixIcon: const Icon(Icons.search, color: Colors.white54),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: (val) {
             if (_selectedCountry == 'EU') {
               trainProvider.searchTrainByNumber(val);
             } else {
               trainProvider.searchStations(val, country: _selectedCountry);
             }
          },
        ),
        const SizedBox(height: 20),
        if (trainProvider.isSearchingByNumber || trainProvider.searchResults.isNotEmpty)
          _buildNumberSearchResults(trainProvider)
        else if (trainProvider.isLoadingSuggestions || trainProvider.stationSuggestions.isNotEmpty)
          _buildStationSuggestions(trainProvider)
        else
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Center(
              child: Text(
                "Inserisci almeno 2 caratteri per la ricerca",
                style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildModeToggle(BuildContext context, String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.blueAccent : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildStationSuggestions(TrainProvider provider) {
    if (provider.isLoadingSuggestions) {
      return const Center(child: CircularProgressIndicator());
    }
    return Expanded(
      child: ListView.builder(
        itemCount: provider.stationSuggestions.length,
        itemBuilder: (context, index) {
          final s = provider.stationSuggestions[index];
          return ListTile(
            leading: const Icon(Icons.location_city, color: Colors.blueAccent),
            title: Text(s.name, style: const TextStyle(color: Colors.white)),
            subtitle: Text(s.country, style: const TextStyle(color: Colors.white54)),
            onTap: () => provider.selectStation(s),
          );
        },
      ),
    );
  }

  Widget _buildNumberSearchResults(TrainProvider provider) {
    if (provider.isSearchingByNumber) {
      return const Center(child: CircularProgressIndicator());
    }
    return Expanded(
      child: ListView.builder(
        itemCount: provider.searchResults.length,
        itemBuilder: (context, index) {
          final m = provider.searchResults[index];
          final line = m['line'] ?? {};
          return ListTile(
            leading: const Icon(Icons.speed, color: Colors.orangeAccent),
            title: Text("${line['name'] ?? '?'}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text("Direzione: ${m['direction'] ?? 'N/A'}", style: const TextStyle(color: Colors.white70)),
            trailing: const Icon(Icons.chevron_right, color: Colors.white24),
            onTap: () {
               final mapState = Provider.of<MapStateProvider>(context, listen: false);
               final lat = m['latitude'];
               final lng = m['longitude'];
               if (lat != null && lng != null) {
                 mapState.flyTo(lat.toDouble(), lng.toDouble(), zoom: 12);
               }
            },
          );
        },
      ),
    );
  }
}
