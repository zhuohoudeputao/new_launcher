# Hash Generator Provider Implementation

## Overview

The Hash Generator provider generates cryptographic hashes from text input.

## Provider Details

- **Provider Name**: HashGenerator
- **Keywords**: hash, md5, sha1, sha256, sha512, generate, digest, checksum, security
- **Model**: hashGeneratorModel

## Supported Hash Algorithms

| Algorithm | Bits | Output Length | Security |
|-----------|------|---------------|----------|
| MD5 | 128 | 32 chars | Deprecated |
| SHA1 | 160 | 40 chars | Deprecated |
| SHA256 | 256 | 64 chars | Recommended |
| SHA512 | 512 | 128 chars | Strong |

## Features

- Real-time hash generation as you type
- SegmentedButton for algorithm selection
- Copy hash to clipboard with one tap
- Hash generation history (up to 10 entries)
- Tap history entries to reuse previous inputs
- Clear history with confirmation dialog

## Model (HashGeneratorModel)

```dart
class HashGeneratorModel extends ChangeNotifier {
  String _input = '';
  String _algorithm = 'SHA256';
  String _output = '';
  final List<HashHistoryEntry> _history = [];
  static const int maxHistory = 10;
  
  void setInput(String value);
  void setAlgorithm(String algorithm);
  void _generateHash();
  void addToHistory();
  void clearHistory();
  void useHistoryEntry(HashHistoryEntry entry);
}
```

## Hash Generation

Uses `crypto` package:
```dart
import 'package:crypto/crypto.dart';
import 'dart:convert';

// MD5
final hash = md5.convert(utf8.encode(input));

// SHA256
final hash = sha256.convert(utf8.encode(input));
```

## Widget (HashGeneratorCard)

- Card.filled style
- SegmentedButton for algorithm selection
- TextField for input text
- SelectableText for hash output
- Copy button
- History toggle view

## Testing

Tests verify:
- Provider existence in Global.providerList
- Keywords matching
- Model initialization and state
- Hash generation (MD5, SHA1, SHA256, SHA512)
- History operations
- Widget rendering

## Related Files

- `lib/providers/provider_hash.dart` - Provider implementation