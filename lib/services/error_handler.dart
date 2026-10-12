import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'app_exception.dart';

/// Centralized utility to safely sanitize, categorize, and transform errors
/// into clear, user-friendly messages without ever exposing technical stack
/// traces, internal URLs, SSH keys, credentials, or raw JSON payloads.
class ErrorHandler {
  /// Strict blacklist of sensitive tokens that MUST NEVER be displayed to the end-user.
  static final List<String> _sensitiveTokens = [
    // Protocols & network references
    'http://',
    'https://',
    'ws://',
    'wss://',
    'ftp://',
    'ssh://',
    'git://',
    'file://',
    'git@',

    // Hosts, domains & cloud platforms
    '.vercel.app',
    '.herokuapp.com',
    '.onrender.com',
    'amazonaws.com',
    '.azurewebsites.net',
    'localhost',
    '127.0.0.1',
    '0.0.0.0',
    ':8080',
    ':3000',
    ':5000',
    ':443',

    // SSH, keys & credentials
    'ssh',
    'id_rsa',
    'id_ed25519',
    'known_hosts',
    'authorized_keys',
    'bearer ',
    'token',
    'secret',
    'api_key',
    'apikey',
    'private_key',
    'password',
    'credential',
    'authorization:',

    // JSON, XML & HTML markup syntax
    '{',
    '}',
    '":"',
    '"error":',
    '"code":',
    '"message":',
    '"status":',
    '<!doctype',
    '<html',
    '<script',
    '<div>',
    'xmlhttprequest',

    // File paths & internal runtime diagnostics
    'c:\\',
    'c:/',
    '/data/user/',
    '/storage/emulated/',
    '/var/task',
    '/tmp/',
    '/etc/',
    'package:',
    'dart:',
    '.dart:',
    'stack trace:',
    'traceback',
    'exception:',
    'clientexception',
    'socketexception',
    'timeoutexception',
    'handshake failed',
    'errno =',
    'os error:',
    'failed host lookup',
  ];

  /// Checks if a message is 100% safe to present to the user.
  /// Rejects anything containing URLs, SSH, credentials, JSON syntax, or system paths.
  static bool isSafeUserFacingMessage(String? msg) {
    if (msg == null) return false;
    final trimmed = msg.trim();
    if (trimmed.isEmpty || trimmed.length > 100) return false;

    final lower = trimmed.toLowerCase();
    for (final token in _sensitiveTokens) {
      if (lower.contains(token)) {
        return false;
      }
    }

    // Must not contain curly braces or brackets that resemble raw data
    if (trimmed.contains('{') || trimmed.contains('}') || trimmed.contains('[') || trimmed.contains(']')) {
      return false;
    }

    return true;
  }

  /// Sanitizes any user-facing text, immediately replacing sensitive or technical
  /// messages with a friendly fallback.
  static String sanitizeUserMessage(
    String? raw, {
    String fallback = "Something went wrong. Please check your internet connection and try again.",
  }) {
    if (raw == null) return fallback;
    final cleaned = raw.replaceAll('Exception: ', '').trim();
    if (isSafeUserFacingMessage(cleaned)) {
      return cleaned;
    }
    return fallback;
  }

  /// Transforms any thrown error or exception into a sanitized, typed [AppException].
  static AppException parse(dynamic error) {
    if (error is AppException) {
      // If the message is already safe, return it directly
      if (isSafeUserFacingMessage(error.message)) {
        return error;
      }
      return AppException(
        title: error.title,
        message: "Something went wrong. Please check your internet connection and try again.",
        type: error.type,
        originalError: error.originalError,
      );
    }

    // Safely log internal diagnostics in debug mode only without user exposure
    if (kDebugMode) {
      debugPrint('[ErrorHandler] Shielded internal exception: $error');
    }

    if (error is SocketException) {
      return AppException(
        title: "No Internet Connection",
        message: "Unable to reach the presentation server. Please check your internet connection and try again.",
        type: ErrorType.network,
        originalError: error,
      );
    }

    if (error is TimeoutException) {
      return AppException(
        title: "Connection Timed Out",
        message: "The server took too long to respond. Please check your internet connection and try again.",
        type: ErrorType.timeout,
        originalError: error,
      );
    }

    if (error is FormatException) {
      return AppException(
        title: "Processing Error",
        message: "Unable to parse presentation content. Please check your internet connection and try again.",
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
        rawString.contains('os error: no address associated with hostname') ||
        rawString.contains('network error') ||
        rawString.contains('offline')) {
      return AppException(
        title: "No Internet Connection",
        message: "Unable to connect to the presentation server. Please check your internet connection and try again.",
        type: ErrorType.network,
        originalError: error,
      );
    }

    // Check for timeout patterns
    if (rawString.contains('timed out') || rawString.contains('timeoutexception')) {
      return AppException(
        title: "Request Timed Out",
        message: "The request took longer than expected. Please check your internet connection and try again.",
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
        rawString.contains('internal server error') ||
        rawString.contains('server error')) {
      return AppException(
        title: "Server Temporarily Unavailable",
        message: "The AI presentation service is temporarily busy. Please check your internet connection and try again.",
        type: ErrorType.server,
        originalError: error,
      );
    }

    // Check for invalid input (400)
    if (rawString.contains('400') || rawString.contains('bad request')) {
      return AppException(
        title: "Invalid Topic Description",
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
        title: "Processing Notice",
        message: "Unable to assemble slide content. Please check your internet connection and try again.",
        type: ErrorType.parse,
        originalError: error,
      );
    }

    // Check if the raw message is safe and non-technical
    final cleaned = error.toString().replaceAll('Exception: ', '').trim();
    if (isSafeUserFacingMessage(cleaned)) {
      return AppException(
        title: "Notice",
        message: cleaned,
        type: ErrorType.unknown,
        originalError: error,
      );
    }

    // Safe universal fallback as requested: "Something went wrong, please check your internet connection"
    return AppException(
      title: "Something Went Wrong",
      message: "Something went wrong. Please check your internet connection and try again.",
      type: ErrorType.unknown,
      originalError: error,
    );
  }
}
