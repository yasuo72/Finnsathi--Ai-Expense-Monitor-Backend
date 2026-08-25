import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart' as geolocator;

class AddressPickerScreen extends StatefulWidget {
  const AddressPickerScreen({super.key});

  @override
  State<AddressPickerScreen> createState() => _AddressPickerScreenState();
}

class _AddressPickerScreenState extends State<AddressPickerScreen> {
  // Never null after init
  late LatLng _pickedLocation;
  String? _pickedAddress;
  late flutter_map.MapController _mapController;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _pickedLocation = LatLng(22.5726, 88.3639); // Kolkata default
    _mapController = flutter_map.MapController();
    _getAddress(_pickedLocation);
    _initLocation();
  }

  Future<void> _getAddress(LatLng pos) async {
    setState(() => _loading = true);
    print(
      '[AddressPicker] Fetching address for: Lat=${pos.latitude}, Lng=${pos.longitude}',
    );
    try {
      final placemarks = await geocoding.placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      print('[AddressPicker] placemarks result: $placemarks');
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address = [
          place.name,
          place.street,
          place.locality,
          place.administrativeArea,
          place.country,
        ].where((part) => part != null && part.trim().isNotEmpty).join(', ');
        setState(() {
          _pickedAddress =
              address.isNotEmpty
                  ? address
                  : 'No address details available for this location.';
        });
      } else {
        setState(
          () => _pickedAddress = 'No address found for these coordinates.',
        );
      }
    } catch (e, stack) {
      print('[AddressPicker] Error in placemarkFromCoordinates: $e\n$stack');
      setState(() => _pickedAddress = 'Error fetching address: $e');
    }
    setState(() => _loading = false);
  }

  Future<void> _initLocation() async {
    try {
      final serviceEnabled =
          await geolocator.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      var permission = await geolocator.Geolocator.checkPermission();
      if (permission == geolocator.LocationPermission.denied) {
        permission = await geolocator.Geolocator.requestPermission();
      }

      if (permission == geolocator.LocationPermission.denied ||
          permission == geolocator.LocationPermission.deniedForever) {
        return;
      }

      final position = await geolocator.Geolocator.getCurrentPosition(
        desiredAccuracy: geolocator.LocationAccuracy.high,
      );

      final current = LatLng(position.latitude, position.longitude);

      if (!mounted) return;

      setState(() {
        _pickedLocation = current;
        _pickedAddress = null;
      });

      _mapController.move(current, 15.0);
      await _getAddress(current);
    } catch (e, stack) {
      print('[AddressPicker] Error getting current location: $e\n$stack');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pick Address')),
      body: Stack(
        children: [
          flutter_map.FlutterMap(
            mapController: _mapController,
            options: flutter_map.MapOptions(
              initialCenter: _pickedLocation,
              initialZoom: 13.0,
              onTap: (_, latLng) {
                setState(() {
                  _pickedLocation = latLng;
                  _pickedAddress = null;
                });
                _getAddress(latLng);
              },
            ),
            children: [
              flutter_map.TileLayer(
                urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.finsaathi_multi',
              ),
              flutter_map.MarkerLayer(
                markers: [
                  flutter_map.Marker(
                    width: 60.0,
                    height: 60.0,
                    point: _pickedLocation,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 90,
            left: 24,
            right: 24,
            child: Card(
              color: Theme.of(context).cardColor,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child:
                    _loading
                        ? Row(
                          children: const [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Fetching address...'),
                          ],
                        )
                        : Text(
                          _pickedAddress ??
                              'No address found for this location',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
              ),
            ),
          ),
          Positioned(
            bottom: 32,
            left: 24,
            right: 24,
            child: ElevatedButton(
              onPressed:
                  _pickedAddress == null || _loading
                      ? null
                      : () {
                        Navigator.pop(context, _pickedAddress);
                      },
              child: const Text('Use this address'),
            ),
          ),
        ],
      ),
    );
  }
}
