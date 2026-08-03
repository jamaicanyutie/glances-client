import 'package:flutter_test/flutter_test.dart';

import 'package:glances_client/config/server_config.dart';

void main() {
  group('ServerConfig.normalize', () {
    test('adds http:// to a bare hostname', () {
      expect(
        ServerConfig.normalize('glances.example.com'),
        'http://glances.example.com',
      );
    });

    test('adds http:// to a bare ip:port', () {
      expect(ServerConfig.normalize('192.168.1.10:61208'), 'http://192.168.1.10:61208');
    });

    test('keeps an explicit https:// scheme', () {
      expect(
        ServerConfig.normalize('https://glances.example.com'),
        'https://glances.example.com',
      );
    });

    test('keeps an explicit http:// scheme', () {
      expect(ServerConfig.normalize('http://192.168.1.10:61208'), 'http://192.168.1.10:61208');
    });

    test('strips trailing slashes', () {
      expect(
        ServerConfig.normalize('https://glances.example.com///'),
        'https://glances.example.com',
      );
    });

    test('trims surrounding whitespace', () {
      expect(
        ServerConfig.normalize('  glances.example.com  '),
        'http://glances.example.com',
      );
    });
  });

  group('ServerConfig.validate', () {
    test('rejects empty input', () {
      expect(ServerConfig.validate(''), isNotNull);
      expect(ServerConfig.validate('   '), isNotNull);
    });

    test('accepts a bare hostname', () {
      expect(ServerConfig.validate('glances.example.com'), isNull);
    });

    test('accepts https:// host', () {
      expect(ServerConfig.validate('https://glances.example.com'), isNull);
    });

    test('accepts ip:port', () {
      expect(ServerConfig.validate('192.168.1.10:61208'), isNull);
    });

    test('rejects a non-http(s) scheme', () {
      expect(ServerConfig.validate('ftp://glances.example.com'), isNotNull);
    });
  });
}
