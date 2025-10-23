import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

// Define a generic ErrorType or specific error classes if needed
// For now, using dynamic for simplicity
// class ApiError { final String message; ApiError(this.message); }
// class WebSocketError { final String message; WebSocketError(this.message); }
// class AuthError { final String message; AuthError(this.message); }

class ErrorHandler {
  static void handleApiError(dynamic error) {
    // Log the error, send to a reporting service, etc.
    var logger = Logger();
    logger.e("API Error: $error");
    // Potentially re-throw or transform into a user-friendly error
  }

  static void handleWebSocketError(dynamic error) {
    // Log the error, send to a reporting service, etc.
    var logger = Logger();
    logger.e("WebSocket Error: $error");
    // Potentially re-throw or transform into a user-friendly error
  }

  static void handleAuthError(dynamic error) {
    // Log the error, send to a reporting service, etc.
    var logger = Logger();
    logger.e("Authentication Error: $error");
    // Potentially re-throw or transform into a user-friendly error
  }

  static void showErrorDialog(BuildContext context, dynamic error) {
    String errorMessage = "An unexpected error occurred.";
    if (error is String) {
      errorMessage = error;
    } else if (error is Exception) {
      errorMessage = error.toString();
    }
    // else if (error is ApiError) {
    //   errorMessage = "API Error: ${error.message}";
    // } else if (error is WebSocketError) {
    //   errorMessage = "Connection Error: ${error.message}";
    // } else if (error is AuthError) {
    //   errorMessage = "Authentication Failed: ${error.message}";
    // }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text("Error"),
          content: Text(errorMessage),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
