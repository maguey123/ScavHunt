import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class MapPickerPage extends StatefulWidget {
  final LatLng? initialPosition;
  const MapPickerPage({super.key, this.initialPosition});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  late LatLng _currentPos;
  double _radius = 25;
  final Completer<GoogleMapController> _controller = Completer();
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentPos = widget.initialPosition ?? const LatLng(-33.8688, 151.2093); // Sydney default
  }

  /// move map camera to given coordinates
  Future<void> _goToLocation(LatLng target) async {
    final controller = await _controller.future;
    await controller.animateCamera(CameraUpdate.newLatLng(target));
  }

  /// search bar handler
  Future<void> _searchPlace() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return;

    try {
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final newPos = LatLng(loc.latitude, loc.longitude);
        setState(() => _currentPos = newPos);
        _goToLocation(newPos);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location not found: $e')),
      );
    }
  }

  /// confirm selection
  void _confirm() {
    Navigator.pop(context, {
      'lat': _currentPos.latitude,
      'lng': _currentPos.longitude,
      'radius': _radius,
    });
  }

  @override
  Widget build(BuildContext context) {
    final circle = Circle(
      circleId: const CircleId('radius'),
      center: _currentPos,
      radius: _radius,
      fillColor: Colors.deepOrange.withOpacity(0.2),
      strokeColor: Colors.deepOrange,
      strokeWidth: 2,
    );

    final marker = Marker(
      markerId: const MarkerId('selected'),
      position: _currentPos,
      draggable: true,
      onDragEnd: (pos) => setState(() => _currentPos = pos),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Select Location')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _currentPos, zoom: 17),
            markers: {marker},
            circles: {circle},
            onMapCreated: (ctrl) => _controller.complete(ctrl),
            onTap: (pos) => setState(() => _currentPos = pos),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),

          /// Search bar overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Material(
                elevation: 3,
                borderRadius: BorderRadius.circular(8),
                child: TextField(
                  controller: _searchCtrl,
                  onSubmitted: (_) => _searchPlace(),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search for a place...',
                    border: InputBorder.none,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _searchPlace,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  ),
                ),
              ),
            ),
          ),

          /// Radius selector + Confirm button
          Positioned(
            bottom: 25,
            left: 10,
            right: 10,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.radio_button_checked, color: Colors.deepOrange),
                        const SizedBox(width: 10),
                        const Text('Radius (m):'),
                        Expanded(
                          child: Slider(
                            value: _radius,
                            min: 5,
                            max: 50,
                            divisions: 9,
                            activeColor: Colors.deepOrange,
                            onChanged: (v) => setState(() => _radius = v),
                          ),
                        ),
                        Text(_radius.toStringAsFixed(0)),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _confirm,
                      icon: const Icon(Icons.check),
                      label: const Text('Confirm Location'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
