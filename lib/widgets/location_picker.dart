import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/location_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/address_model.dart';

class LocationPicker extends StatefulWidget {
  final Function(LocationModel) onLocationSelected;
  final LocationModel? initialLocation;

  const LocationPicker({
    super.key,
    required this.onLocationSelected,
    this.initialLocation,
  });

  @override
  _LocationPickerState createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  LocationModel? _pickedLocation;
  bool _isLoading = false;

  late final ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = Provider.of<ApiService>(
      context,
      listen: false,
    );
    if (widget.initialLocation != null) {
      _pickedLocation = widget.initialLocation;
    }
  }

  // Implement address autocomplete
  Future<void> _showLocationDialog() async {

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            List<AddressModel> searchResults = [];
            bool searching = false;

            Future<void> searchAddresses(String query) async {
              setState(() {
                searching = true;
                searchResults = [];
              });

              try {
                final results = await _apiService.searchAddresses(
                  query: query,
                );

                setState(() {
                  searchResults = results;
                });
              } catch (e) {
                var logger = Logger();
                logger.e('Error searching addresses: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Could not search addresses: ${e.toString()}',
                    ),
                  ),
                );
              } finally {
                setState(() {
                  searching = false;
                });
              }
            }

            return AlertDialog(
              title: const Text('Pick Location'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search address',
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        searchAddresses(value);
                      } else {
                        setState(() {
                          searchResults = [];
                        });
                      }
                    },
                  ),
                  if (searching)
                    const CircularProgressIndicator()
                  else
                    SizedBox(
                      height: 200,
                      width: 300,
                      child: ListView.builder(
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          final result = searchResults[index];
                          return ListTile(
                            title: Text(result.fullAddress ?? result.placeName ?? ''),
                            onTap: () async {
                              try {
                                final placeId = result.placeId ?? '';
                                if (placeId.isNotEmpty) {
                                  final details = await _apiService.placeDetails(placeId: placeId);
                                  if (details != null) {
                                    setState(() {
                                      _pickedLocation = details;
                                    });
                                    Navigator.pop(context);
                                  }
                                } else {
                                  // Fallback: set only the address text if no placeId
                                  setState(() {
                                    _pickedLocation = LocationModel(
                                      latitude: 0,
                                      longitude: 0,
                                      address: result.fullAddress ?? result.placeName,
                                      placeId: result.placeId,
                                      placeName: result.placeName,
                                    );
                                  });
                                  Navigator.pop(context);
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to get place details: $e')),
                                );
                              }
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      },
    );

    if (_pickedLocation != null) {
      widget.onLocationSelected(_pickedLocation!);
      setState(() {});
    }
  }

  // Implement reverse geocoding for current location
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check for location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permissions are denied. Please enable them in settings.',
              ),
            ),
          );
          setState(() => _isLoading = false);
          return;
        }
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location services are disabled. Please enable them.',
            ),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10), // Add a time limit
      );

      try {
        final AddressModel? addr = await _apiService.reverseGeocode(
          lat: position.latitude,
          lng: position.longitude,
        );
        setState(() {
          _pickedLocation = LocationModel(
            latitude: position.latitude,
            longitude: position.longitude,
            address: addr?.fullAddress ?? 'Lat: ${position.latitude}, Lon: ${position.longitude}',
            placeId: addr?.placeId,
            placeName: addr?.placeName,
          );
          widget.onLocationSelected(_pickedLocation!);
        });
      } catch (e) {
        var logger = Logger();
        logger.e('Error reverse geocoding: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not reverse geocode: ${e.toString()}')),
        );
        setState(() {
          _pickedLocation = LocationModel(
            latitude: position.latitude,
            longitude: position.longitude,
            address: 'Lat: ${position.latitude}, Lan: ${position.longitude}',
          );
          widget.onLocationSelected(_pickedLocation!);
        });
      }
    } catch (e) {
      var logger = Logger();
      logger.e('Error getting current location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not get current location: ${e.toString()}'),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _pickedLocation == null
              ? 'No location selected'
              : 'Selected: ${_pickedLocation!.address ?? 'Lat: ${_pickedLocation!.latitude}, Lan: ${_pickedLocation!.longitude}'}',
          style: const TextStyle(fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.map),
                label: const Text('Pick Location'),
                onPressed: _showLocationDialog,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.my_location),
                label: const Text('Current Location'),
                onPressed: _getCurrentLocation,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
