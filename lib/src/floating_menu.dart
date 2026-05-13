import 'package:floating_context_menu/src/floating_menu_controller.dart';
import 'package:flutter/material.dart';

/// A wrapper widget that defines a trigger area for a floating context menu.
///
/// [FloatingMenu] must be a descendant of a [FloatingMenuController].
/// When the user interacts with this widget (via long press or tap managed by
/// the controller), the menu defined by [items] will appear.
///
/// It handles automatic registration and unregistration with the nearest
/// [FloatingMenuControllerState] using the provided [tag].
class FloatingMenu extends StatefulWidget {
  /// Creates a [FloatingMenu].
  ///
  /// * [child]: The primary widget that will be displayed in the UI.
  /// * [expandedChild]: An optional widget that replaces the child when the
  ///   menu is active (e.g., a version of the child with different styling).
  /// * [tag]: A unique identifier for this menu. Must be unique within the
  ///   same [FloatingMenuController].
  /// * [items]: A list of labels for the menu options.
  /// * [onSelected]: Callback triggered when a menu item is selected,
  ///   providing the index of the item.
  const FloatingMenu({
    super.key,
    required this.child,
    this.expandedChild,
    required this.tag,
    this.items = const [],
    this.onSelected,
  });

  /// The widget to be displayed and used as the interaction target.
  final Widget child;

  /// An optional widget to show when the menu is expanded.
  /// If null, the standard [child] is used.
  final Widget? expandedChild;

  /// Unique identifier for this menu instance.
  final String tag;

  /// The list of items to display in the floating menu.
  final List<String> items;

  /// Callback called when an item at a specific index is tapped.
  final void Function(int)? onSelected;

  @override
  State<FloatingMenu> createState() => _FloatingMenuState();
}

class _FloatingMenuState extends State<FloatingMenu> {
  /// GlobalKey used by the controller to calculate the position and size
  /// of this widget on the screen.
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Register the menu with the controller after the first frame is rendered.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _getController()?.register(widget, _key);
      }
    });
  }

  @override
  void dispose() {
    // Ensure the menu is removed from the controller registry when disposed.
    _getController()?.unregister(widget.tag);
    super.dispose();
  }

  /// Helper method to safely access the [FloatingMenuControllerState].
  FloatingMenuControllerState? _getController() {
    return FloatingMenuController.maybeOf(context)
        as FloatingMenuControllerState?;
  }

  @override
  Widget build(BuildContext context) {
    final controller = _getController();

    // Check if this specific menu is currently active.
    final bool isSelected = widget.tag == controller?.selectedTag;

    // Check if this specific menu is currently being pressed down.
    final bool isHolding = widget.tag == controller?.holdingTag;

    return Visibility(
      // Hide the original widget in the list/stack when it's being
      // animated in the overlay center.
      visible: !isSelected,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: Container(
        key: _key,
        child: Transform.scale(
          // Apply the holding scale factor (provided by the controller)
          // to give visual feedback during a tap-down.
          scale: isHolding ? _getController()?.holdingFactor ?? 1 : 1,
          child: widget.child,
        ),
      ),
    );
  }
}
