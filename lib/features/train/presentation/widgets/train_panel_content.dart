import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/train_provider.dart';
import '../../../../presentation/providers/map_state_provider.dart';
import 'package:intl/intl.dart';

class TrainPanelContent extends StatefulWidget {
  const TrainPanelContent({super.key});

  @override
  State<TrainPanelContent> createState() => _TrainPanelContentState();
}

class _TrainPanelContentState extends State<TrainPanelContent> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCountry = 'IT';

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
                      
                      return ExpansionTile(
                        iconColor: Colors.white,
                        collapsedIconColor: Colors.white54,
                        onExpansionChanged: (expanded) {
                           if (expanded) trainProvider.expandTrainDetails(index);
                        },
                        leading: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              dep.scheduledTime != null ? DateFormat('HH:mm').format(dep.scheduledTime!) : '--:--',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            if (dep.isDelayed)
                              Text(
                                "+${dep.delayMinutes}'",
                                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                              ),
                          ],
                        ),
                        title: Text(
                          "${dep.category ?? ''} ${dep.trainNumber ?? ''} ${isArrival ? 'da' : '->'} ${isArrival ? dep.origin ?? '' : dep.destination ?? ''}",
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          "Binario: ${dep.platform ?? '?'}",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        children: [
                          if (dep.stops == null)
                             const Padding(
                               padding: EdgeInsets.all(8.0),
                               child: CircularProgressIndicator(strokeWidth: 2),
                             )
                          else if (dep.stops!.isEmpty)
                             const Padding(
                               padding: EdgeInsets.all(8.0),
                               child: Text("Nessuna fermata trovata", style: TextStyle(color: Colors.white54)),
                             )
                          else
                             ...dep.stops!.map((stop) {
                               final isDelayed = (stop.delay is int && stop.delay! > 0);
                               return ListTile(
                                dense: true,
                                leading: Icon(Icons.radio_button_checked, size: 12, color: Colors.blueAccent.withOpacity(0.6)),
                                title: Text(stop.stationName, style: const TextStyle(color: Colors.white, fontSize: 14)),
                                subtitle: Row(
                                  children: [
                                    Text(
                                      "Arr: ${stop.arrival != null ? DateFormat('HH:mm').format(stop.arrival!) : '--'} | Dep: ${stop.departure != null ? DateFormat('HH:mm').format(stop.departure!) : '--'}",
                                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                                    ),
                                    if (isDelayed) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        "+${stop.delay}'",
                                        style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ]
                                  ],
                                ),
                                trailing: stop.platform != null ? Text(stop.platform!, style: const TextStyle(color: Colors.orangeAccent, fontSize: 12)) : null,
                               );
                             }).toList(),
                          
                          // Bottone per vedere sulla mappa
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final mapState = Provider.of<MapStateProvider>(context, listen: false);
                                // Chiamata JavaScript per evidenziare il treno sulla mappa
                                mapState.runJs("window.highlightTrain?.('${dep.trainNumber}', '${dep.tripId}');");
                              },
                              icon: const Icon(Icons.map, size: 18),
                              label: const Text("Segui sulla Mappa"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent.withOpacity(0.2),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 36),
                              ),
                            ),
                          ),
                        ],
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
