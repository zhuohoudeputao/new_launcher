# IPCalculator Provider Implementation

## Overview

The IPCalculator provider provides IP address and subnet calculations for network administrators and developers.

## Implementation Details

### Location
- Provider file: `lib/providers/provider_ipcalculator.dart`
- Model: `IPCalculatorModel` (ChangeNotifier)
- Widget: `IPCalculatorCard`

### Features

1. **IP Address Input and Validation**
   - IPv4 address input with validation
   - CIDR notation input (0-32)
   - Invalid IP detection

2. **Subnet Calculations**
   - Subnet mask calculation (decimal and binary format)
   - Network address calculation
   - Broadcast address calculation

3. **Host Information**
   - First usable host address
   - Last usable host address
   - Number of usable hosts

4. **IP Classification**
   - IP address class determination (A, B, C, D, E)
   - IP address type detection (Private, Public, Loopback, Reserved)

5. **History Management**
   - Save calculations to history (up to 10 entries)
   - Load previous calculations from history
   - Clear history with confirmation dialog

### Model Properties

```dart
class IPCalculatorModel extends ChangeNotifier {
  String ipAddress;              // Current IP address
  int cidr;                      // Current CIDR notation
  bool isValidIP;                // IP validation status
  bool isValidCIDR;              // CIDR validation status
  
  // Calculated values (computed properties)
  String subnetMaskDecimal;      // Subnet mask in decimal
  String subnetMaskBinary;       // Subnet mask in binary
  String networkAddressDecimal;  // Network address
  String broadcastAddressDecimal; // Broadcast address
  String firstUsableHostDecimal; // First usable host
  String lastUsableHostDecimal;  // Last usable host
  int numberOfHosts;             // Number of usable hosts
  String ipClass;                // IP class (A, B, C, D, E)
  String ipType;                 // IP type (Private, Public, etc.)
  
  // History
  List<IPCalculationHistory> history;
  bool hasHistory;
}
```

### Model Methods

```dart
void init()                     // Initialize model
void setIPAddress(String ip)    // Set IP address
void setCIDR(int value)         // Set CIDR notation (0-32)
void addToHistory()             // Save current calculation to history
void applyFromHistory(entry)    // Load calculation from history
void clearHistory()             // Clear all history
void refresh()                  // Notify listeners
```

### IP Address Calculations

#### Subnet Mask
- Formula: `(0xFFFFFFFF << (32 - cidr)) & 0xFFFFFFFF`
- Example: CIDR 24 → 255.255.255.0

#### Network Address
- Formula: `ipAsInt & subnetMask`
- Example: 192.168.1.100/24 → 192.168.1.0

#### Broadcast Address
- Formula: `networkAddress | (~subnetMask & 0xFFFFFFFF)`
- Example: 192.168.1.100/24 → 192.168.1.255

#### Usable Hosts
- Formula: `(1 << (32 - cidr)) - 2` (for CIDR < 31)
- Example: CIDR 24 → 254 hosts

### IP Class Determination

| First Octet Range | Class |
|-------------------|-------|
| 0-127             | A |
| 128-191           | B |
| 192-223           | C |
| 224-239           | D (Multicast) |
| 240-255           | E (Reserved) |

### IP Type Detection

| IP Range | Type |
|----------|------|
| 10.0.0.0/8 | Private |
| 172.16.0.0/12 | Private |
| 192.168.0.0/16 | Private |
| 127.0.0.0/8 | Loopback |
| 0.0.0.0/8 | This Network |
| 224.0.0.0/4 | Multicast |
| 240.0.0.0/4 | Reserved |
| Others | Public |

### UI Components

- `IPCalculatorCard`: Main widget with Card.filled style
- `_buildInputSection`: IP address and CIDR input fields
- `_buildResultsSection`: Calculation results display
- `_buildHistorySection`: History chips with clear option

### Keywords

```
ip, calculator, subnet, network, cidr, mask, broadcast, host, address, ipv4
```

## Testing

Tests are located in `test/widget_test.dart` under the `IPCalculator provider tests` group:

1. **Model Tests**
   - Initialization test
   - setIPAddress functionality
   - setCIDR functionality with boundary checking
   - IP address validation
   - Subnet mask calculation
   - Network address calculation
   - Broadcast address calculation
   - Usable hosts calculation
   - IP class determination
   - IP type determination

2. **History Tests**
   - History operations (add, clear)
   - Max history limit enforcement
   - Apply from history functionality

3. **Widget Tests**
   - IPCalculatorCard renders correctly
   - Provider inclusion in Global.providerList

## Usage Examples

### Basic Subnet Calculation
```
IP: 192.168.1.100/24
Subnet Mask: 255.255.255.0
Network: 192.168.1.0
Broadcast: 192.168.1.255
First Host: 192.168.1.1
Last Host: 192.168.1.254
Hosts: 254
```

### Private Network Detection
```
IP: 10.0.0.1/8
Type: Private
Class: A
```

### Small Network
```
IP: 192.168.1.1/30
Hosts: 2
First Host: 192.168.1.1
Last Host: 192.168.1.2
```

## Integration

The provider is registered in:
1. `lib/data.dart`: Added to `Global.providerList`
2. `lib/main.dart`: Added to `MultiProvider` providers

## Material 3 Compliance

- Uses `Card.filled` for main container
- Uses `Theme.of(context).cardColor` for transparency support
- Uses `ColorScheme` properties for consistent styling
- Text styling follows Material 3 typography guidelines
- Input fields use `OutlineInputBorder` decoration
- Action chips for history items