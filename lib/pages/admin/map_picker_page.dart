import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import '../../theme/app_theme.dart';

class MapPickerPage extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  const MapPickerPage({super.key, this.initialLat, this.initialLng});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  late LatLng _pos;
  double _radius = 25;
  final _ctrl    = Completer<GoogleMapController>();
  final _search  = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pos = (widget.initialLat != null && widget.initialLng != null)
        ? LatLng(widget.initialLat!, widget.initialLng!)
        : const LatLng(-33.8688, 151.2093); // Sydney default
  }

  Future<void> _goTo(LatLng t) async {
    (await _ctrl.future).animateCamera(CameraUpdate.newLatLng(t));
  }

  Future<void> _searchPlace() async {
    final q = _search.text.trim();
    if (q.isEmpty) return;
    try {
      final locs = await locationFromAddress(q);
      if (locs.isNotEmpty) {
        final p = LatLng(locs.first.latitude, locs.first.longitude);
        setState(() => _pos = p);
        _goTo(p);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Not found: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pick Location'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context))),
      body: Stack(children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: _pos, zoom: 17),
          markers: {Marker(
            markerId: const MarkerId('pin'), position: _pos, draggable: true,
            onDragEnd: (p) => setState(() => _pos = p))},
          circles: {Circle(
            circleId: const CircleId('r'), center: _pos, radius: _radius,
            fillColor: ScavColors.accent.withOpacity(0.15),
            strokeColor: ScavColors.accent, strokeWidth: 2)},
          onMapCreated: (c) => _ctrl.complete(c),
          onTap: (p) => setState(() => _pos = p),
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
        ),
        // Search
        SafeArea(child: Padding(
          padding: const EdgeInsets.all(12),
          child: Material(
            color: ScavColors.surface, borderRadius: BorderRadius.circular(10),
            child: TextField(
              controller: _search,
              onSubmitted: (_) => _searchPlace(),
              textInputAction: TextInputAction.search,
              style: const TextStyle(color: ScavColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search for a place...',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                prefixIcon: const Icon(Icons.search, color: ScavColors.textMuted),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send, color: ScavColors.accent, size: 18),
                  onPressed: _searchPlace)),
            ),
          ),
        )),
        // Confirm panel
        Positioned(bottom: 20, left: 12, right: 12, child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: ScavColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ScavColors.border)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              const Icon(Icons.radio_button_checked, color: ScavColors.accent, size: 18),
              const SizedBox(width: 8),
              const Expanded(child: Text('Check-in radius',
                style: TextStyle(color: ScavColors.textSecondary, fontSize: 13))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: ScavColors.accentLo,
                  borderRadius: BorderRadius.circular(20)),
                child: Text('${_radius.toStringAsFixed(0)} m', style: const TextStyle(
                  color: ScavColors.accent, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ]),
            Slider(value: _radius, min: 5, max: 100, divisions: 19,
              onChanged: (v) => setState(() => _radius = v)),
            const Text('50m ≈ half a block', style: TextStyle(
              color: ScavColors.textMuted, fontSize: 11)),
            const SizedBox(height: 8),
            ScavPrimaryButton(label: 'Confirm Location', onPressed: () {
              Navigator.pop(context, {'lat': _pos.latitude, 'lng': _pos.longitude, 'radius': _radius});
            }),
          ]),
        )),
      ]),
    );
  }
}
