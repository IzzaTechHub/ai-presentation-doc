# Error Handling & Exception Architecture

## Overview
Prior to this release, raw exceptions (`SocketException`, `ClientException`, `FormatException`) and server responses were passed directly into UI `Text` widgets or dialog contents. This led to internal URLs (`https://ai-presentation-backend.vercel.app`), raw JSON payloads, and stack traces leaking into user-facing alerts.

The new architecture implements a strict **Shielded Error Boundary** where all external network calls, parsing operations, and file storage actions are intercepted, sanitized, and transformed into clear, human-friendly messages with contextual actions (Retry / Dismiss).

---

## 1. Core Components

### `AppException` ([lib/services/app_exception.dart](file:///e:/Abdulrahman/imagineX/lib/services/app_exception.dart))
A typed model categorizing all system errors:
- `network`: Offline, host lookup failed, connection reset.
- `timeout`: Server request exceeded duration threshold.
- `server`: 5xx, 502, 503, 504 gateway or AI server errors.
- `client`: 400 bad request, empty input, missing parameters.
- `rateLimit`: 429 too many requests.
- `parse`: Malformed JSON or unexpected non-JSON response format.
- `storage`: File writing or permission constraints.
- `unknown`: Safe generic fallback.

### `ErrorHandler` ([lib/services/error_handler.dart](file:///e:/Abdulrahman/imagineX/lib/services/error_handler.dart))
Central parser and sanitizer:
- **Zero URL Leakage Guarantee:** Strips all `http://`, `https://`, domain names, port numbers, and endpoint paths.
- **Zero JSON Leakage Guarantee:** Filters out any strings containing JSON brackets, keys, or technical symbols.
- **Debug-Only Logging:** Emits raw diagnostics exclusively via `debugPrint` in `kDebugMode`.

### `AppErrorDialog` ([lib/widgets/app_error_dialog.dart](file:///e:/Abdulrahman/imagineX/lib/widgets/app_error_dialog.dart))
Elevated modal interface featuring:
- Category vector iconography (`Icons.wifi_off_rounded`, `Icons.timer_outlined`, `Icons.cloud_off_rounded`).
- Editorial white surface with subtle dual-layer elevation.
- Clear title and human-friendly explanation.
- Contextual "Try Again" and "Dismiss" buttons with spring haptic feedback.

### `AppSnackBar` ([lib/widgets/app_snackbar.dart](file:///e:/Abdulrahman/imagineX/lib/widgets/app_snackbar.dart))
Floating capsule toast banner replacing standard raw snackbars across the app.

---

## 2. Network Timeouts in `ApiService`

All outbound requests now enforce safe timeouts to prevent infinite loading spinners:

| Operation | Timeout Duration | Fallback Handling |
| :--- | :--- | :--- |
| `fetchTemplates()` | 15 seconds | Displays retry card with network vector icon |
| `perfectPrompt()` | 20 seconds | Shows clean toast: "The server took too long to respond." |
| `generateSlides()` | 45 seconds | Dismisses loader and launches `AppErrorDialog` with Retry |
| `generatePPTX()` | 40 seconds | Dismisses compiler overlay and launches `AppErrorDialog` |

---

## 3. Test Coverage
Exhaustive unit test suite in [test/error_handler_test.dart](file:///e:/Abdulrahman/imagineX/test/error_handler_test.dart) verifies:
1. `SocketException` mapping without host leakage.
2. `TimeoutException` mapping.
3. `FormatException` sanitization (HTML/Bad Request payloads).
4. Server 504 Gateway Timeout sanitization.
5. Rate limit 429 mapping.
6. JSON leak prevention (zero brackets or internal paths).
7. Pass-through for existing typed `AppException`.

**Test Status:** 7/7 tests passing (`flutter test` exit code 0).
