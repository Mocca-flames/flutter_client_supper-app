import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/address_model.dart';
import 'package:provider/provider.dart';
import '../../providers/location_provider.dart';
import '../../models/location_model.dart';
import '../../services/api_service.dart';

class AddressSearchBottomSheet extends StatefulWidget {
  final ScrollController scrollController;
  final Function(AddressModel) onAddressSelected;
  final LocationModel? initialLocation;

  const AddressSearchBottomSheet({
    super.key,
    required this.scrollController,
    required this.onAddressSelected,
    this.initialLocation,
  });

  @override
  _AddressSearchBottomSheetState createState() =>
      _AddressSearchBottomSheetState();
}

class _AddressSearchBottomSheetState extends State<AddressSearchBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<AddressModel> _searchResults = [];
  bool _isSearching = false;
  String _searchQuery = '';
  LocationModel? _currentLocation;
  List<AddressModel> _nearbyLocations = [];
  bool _isLoadingNearby = false;
  String? _errorMessage;

  late final LocationProvider _locationProvider;
  late final ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _locationProvider = Provider.of<LocationProvider>(context, listen: false);
    _apiService = Provider.of<ApiService>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
      _fetchCurrentLocationAndNearbyPlaces();
    });

    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _fetchCurrentLocationAndNearbyPlaces() async {
    if (!mounted) return;

    setState(() {
      _isLoadingNearby = true;
      _errorMessage = null;
    });

    try {
      // Use initial location if provided, otherwise use user's current location
      _currentLocation = widget.initialLocation ?? _locationProvider.userLocation;

      if (_currentLocation != null) {
        final addressResult = await _apiService.reverseGeocode(
          lat: _currentLocation!.latitude,
          lng: _currentLocation!.longitude,
        );

        if (addressResult != null &&
            addressResult.latitude != null &&
            addressResult.longitude != null &&
            addressResult.fullAddress != null &&
            mounted) {
          setState(() {
            _currentLocation = LocationModel(
              latitude: addressResult.latitude!,
              longitude: addressResult.longitude!,
              address: addressResult.fullAddress!,
            );
          });
        }

        final nearbyPlaces = await _apiService.searchNearbyPlaces(
          lat: _currentLocation!.latitude,
          lng: _currentLocation!.longitude,
          limit: 5,
        );

        if (mounted) {
          setState(() {
            _nearbyLocations = nearbyPlaces;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage =
                'Unable to get your current location. Please check location permissions.';
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching current location or nearby places: $e');
      }
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load location data. Please try again.';
          _nearbyLocations = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingNearby = false;
        });
      }
    }
  }

  void _onSearchChanged() {
    final currentQuery = _searchController.text;
    if (currentQuery != _searchQuery) {
      _searchQuery = currentQuery;
      if (_searchQuery.isNotEmpty) {
        _performSearch(_searchQuery);
      } else {
        if (mounted) {
          setState(() {
            _searchResults.clear();
            _errorMessage = null;
          });
        }
        _fetchCurrentLocationAndNearbyPlaces();
      }
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty || !mounted) return;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final results = await _apiService.searchAddresses(
        query: query,
        proximityLat: _currentLocation?.latitude,
        proximityLng: _currentLocation?.longitude,
        limit: 10,
      );

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error searching addresses: $e');
      }

      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchResults.clear();
          _errorMessage = 'Failed to search addresses. Please try again.';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching addresses: ${e.toString()}'),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _clearSearch() {
    _searchController.clear();
    if (mounted) {
      setState(() {
        _searchResults.clear();
        _searchQuery = '';
        _errorMessage = null;
      });
    }
    _fetchCurrentLocationAndNearbyPlaces();
  }

  bool _isResolvingCoordinates = false;

  Future<void> _selectAddress(AddressModel address) async {
    if (_isResolvingCoordinates) return;

    if (kDebugMode) {
      print('Selecting address: $address');
    }

    if (address.latitude != null && address.longitude != null) {
      try {
        widget.onAddressSelected(address);
      } catch (e) {
        if (kDebugMode) {
          print('Error selecting address: $e');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting address: ${e.toString()}'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
      return;
    }

    // Resolve coordinates for address without lat/lng
    _isResolvingCoordinates = true;
    setState(() {
      _errorMessage = null;
    });

    try {
      final detailedLocation = await _apiService.placeDetails(
        placeId: address.placeId ?? '',
      );
      if (detailedLocation != null &&
          detailedLocation.latitude != null &&
          detailedLocation.longitude != null) {
        final resolvedAddress = AddressModel(
          id: address.id,
          street: address.street,
          city: address.city,
          state: address.state,
          postalCode: address.postalCode,
          country: address.country,
          latitude: detailedLocation.latitude!,
          longitude: detailedLocation.longitude!,
          fullAddress: detailedLocation.address ?? address.fullAddress,
          placeId: address.placeId,
          placeName: address.placeName,
        );
        if (mounted) {
          widget.onAddressSelected(resolvedAddress);
        }
      } else {
        throw Exception('Failed to resolve coordinates for selected address.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error resolving address coordinates: $e');
      }
      if (mounted) {
        setState(() {
          _errorMessage =
              'Failed to resolve address coordinates. Please try again.';
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error resolving address coordinates: ${e.toString()}'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    } finally {
      _isResolvingCoordinates = false;
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Search row with cancel button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Search for an address...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: _clearSearch,
                              icon: const Icon(Icons.clear),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        _performSearch(value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // Error message
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Content area
          Expanded(
            child: _isSearching
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text('Searching addresses...'),
                      ],
                    ),
                  )
                : _searchQuery.isNotEmpty
                ? _buildSearchResults()
                : _buildLocationContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'No results found',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            SizedBox(height: 4),
            Text(
              'Try a different search term',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: widget.scrollController,
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final address = _searchResults[index];
        return ListTile(
          // Remove enabled to allow tapping even if coordinates are missing
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.place, color: Colors.red),
          ),
          title: Text(
            address.placeName ?? address.fullAddress ?? 'Unknown location',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            address.fullAddress ?? '',
            style: TextStyle(color: Colors.grey.shade600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => _selectAddress(address),
        );
      },
    );
  }

  Widget _buildLocationContent() {
    if (_isLoadingNearby) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 8),
            Text('Loading location data...'),
          ],
        ),
      );
    }

    return ListView(
      controller: widget.scrollController,
      children: [
        // Current location option
        if (_currentLocation != null && _currentLocation!.address != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  'Current Location',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              ListTile(
                enabled: true,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.my_location, color: Colors.blue),
                ),
                title: Text(
                  _currentLocation!.address!,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: const Text(
                  'Your current location',
                  style: TextStyle(color: Colors.grey),
                ),
                onTap: () => _selectAddress(
                  AddressModel(
                    fullAddress: _currentLocation!.address,
                    latitude: _currentLocation!.latitude,
                    longitude: _currentLocation!.longitude,
                  ),
                ),
              ),
              const Divider(),
            ],
          ),

        // Nearby locations
        if (_nearbyLocations.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  'Nearby Places',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              ..._nearbyLocations.map((address) {
                return ListTile(
                  enabled:
                      address.latitude != null && address.longitude != null,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.location_on, color: Colors.green),
                  ),
                  title: Text(
                    address.placeName ?? address.fullAddress ?? 'Unknown place',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    address.fullAddress ?? '',
                    style: TextStyle(color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _selectAddress(address),
                );
              }),
            ],
          ),

        // Empty state
        if (_currentLocation == null &&
            _nearbyLocations.isEmpty &&
            !_isLoadingNearby)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(Icons.location_off, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Location not available',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please check your location permissions and try again',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
