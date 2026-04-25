# Hash Generator Provider

## Overview

The Hash Generator provider allows users to generate cryptographic hashes from text input. It supports four hash algorithms: MD5, SHA1, SHA256, and SHA512.

## Features

- Generate MD5, SHA1, SHA256, and SHA512 hashes from text input
- Real-time hash generation as you type
- Copy hash to clipboard with one tap
- Hash generation history (up to 10 entries)
- Tap history entries to reuse previous inputs
- Clear history with confirmation dialog
- Hash length display for each algorithm
- Uses `Card.filled` and `SegmentedButton` for Material 3 style

## Implementation Details

### Provider File

Located at `lib/providers/provider_hash.dart`.

### Model

`HashGeneratorModel` manages the hash generation state:

- `inputText`: The text input to hash
- `outputHash`: The generated hash output
- `mode`: The hash algorithm (md5, sha1, sha256, sha512)
- `history`: List of previous hash generation entries

### Hash Algorithms

- **MD5**: 128-bit hash, 32 character output (not recommended for security purposes)
- **SHA1**: 160-bit hash, 40 character output (deprecated for security purposes)
- **SHA256**: 256-bit hash, 64 character output (recommended for most purposes)
- **SHA512**: 512-bit hash, 128 character output (highest security)

### Dependencies

Uses the `crypto` package for hash generation:
```yaml
crypto: ^3.0.0
```

### Widget

`HashGeneratorCard` provides the UI:
- Header with history toggle button
- SegmentedButton for algorithm selection
- Input TextField for text entry
- Output display with copy button
- Action buttons for clear and save to history
- History section with load and clear options

## Keywords

- hash, md5, sha1, sha256, sha512, generate, digest, checksum, security

## Testing

Tests cover:
- Model initialization and default values
- Hash generation for each algorithm
- Correct hash output verification
- Mode switching
- Input clearing
- History management (add, load, clear, limit)
- Mode label and hash length getters
- Widget rendering and presence
- Provider registration in Global.providerList

## Usage Example

1. Type text in the input field
2. Select desired hash algorithm using SegmentedButton
3. Hash is generated automatically in real-time
4. Copy hash to clipboard using the copy button
5. Save to history for future reference
6. Load previous hashes from history

## Notes

- MD5 and SHA1 are provided for legacy compatibility but not recommended for security purposes
- SHA256 is the default algorithm and recommended for most use cases
- SHA512 provides the highest security level
- Empty input produces empty output
- Hash length is displayed for reference