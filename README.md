# Floating Context Menu

A Flutter package that provides a modern, interactive floating context menu inspired by iOS/iPadOS gestures. It features smooth animations, background blurring, and intuitive "hold-and-drag" interactions.

---

## Live Demo

Live demo website: https://floating-context-menu-live-demo.netlify.app/

---

## Preview

![Preview gif](https://raw.githubusercontent.com/TarLeeProject/floating_context_menu/refs/heads/main/example/preview.gif)

---

## Features

*   **Smooth Animations**: High-quality scale and transition animations using CurvedAnimation.
*   **Glassmorphism Effect**: Automatic background blur `BackdropFilter` when the menu is active.
*   **Gesture-Driven**: Supports both `long-press` to trigger and `drag-to-select` interactions.
*   **Highly Customizable**: Use any widget as your menu trigger and provide an `expandedChild` for the active state.
*   **Lightweight**: Minimal dependencies, built primarily with Flutter's core widgets.

---

## Getting started

Add to your `pubspec.yaml`:

```yaml
dependencies:
  floating_context_menu: ^1.0.0
```

Then run:

```bash
flutter pub get
```

---

## Usage

### 1. Wrap your app with `FloatingMenuController`
The `FloatingMenuController` manages the global state and coordinates the overlay animations.

```dart
import 'package:floating_context_menu/floating_context_menu.dart';

void main() {
  runApp(
    MaterialApp(
      home: FloatingMenuController(
        child: MyHomePage(),
      ),
    ),
  );
}
```

### 2. Add `FloatingMenu` to your widgets
Wrap any widget you want to trigger a menu with `FloatingMenu`.

```dart
FloatingMenu(
    tag: 'unique_item_1', // Must be unique
    items: ['Edit', 'Share', 'Delete'],
    onSelected: (index) {
        print('Selected item: $index');
    },
    child: Container(
        padding: EdgeInsets.all(16),
        color: Colors.blue,
        child: Text('Long press me'),
    ),
    expandedChild: Container(
        padding: EdgeInsets.all(16),
        color: Colors.blueAccent,
        child: Text('I am expanded!'),
    ),
)
```