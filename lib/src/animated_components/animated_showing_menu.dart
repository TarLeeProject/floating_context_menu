import 'package:flutter/material.dart';

class AnimatedShowingMenu extends StatefulWidget {
  final List<String> items;
  final Offset? offset;
  final Offset? select;
  final void Function(int?) onHover;
  final void Function(int) onSelectIndex;
  final void Function((Offset leftTop, Offset rightBottom))? showed;
  final bool isClosing;

  const AnimatedShowingMenu({
    super.key,
    required this.items,
    this.offset,
    required this.onHover,
    this.showed,
    this.select,
    required this.onSelectIndex,
    this.isClosing = false,
  });

  @override
  State<AnimatedShowingMenu> createState() => _AnimatedShowingMenuState();
}

class _AnimatedShowingMenuState extends State<AnimatedShowingMenu> {
  final _viewKey = GlobalKey();
  final _menuItemHeight = 46.0;

  late double _heightView;
  double _top = -1;
  bool _show = false;

  int? _selectedIndex;

  final List<GlobalKey> _keys = [];
  final Map<int, (Offset leftTop, Offset rightBottom)> _bounds = {};

  @override
  void didUpdateWidget(AnimatedShowingMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isClosing && !oldWidget.isClosing && widget.isClosing) {
      setState(() {
        _show = false;
      });
    }

    if (widget.select != null && oldWidget.select != widget.select) {
      int? index;
      for (final entry in _bounds.entries) {
        final dx = widget.select?.dx ?? -1;
        final dy = widget.select?.dy ?? -1;
        final left = entry.value.$1.dx;
        final top = entry.value.$1.dy;
        final right = entry.value.$2.dx;
        final bottom = entry.value.$2.dy;
        if (left <= dx && right >= dx && top <= dy && bottom >= dy) {
          index = entry.key;
          break;
        }
      }
      widget.onSelectIndex.call(index ?? 0);
      return;
    }
    if (widget.offset != null && oldWidget.offset != widget.offset) {
      _calculateSelection();
    }
  }

  void _calculateSelection() {
    int? index;
    for (final entry in _bounds.entries) {
      final dx = widget.offset?.dx ?? -1;
      final dy = widget.offset?.dy ?? -1;
      final left = entry.value.$1.dx;
      final top = entry.value.$1.dy;
      final right = entry.value.$2.dx;
      final bottom = entry.value.$2.dy;
      if (left <= dx && right >= dx && top <= dy && bottom >= dy) {
        index = entry.key;
        break;
      }
    }
    setState(() {
      _selectedIndex = index;
    });
    widget.onHover.call(index);
  }

  void _updateShow() {
    final viewBox = _viewKey.currentContext?.findRenderObject() as RenderBox?;
    if (viewBox != null) {
      final Offset offset = viewBox.localToGlobal(Offset.zero);
      final Size size = viewBox.size;
      final left = offset.dx;
      final top = offset.dy;
      final right = left + size.width;
      final bottom = top + size.height;
      widget.showed?.call((Offset(left, top), Offset(right, bottom)));
    }
    for (final item in widget.items) {
      final index = widget.items.indexOf(item);
      final box = _keys[index].currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        final Offset offset = box.localToGlobal(Offset.zero);
        final Size size = box.size;
        final left = offset.dx;
        final top = offset.dy;
        final right = left + size.width;
        final bottom = top + size.height;
        _bounds[index] = (Offset(left, top), Offset(right, bottom));
      }
    }
  }

  @override
  void initState() {
    _keys.addAll(widget.items.map<GlobalKey>((_) => GlobalKey()).toList());
    _heightView = _menuItemHeight * widget.items.length;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        final size = MediaQuery.sizeOf(context);
        _top = size.height - _heightView - 16;
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        setState(() {
          _show = true;
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          _updateShow();
        });
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_top == -1) {
      return SizedBox.shrink();
    }
    return Stack(
      children: [
        AnimatedPositioned(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutQuart,
          left: 16,
          top: _top,
          child: AnimatedOpacity(
            opacity: _show ? 1 : 0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOutQuart,
            child: AnimatedContainer(
              key: _viewKey,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOutQuart,
              width: _show ? 200 : 0,
              height: _show ? _heightView : 0,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SingleChildScrollView(
                  child: Column(
                    children: widget.items
                        .map(
                          (title) => Container(
                            key: _keys[widget.items.indexOf(title)],
                            height: _menuItemHeight,
                            color: widget.items.indexOf(title) == _selectedIndex
                                ? Colors.black12
                                : null,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(title),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
