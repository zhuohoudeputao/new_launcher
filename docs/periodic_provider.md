# PeriodicTable Provider

## Overview

The PeriodicTable provider provides a comprehensive reference of all 118 chemical elements. It displays element data including atomic number, symbol, name, atomic mass, category, electron configuration, and discovery year for synthetic elements.

## Implementation

### File Location
`lib/providers/provider_periodic.dart`

### Provider Definition
```dart
MyProvider providerPeriodicTable = MyProvider(
    name: "PeriodicTable",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);
```

### Model Class
`PeriodicTableModel` extends `ChangeNotifier` and manages:
- Search query for filtering elements
- Selected element detail view
- Category filtering
- Clipboard copy functionality

### Element Data
`ChemicalElement` class contains:
- `atomicNumber`: Element's atomic number (1-118)
- `symbol`: Chemical symbol (H, He, Li, etc.)
- `name`: Full element name
- `atomicMass`: Atomic mass value
- `category`: Element category enum
- `group`: Periodic table group (optional)
- `period`: Periodic table period
- `electronConfiguration`: Electron configuration string
- `discoveryYear`: Discovery year for synthetic elements (optional)

### Element Categories
11 element categories:
- **Alkali Metal**: Li, Na, K, Rb, Cs, Fr
- **Alkaline Earth Metal**: Be, Mg, Ca, Sr, Ba, Ra
- **Transition Metal**: Fe, Cu, Ag, Au, Pt, etc.
- **Post-Transition Metal**: Al, Ga, In, Sn, Tl, Pb, Bi
- **Metalloid**: B, Si, Ge, As, Sb, Te, Po
- **Nonmetal**: H, C, N, O, P, S, Se
- **Halogen**: F, Cl, Br, I, At
- **Noble Gas**: He, Ne, Ar, Kr, Xe, Rn
- **Lanthanide**: La-Lu (57-71)
- **Actinide**: Ac-Lr (89-103)
- **Unknown**: Mt, Ds, Rg, Cn, Nh, Fl, Mc, Lv, Ts, Og

### Features
1. **Search**: Filter elements by name, symbol, or atomic number
2. **Category Filter**: ActionChips for quick category filtering
3. **Grid View**: Display elements in a 6-column grid (first 36 elements)
4. **Detail View**: Tap an element to see full information
5. **Copy Info**: Copy element info to clipboard

### UI Components
- `PeriodicTableCard`: Main widget displaying the reference
- Search field with clear button
- Category filter ActionChips
- GridView for element display
- Detail view with complete element information

### Color Coding
Each category has a distinct color:
- Alkali Metal: Light Red (0xFFE57373)
- Alkaline Earth Metal: Light Orange (0xFFFFB74D)
- Transition Metal: Light Blue (0xFF64B5F6)
- Post-Transition Metal: Light Cyan (0xFF4DD0E1)
- Metalloid: Light Green (0xFF81C784)
- Nonmetal: Light Lime (0xFFAED581)
- Halogen: Light Coral (0xFFFF8A65)
- Noble Gas: Light Purple (0xFFBA68C8)
- Lanthanide: Light Yellow (0xFFFFF176)
- Actinide: Light Pink (0xFFF48FB1)
- Unknown: Surface color

### Keywords
`periodic table element chemistry atomic science`

### Material 3 Components
- `Card.filled` for main container
- `ActionChip` for category filtering
- `TextField` with search decoration
- `GridView` for element grid
- `SelectableText` for electron configuration

## Usage

The Periodic Table reference appears as an info widget in the main card list. Users can:
1. Search for specific elements
2. Filter by category
3. Tap elements to view details
4. Copy element information to clipboard