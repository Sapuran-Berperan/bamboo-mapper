import 'package:drift/drift.dart';

/// Unsupported platform - throws an error
QueryExecutor openConnection() {
  throw UnsupportedError(
    'Platform not supported. This app requires either native (mobile/desktop) or web platform.',
  );
}
