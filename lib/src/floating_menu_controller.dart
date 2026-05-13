import 'dart:ui';
import 'package:flutter/material.dart';
import 'animated_components/animated_showing_menu.dart';
import 'animated_components/animated_to_center.dart';
import 'floating_menu.dart';

/// A widget that manages the state and display of floating menus.
///
/// [FloatingMenuController] act as a wrapper for your application or a specific
/// screen area. It handles the gestures (long press, pan, tap) required to
/// trigger and interact with [FloatingMenu] components.
///
/// It uses an [InheritedWidget] to allow descendant [FloatingMenu]s to register
/// themselves and access the controller's state.
class FloatingMenuController extends StatefulWidget {
  /// Creates a [FloatingMenuController].
  ///
  /// The [child] usually contains the rest of your UI where floating menus
  /// are registered.
  ///
  /// It is recommended to wrap it around the [Scaffold].
  const FloatingMenuController({super.key, required this.child});

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  State<FloatingMenuController> createState() => _FloatingMenuControllerState();

  /// Returns the nearest [FloatingMenuControllerState] that encloses the given context.
  ///
  /// Returns null if no [FloatingMenuController] is found.
  static State<FloatingMenuController>? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_FloatingMenuControllerInherited>()
        ?.controllerState;
  }

  /// Returns the nearest [FloatingMenuControllerState] that encloses the given context.
  ///
  /// Throws an assertion error if no [FloatingMenuController] is found.
  static State<FloatingMenuController> of(BuildContext context) {
    final result = maybeOf(context);
    assert(result != null, 'Not found controller');
    return result!;
  }
}

/// Abstract base class for [FloatingMenuController] state.
///
/// This defines the public API that [FloatingMenu] widgets use to communicate
/// with the controller.
abstract class FloatingMenuControllerState
    extends State<FloatingMenuController> {
  /// Registers a [menu] with its corresponding [key] into the controller.
  void register(FloatingMenu menu, GlobalKey key);

  /// Unregisters a menu using its unique [tag].
  void unregister(String tag);

  /// Returns the tag of the currently active/open menu.
  String? get selectedTag;

  /// The tag of the menu currently being "held" (during tap down animation).
  String? holdingTag;

  /// A scale factor applied to the button being pressed.
  double holdingFactor = 1;
}

