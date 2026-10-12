import 'package:flutter/material.dart';

/// Categories of errors encountered in the application.
enum ErrorType {
  /// No network, socket failure, offline, host lookup failure
  network,

  /// Request timed out waiting for server response
  timeout,

  /// 5xx, gateway error, backend service crash
  server,

  /// 400 bad request, 404 missing resource
  client,

  /// 429 too many requests
  rateLimit,

  /// JSON decoding error, schema mismatch, malformed response
  parse,

  /// File storage, permissions, or write failure
  storage,

  /// Catch-all for unexpected exceptions
  unknown,
}

/// A structured, user-safe exception class.
/// 
/// Guarantees that technical stack traces, internal URLs, and raw JSON
/// payloads are never displayed to the end user.
class AppException implements Exception {
  /// User-friendly title suitable for dialog headers
  final String title;

  /// User-friendly, actionable description
  final String message;

  /// Semantic category of the error
  final ErrorType type;

  /// Original raw technical error, kept exclusively for internal diagnostics
  final dynamic originalError;

  const AppException({
    required this.title,
    required this.message,
    required this.type,
    this.originalError,
  });

  /// Associated vector icon representing this error state
  IconData get icon {
    switch (type) {
      case ErrorType.network:
        return Icons.wifi_off_rounded;
      case ErrorType.timeout:
        return Icons.timer_outlined;
      case ErrorType.server:
        return Icons.cloud_off_rounded;
      case ErrorType.rateLimit:
        return Icons.hourglass_empty_rounded;
      case ErrorType.parse:
        return Icons.auto_awesome_motion_outlined;
      case ErrorType.storage:
        return Icons.folder_off_outlined;
      case ErrorType.client:
        return Icons.info_outline_rounded;
      case ErrorType.unknown:
        return Icons.error_outline_rounded;
    }
  }

  @override
  String toString() => message;
}
