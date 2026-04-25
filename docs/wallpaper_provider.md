# Wallpaper Provider Implementation

## Overview

The Wallpaper provider manages the background image displayed in the launcher, supporting both network images and local image selection.

## Provider Details

- **Provider Name**: Wallpaper
- **Keywords**: wallpaper background image
- **Settings Keys**: `Wallpaper.Enabled`, `WallpaperPicker`
- **Model**: BackgroundImageModel (in data.dart)

## Features

### Background Image Management

- Default background: Network image from picsum.photos
- Custom background: Local image from device gallery
- Transparent background support for testing

### WallpaperPickerButton

Located in Settings provider, allows users to:
- Pick custom image from device
- Reset to default network image

## Implementation

### Provider Structure

```dart
MyProvider providerWallpaper = MyProvider(
    name: "Wallpaper",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);
```

### BackgroundImageModel

```dart
class BackgroundImageModel with ChangeNotifier {
  ImageProvider _backgroundImage = NetworkImage("https://picsum.photos/1920/1080");
  
  ImageProvider get backgroundImage => _backgroundImage;
  
  set backgroundImage(ImageProvider value) {
    _backgroundImage = value;
    notifyListeners();
  }
}
```

### Image Picker Integration

Uses `image_picker` package for local image selection:
- `ImagePicker.pickImage(source: ImageSource.gallery)`
- Supports JPEG and PNG formats

### WallpaperPickerButton Widget

```dart
class WallpaperPickerButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card.filled(
      color: Theme.of(context).cardColor,
      child: IconButton(
        icon: Icon(Icons.image),
        onPressed: _pickImage,
        tooltip: "Pick background image",
      ),
    );
  }
}
```

## Background Display

The background is displayed in `MyHomePage`:

```dart
Stack(fit: StackFit.expand, children: <Widget>[
  Consumer<BackgroundImageModel>(
    builder: (context, BackgroundImageModel background, child) {
      return Image(
        image: context.watch<BackgroundImageModel>().backgroundImage,
        fit: BoxFit.cover);
    }),
  Scaffold(...)
])
```

## Testing

- Test assets use `test_assets/transparent.png`
- Mock background image in test setup
- BackgroundImageModel notifyListeners tests

## Related Files

- `lib/providers/provider_wallpaper.dart` - Provider implementation
- `lib/data.dart` - BackgroundImageModel
- `lib/main.dart` - Background display in Stack
- `lib/providers/provider_settings.dart` - WallpaperPickerButton