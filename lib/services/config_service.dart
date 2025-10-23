import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class ConfigService {
  final FirebaseFirestore _firestore;

  ConfigService(this._firestore);

  static const String _defaultBaseUrl = "http://56.228.32.209:8000";
  static final String _defaultGoogleMapsApiKey =
      dotenv.env['GOOGLE_MAPS_API_KEY'] ?? "AIzaSyDuoK9UDDH30uBuZKRhLRvAWnYgPfRKzz0";

  String _baseUrl = _defaultBaseUrl;
  String _googleMapsApiKey = _defaultGoogleMapsApiKey;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await dotenv.load(fileName: ".env");

    try {
      final DocumentSnapshot<Map<String, dynamic>> configDoc = await _firestore
          .collection('config')
          .doc('api')
          .get();

      if (configDoc.exists && configDoc.data() != null) {
        final data = configDoc.data()!;
        final fetchedUrl = data['baseUrl'] as String?;
        final fetchedGoogleMapsApiKey = data['googleMapsApiKey'] as String?;

        if (fetchedUrl != null && fetchedUrl.isNotEmpty) {
          _baseUrl = fetchedUrl;
          if (kDebugMode) {
            Logger().i('[ConfigService] fetched baseUrl: $_baseUrl');
          }
        } else {
          if (kDebugMode) {
            print(
              '[ConfigService] baseUrl missing in Firestore, using default.',
            );
          }
        }

        if (fetchedGoogleMapsApiKey != null &&
            fetchedGoogleMapsApiKey.isNotEmpty) {
          _googleMapsApiKey = fetchedGoogleMapsApiKey;
          if (kDebugMode) {
            Logger().i('[ConfigService] fetched googleMapsApiKey');
          }
        } else {
          if (kDebugMode) {
            print(
              '[ConfigService] googleMapsApiKey missing in Firestore, using default.',
            );
          }
        }
      } else {
        if (kDebugMode) {
          print('[ConfigService] Config doc not found, using defaults.');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[ConfigService] Error fetching config: $e. Using defaults.');
      }
    }
    _isInitialized = true;
  }

  String get baseUrl {
    if (!_isInitialized && kDebugMode) {
      print(
        "[ConfigService] baseUrl accessed before initialize(); returning default.",
      );
    }
    return _baseUrl;
  }

  String get googleMapsApiKey {
    if (!_isInitialized && kDebugMode) {
      print(
        "[ConfigService] googleMapsApiKey accessed before initialize(); returning default.",
      );
    }
    return _googleMapsApiKey;
  }
}
