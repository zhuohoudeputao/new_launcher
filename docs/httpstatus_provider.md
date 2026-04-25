# HTTPStatus Provider

## Overview

The HTTPStatus provider provides a comprehensive reference of HTTP status codes for developers. It displays all standard HTTP status codes with their names, descriptions, and categories.

## Implementation

### File Location
`lib/providers/provider_httpstatus.dart`

### Provider Definition
```dart
MyProvider providerHTTPStatus = MyProvider(
    name: "HTTPStatus",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);
```

### Model Class
`HTTPStatusModel` extends `ChangeNotifier` and manages:
- Search query for filtering codes
- Selected code detail view
- Category filtering (1xx, 2xx, 3xx, 4xx, 5xx)
- Clipboard copy functionality

### Status Code Data
`HTTPStatusCode` class contains:
- `code`: HTTP status code number (e.g., 200, 404, 500)
- `name`: Official name (e.g., "OK", "Not Found")
- `description`: Detailed explanation of the status
- `category`: Category enum (informational, success, redirect, clientError, serverError)

### Categories
The provider includes 63 HTTP status codes across 5 categories:
- **Informational (1xx)**: 100-103 (Continue, Switching Protocols, etc.)
- **Success (2xx)**: 200-226 (OK, Created, No Content, etc.)
- **Redirect (3xx)**: 300-308 (Multiple Choices, Moved Permanently, etc.)
- **Client Error (4xx)**: 400-451 (Bad Request, Unauthorized, Forbidden, Not Found, etc.)
- **Server Error (5xx)**: 500-511 (Internal Server Error, Bad Gateway, etc.)

### Features
1. **Search**: Filter codes by number, name, or description
2. **Category Filter**: ActionChips for quick category filtering
3. **Detail View**: Tap a code to see full description
4. **Copy Info**: Copy code info to clipboard

### UI Components
- `HTTPStatusCard`: Main widget displaying the reference
- Search field with clear button
- Category filter ActionChips
- Code list with ListTile items
- Detail view with full code information

### Color Coding
Each category has a distinct color:
- Informational: Light Blue (0xFF90CAF9)
- Success: Light Green (0xFFA5D6A7)
- Redirect: Light Yellow (0xFFFFE082)
- Client Error: Light Red (0xFFEF9A9A)
- Server Error: Light Purple (0xFFCE93D8)

### Keywords
`http status code response error web server api rest`

### Material 3 Components
- `Card.filled` for main container
- `ActionChip` for category filtering
- `TextField` with search decoration
- `ListTile` for code items
- `SelectableText` for description

## Usage

The HTTP Status reference appears as an info widget in the main card list. Users can:
1. Search for specific codes
2. Filter by category
3. Tap codes to view details
4. Copy code information to clipboard