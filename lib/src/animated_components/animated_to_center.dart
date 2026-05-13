import 'package:flutter/material.dart';

class AnimatedToCenterWidget extends StatefulWidget {
  final Widget child;
  final Widget? expandedChild;
  final double left;
  final double top;
  final double width;
  final double height;
  final void Function((Offset leftTop, Offset rightBottom))? showed;
  final bool isClosing;
  final int menuItems;

  const AnimatedToCenterWidget({
    super.key,
    required this.child,
    this.expandedChild,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    this.showed,
    this.isClosing = false,
    required this.menuItems,
  });

  @override
  State<AnimatedToCenterWidget> createState() => _AnimatedToCenterWidgetState();
}

class _AnimatedToCenterWidgetState extends State<AnimatedToCenterWidget> {
  late double _left;
  late double _top;
  late double _width;
  late double _height;
  double _scale = 1.05;
  double _expandedOpacity = 0;

  double _menuHeightView = 0;

  @override
  void initState() {
    _left = widget.left;
    _top = widget.top;
    _width = widget.width;
    _height = widget.height;
    _menuHeightView = (widget.menuItems * 46) + 32 + 16;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.sizeOf(context);
      setState(() {
        _left = 32;
        _top = 32;
        _width = size.width - 64;
        _height = size.height - _menuHeightView - 32;

        _expandedOpacity = 1;
      });
      widget.showed?.call((
        Offset(_left, _top),
        Offset(_left + _width, _top + _height),
      ));
    });

    super.initState();
  }

  @override
  void didUpdateWidget(AnimatedToCenterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isClosing && !oldWidget.isClosing) {
      setState(() {
        _left = widget.left;
        _top = widget.top;
        _width = widget.width;
        _height = widget.height;
        _scale = 1;
        _expandedOpacity = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedPositioned(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutQuart,
          left: _left,
          top: _top,
          width: _width,
          height: _height,
          child: AnimatedScale(
            scale: _scale,
            duration: const Duration(milliseconds: 500),
            child: widget.child,
          ),
        ),
        if (widget.expandedChild != null)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOutQuart,
            left: _left,
            top: _top,
            width: _width,
            height: _height,
            child: AnimatedOpacity(
              opacity: _expandedOpacity,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOutQuart,
              child: AnimatedScale(
                scale: _scale,
                curve: Curves.easeInOutQuart,
                duration: const Duration(milliseconds: 500),
                child: widget.expandedChild,
              ),
            ),
          ),
      ],
    );
  }
}
