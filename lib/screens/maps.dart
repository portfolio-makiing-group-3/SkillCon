import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapsWidget extends StatefulWidget {
  const MapsWidget({Key? key}) : super(key: key);

  @override
  State<MapsWidget> createState() => _MapsWidgetState();
}

class _MapsWidgetState extends State<MapsWidget> {
  final Set<Marker> _markers = {};
  List<dynamic> _jobs = [];
  LatLng _initialPosition = const LatLng(14.5995, 120.9842); // Manila default
  bool _loading = true;
  String? _loadingError;

  // For selected job marker info
  dynamic _selectedJob;
  LatLng? _selectedPosition;

  @override
  void initState() {
    super.initState();
    _loadJobMarkers();
  }

  Future<void> _loadJobMarkers() async {
    try {
      final String response = await rootBundle.loadString(
        'lib/dataset/job_dataset.json',
      );
      final List<dynamic> jobs = json.decode(response);

      final Set<Marker> loadedMarkers = {};
      LatLng? firstLocation;

      for (int i = 0; i < jobs.length; i++) {
        final job = jobs[i];
        final LatLng position = LatLng(
          (job['latitude'] as num?)?.toDouble() ?? 14.5995,
          (job['longitude'] as num?)?.toDouble() ?? 120.9842,
        );

        if (i == 0) {
          firstLocation = position;
        }

        loadedMarkers.add(
          Marker(
            markerId: MarkerId('job_$i'),
            position: position,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
            onTap: () {
              // Show custom info window on tap
              setState(() {
                _selectedJob = job;
                _selectedPosition = position;
              });
            },
          ),
        );
      }

      setState(() {
        _markers.clear();
        _markers.addAll(loadedMarkers);
        _jobs = jobs;
        if (firstLocation != null) {
          _initialPosition = firstLocation;
        }
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _loadingError = "Failed to load job data: $e";
      });
    }
  }

  void _closeInfoWindow() {
    setState(() {
      _selectedJob = null;
      _selectedPosition = null;
    });
  }

  Widget _buildCustomInfoWindow() {
    if (_selectedJob == null) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedJob['job'] ?? '',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _closeInfoWindow,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Location: ${_selectedJob['place'] ?? ''}",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(_selectedJob['description'] ?? ''),
                const SizedBox(height: 8),
                Text(
                  "Skills: ${(_selectedJob['skillset'] as List<dynamic>).join(', ')}",
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Salary Range: ${_selectedJob['salary-range'] ?? ''}",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Menu pressed')));
          },
        ),
        title: Image.asset(
          'lib/assets/branding.png',
          height: 100,
          fit: BoxFit.contain,
        ),
      ),
      body: Stack(
        children: [
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _loadingError != null
              ? Center(
                  child: Text(
                    _loadingError!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                )
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _initialPosition,
                    zoom: 11,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                  zoomGesturesEnabled: true,
                  scrollGesturesEnabled: true,
                  rotateGesturesEnabled: true,
                  tiltGesturesEnabled: true,
                  onTap: (_) {
                    // Hide info window if user taps elsewhere on the map
                    _closeInfoWindow();
                  },
                ),
          // Custom info window overlay
          if (_selectedJob != null) _buildCustomInfoWindow(),
        ],
      ),
    );
  }
}
