import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'app_exception.dart';

/// Centralized utility to safely sanitize, categorize, and transform errors
/// into clear, user-friendly messages without ever exposing technical stack
/// traces, internal URLs, or raw JSON payloads.
class ErrorHandler {
  /// Transforms any thrown error or exception into a sanitized, typed [AppException].
  static AppException parse(dynamic error) {
    if (error is AppException) {
      return error;
    }

    // Safely log internal diagnostics in debug mode without user visibility
    if (kDebugMode) {
      debugPrint('[ErrorHandler] Caught exception: $error');
    }

    if (error is SocketException) {
      return AppException(
        title: "No Internet Connection",
        message: "Please check your Wi-Fi or mobile data connection and try again.",
        type: ErrorType.network,
        originalError: error,
      );
    }

    if (error is TimeoutException) {
      return AppException(
        title: "Connection Timed Out",
        message: "The server took too long to respond. Please check your internet and try again.",
        type: ErrorType.timeout,
        originalError: error,
      );
    }

    if (error is FormatException) {
      return AppException(
        title: "Processing Error",
        message: "Unable to parse presentation content. Please try again with a different topic.",
        type: ErrorType.parse,
        originalError: error,
      );
    }

    final rawString = error.toString().toLowerCase();

    // Check for network and connectivity patterns
    if (rawString.contains('socketexception') ||
        rawString.contains('failed host lookup') ||
        rawString.contains('clientexception') ||
        rawString.contains('network is unreachable') ||
        rawString.contains('connection refused') ||
        rawString.contains('connection reset') ||
        rawString.contains('handshake failed') ||
        rawString.contains('os error: no address associated with hostname')) {
      return AppException(
        title: "No Internet Connection",
        message: "Unable to reach the presentation server. Please check your internet connection.",
        type: ErrorType.network,
        originalError: error,
      );
    }

    // Check for timeout patterns
    if (rawString.contains('timed out') || rawString.contains('timeoutexception')) {
      return AppException(
        title: "Request Timed Out",
        message: "The presentation generation took longer than expected. Please try again.",
        type: ErrorType.timeout,
        originalError: error,
      );
    }

    // Check for rate limiting
    if (rawString.contains('429') || rawString.contains('rate limit') || rawString.contains('too many requests')) {
      return AppException(
        title: "Rate Limit Reached",
        message: "You have made several requests recently. Please wait a moment before trying again.",
        type: ErrorType.rateLimit,
        originalError: error,
      );
    }

    // Check for server errors (5xx)
    if (rawString.contains('500') ||
        rawString.contains('502') ||
        rawString.contains('503') ||
        rawString.contains('504') ||
        rawString.contains('gateway timeout') ||
        rawString.contains('bad gateway') ||
        rawString.contains('internal server error')) {
      return AppException(
        title: "Server Temporarily Unavailable",
        message: "The AI presentation service is currently experiencing high demand. Please try again shortly.",
        type: ErrorType.server,
        originalError: error,
      );
    }

    // Check for invalid input (400)
    if (rawString.contains('400') || rawString.contains('bad request')) {
      return AppException(
        title: "Invalid Topic Input",
        message: "Please enter a valid presentation topic or prompt description.",
        type: ErrorType.client,
        originalError: error,
      );
    }

    // Check for JSON or schema parse issues
    if (rawString.contains('formatexception') ||
        rawString.contains('unexpected character') ||
        rawString.contains('json.decode') ||
        rawString.contains('syntaxerror')) {
      return AppException(
        title: "Generation Format Issue",
        message: "The AI returned an invalid slide structure. Please try refining your topic.",
        type: ErrorType.parse,
        originalError: error,
      );
    }

    // Fallback: check if the string message is user-friendly and doesn't leak URLs/code
    final cleaned = _sanitizeMessage(error.toString());
    if (cleaned != null && cleaned.isNotEmpty) {
      return AppException(
        title: "Notice",
        message: cleaned,
        type: ErrorType.unknown,
        originalError: error,
      );
    }

    // Default safe fallback
    return AppException(
      title: "Something Went Wrong",
      message: "An unexpected error occurred while processing your request. Please try again.",
      type: ErrorType.unknown,
      originalError: error,
    );
  }

  /// Strips technical code, HTTP URLs, file paths, and package artifacts from raw messages.
  static String? _sanitizeMessage(String raw) {
    String msg = raw.replaceAll('Exception: ', '').trim();

    // If message contains sensitive indicators, reject it
    if (msg.contains('http://') ||
        msg.contains('https://') ||
        msg.contains('.vercel.app') ||
        msg.contains('{') ||
        msg.contains('}') ||
        msg.contains('<html') ||
        msg.contains('<!DOCTYPE') ||
        msg.contains('XMLHttpRequest') ||
        msg.contains('ClientException') ||
        msg.contains('SocketException') ||
        msg.contains('Stack trace:')) {
      return null;
    }

    // If message is too long (likely raw response dump), reject it
    if (msg.length > 120) {
      return null;
    }

    return msg;
  }
}