/// Implementation of [FloatingMenuControllerState].
///
/// Handles the core logic: gesture detection, animation controllers for blur effects,
/// and rendering the floating menu overlays using a [Stack].
class _FloatingMenuControllerState extends FloatingMenuControllerState
    with SingleTickerProviderStateMixin {
  /// Internal registry of all floating menus available in the current context.
  final Map<String, (FloatingMenu menu, GlobalKey key)> _registry = {};

  /// Data of active menus being displayed.
  final Map<String, (FloatingMenu menu, Offset leftTop, Offset rightBottom)>
  _menus = {};

  /// Controller for the press-and-hold (scaling) animation.
  late final AnimationController holdingController;

  /// Animation for the holding scale effect.
  late final Animation<double> holdingTween;

  String? _currentSelectedTag;
  @override
  String? get selectedTag => _currentSelectedTag;

  /// Check if any menu is currently visible.
  bool get _isMenuOpen => _currentSelectedTag != null;

  @override
  void register(FloatingMenu menu, GlobalKey key) =>
      _registry[menu.tag] = (menu, key);

  @override
  void unregister(String tag) => _registry.remove(tag);

  /// Logic for detecting which menu is triggered on long press.
  void _handleLongPress(LongPressStartDetails details) {
    for (final entry in _registry.entries) {
      final context = entry.value.$2.currentContext;
      if (context == null) continue;

      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.attached) continue;

      final offset = renderBox.localToGlobal(Offset.zero);
      final rect = offset & renderBox.size;

      if (rect.contains(details.globalPosition)) {
        setState(() {
          _currentSelectedTag = entry.key;
          _menus[entry.key] = (
            entry.value.$1,
            offset,
            offset + Offset(renderBox.size.width, renderBox.size.height),
          );
          _moving = details.globalPosition;
        });
        break;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    holdingController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 400),
          reverseDuration: const Duration(milliseconds: 400),
        )..addListener(() {
          setState(() {
            holdingFactor = 1 + 0.05 * ((holdingTween.value * 400) / 400);
          });
        });

    holdingTween = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: holdingController, curve: Curves.easeOutQuart),
    );
  }

  Offset? _moving;
  Offset? _tapped;
  int? _hoveringOnIndex;

  (Offset leftTop, Offset rightBottom)? _selectedView;
  (Offset leftTop, Offset rightBottom)? _selectedMenu;

  /// Helper to check if a [touchPoint] is within the bounds of a rectangle.
  bool _isInside(Offset touchPoint, Offset leftTop, Offset rightBottom) {
    final dx = touchPoint.dx;
    final dy = touchPoint.dy;
    return leftTop.dx <= dx &&
        rightBottom.dx >= dx &&
        leftTop.dy <= dy &&
        rightBottom.dy >= dy;
  }

  bool _isClosing = false;

  /// Closes the active menu with a fade-out animation.
  void closeMenu() async {
    holdingController.reset();
    setState(() {
      holdingFactor = 1;
      _isClosing = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _currentSelectedTag = null;
        _isClosing = false;
        _tapped = null;
        _moving = null;
        _hoveringOnIndex = null;
      });
    });
  }

  /// Builds the overlay widgets (Menu items and the central animated component).
  List<Widget> _buildSelectedWidget() {
    return [
      AnimatedShowingMenu(
        items: _menus[_currentSelectedTag]!.$1.items,
        offset: _moving,
        select: _tapped,
        onSelectIndex: (index) {
          if (!_isMenuOpen) return;
          _menus[_currentSelectedTag]?.$1.onSelected?.call(index);
          Future.delayed(const Duration(milliseconds: 100), () {
            closeMenu();
          });
        },
        showed: (view) => _selectedMenu = view,
        onHover: (index) {
          _hoveringOnIndex = index;
        },
        isClosing: _isClosing,
      ),
      AnimatedToCenterWidget(
        left: _menus[_currentSelectedTag]!.$2.dx,
        top: _menus[_currentSelectedTag]!.$2.dy,
        width:
            _menus[_currentSelectedTag]!.$3.dx -
            _menus[_currentSelectedTag]!.$2.dx,
        height:
            _menus[_currentSelectedTag]!.$3.dy -
            _menus[_currentSelectedTag]!.$2.dy,
        showed: (view) => _selectedView = view,
        isClosing: _isClosing,
        expandedChild: _menus[_currentSelectedTag]?.$1.expandedChild,
        menuItems: _menus[_currentSelectedTag]?.$1.items.length ?? 0,
        child: _menus[_currentSelectedTag]!.$1.child,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return _FloatingMenuControllerInherited(
      controllerState: this,
      child: GestureDetector(
        onTapDown: !_isMenuOpen
            ? (details) {
                // Check if the tap down hits any registered menu to start holding animation
                for (final entry in _registry.entries) {
                  final context = entry.value.$2.currentContext;
                  if (context == null) continue;

                  final renderBox = context.findRenderObject() as RenderBox?;
                  if (renderBox == null || !renderBox.attached) continue;

                  final offset = renderBox.localToGlobal(Offset.zero);
                  final rect = offset & renderBox.size;

                  if (rect.contains(details.globalPosition)) {
                    holdingTag = entry.key;
                    holdingController.forward();
                    break;
                  }
                }
              }
            : null,
        onTapUp: !_isMenuOpen
            ? (_) => holdingController.reverse()
            : (details) {
                // Logic to select an item or close menu when tapping
                if (_selectedView != null) {
                  if (_isInside(
                    details.globalPosition,
                    _selectedView!.$1,
                    _selectedView!.$2,
                  )) {
                    return;
                  }
                }

                if (_selectedMenu != null) {
                  if (_isInside(
                    details.globalPosition,
                    _selectedMenu!.$1,
                    _selectedMenu!.$2,
                  )) {
                    setState(() {
                      _tapped = details.globalPosition;
                    });
                    return;
                  }
                }
                closeMenu();
              },
        onTapCancel: !_isMenuOpen ? () => holdingController.reverse() : null,
        onPanUpdate: (details) {
          if (!_isMenuOpen) return;
          setState(() {
            _moving = details.globalPosition;
          });
        },
        onPanEnd: (details) {
          if (_selectedMenu != null) {
            if (_isInside(
              details.globalPosition,
              _selectedMenu!.$1,
              _selectedMenu!.$2,
            )) {
              setState(() {
                _tapped = details.globalPosition;
              });
              return;
            }
          }
        },
        onLongPressStart: !_isMenuOpen ? _handleLongPress : null,
        onLongPressMoveUpdate: (details) {
          if (!_isMenuOpen) return;
          setState(() {
            _moving = details.globalPosition;
          });
        },
        onLongPressEnd: (details) {
          if (!_isMenuOpen) return;
          if (_hoveringOnIndex != null) {
            _menus[_currentSelectedTag]?.$1.onSelected?.call(_hoveringOnIndex!);
            closeMenu();
          }
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Positioned.fill(child: widget.child),
              if (_isMenuOpen) ...[
                // Overlay background with blur effect
                Positioned.fill(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 400),
                    opacity: _isClosing ? 0.0 : 1.0,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(51),
                        ),
                      ),
                    ),
                  ),
                ),
                ..._buildSelectedWidget(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Internal [InheritedWidget] to provide [FloatingMenuControllerState] to descendants.
class _FloatingMenuControllerInherited extends InheritedWidget {
  /// The state of the controller.
  final _FloatingMenuControllerState controllerState;

  const _FloatingMenuControllerInherited({
    required this.controllerState,
    required super.child,
  });

  @override
  bool updateShouldNotify(_FloatingMenuControllerInherited oldWidget) {
    return true;
  }
}
