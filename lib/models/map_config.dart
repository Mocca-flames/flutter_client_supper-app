import 'package:molo/services/config_service.dart';

/// Deprecated MapConfig (Mapbox removed).
/// This now only exposes Google Maps configuration as per
/// [ADR-005 — Replace Mapbox with Google Places, Geocoding, and Directions](.kilocode/rules/memory-bank/decisions/ADR-005-google-places.md).
class MapConfig {
  final String googleMapsApiKey;

  const MapConfig({
    required this.googleMapsApiKey,
  });

  factory MapConfig.fromConfigService(ConfigService configService) {
    return MapConfig(
      googleMapsApiKey: configService.googleMapsApiKey,
    );
  }
}
