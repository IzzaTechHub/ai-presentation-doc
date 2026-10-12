import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/services/app_exception.dart';
import 'package:flutter_app/services/error_handler.dart';

void main() {
  group('ErrorHandler Tests', () {
    test('Correctly maps SocketException to network error without leaking host', () {
      const socketError = SocketException("Failed host lookup: 'ai-presentation-backend.vercel.app'");
      final appError = ErrorHandler.parse(socketError);

      expect(appError.type, equals(ErrorType.network));
      expect(appError.title, equals("No Internet Connection"));
      expect(appError.message.contains("ai-presentation-backend.vercel.app"), isFalse);
      expect(appError.message.contains("SocketException"), isFalse);
    });

    test('Correctly maps TimeoutException to timeout error', () {
      final timeoutError = TimeoutException("Future timed out after 0:00:15.000000");
      final appError = ErrorHandler.parse(timeoutError);

      expect(appError.type, equals(ErrorType.timeout));
      expect(appError.title, equals("Connection Timed Out"));
      expect(appError.message.contains("0:00:15"), isFalse);
    });

    test('Correctly maps FormatException to parse error without leaking raw payload', () {
      const formatError = FormatException("Unexpected character (at character 1) <!DOCTYPE html>...");
      final appError = ErrorHandler.parse(formatError);

      expect(appError.type, equals(ErrorType.parse));
      expect(appError.title, equals("Processing Error"));
      expect(appError.message.contains("<!DOCTYPE"), isFalse);
    });

    test('Sanitizes 504 Gateway Timeout or server errors', () {
      final serverError = Exception("Server returned status 504 Gateway Timeout from https://ai-presentation-backend.vercel.app/generate");
      final appError = ErrorHandler.parse(serverError);

      expect(appError.type, equals(ErrorType.server));
      expect(appError.title, equals("Server Temporarily Unavailable"));
      expect(appError.message.contains("vercel.app"), isFalse);
      expect(appError.message.contains("https://"), isFalse);
      expect(appError.message.contains("504"), isFalse);
    });

    test('Sanitizes 429 Rate Limit error', () {
      final rateError = Exception("Client error 429 Too Many Requests");
      final appError = ErrorHandler.parse(rateError);

      expect(appError.type, equals(ErrorType.rateLimit));
      expect(appError.title, equals("Rate Limit Reached"));
      expect(appError.message.contains("429"), isFalse);
    });

    test('Never leaks JSON structure or braces in output message', () {
      final jsonLeakError = Exception('{"error": "Internal AI crash at route /generate", "code": 500}');
      final appError = ErrorHandler.parse(jsonLeakError);

      expect(appError.message.contains('{'), isFalse);
      expect(appError.message.contains('}'), isFalse);
      expect(appError.message.contains('/generate'), isFalse);
    });

    test('Existing AppException passes through unchanged', () {
      const custom = AppException(
        title: "Custom Title",
        message: "Friendly notice message",
        type: ErrorType.client,
      );
      final parsed = ErrorHandler.parse(custom);

      expect(parsed, equals(custom));
      expect(parsed.title, equals("Custom Title"));
      expect(parsed.message, equals("Friendly notice message"));
    });
  });
}
