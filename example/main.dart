import 'package:floating_context_menu/floating_context_menu.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Floating Context Menu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.blue),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingMenuController(
      child: Scaffold(
        body: Center(
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Tapped on outside'),
              ));
            },
            child: FloatingMenu(
              tag: 'unique_tag',
              items: List.generate(5, (index) => 'Item$index'),
              onSelected: (index) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Tapped on Item$index'),
                  ));
                });
              },
              expandedChild: Container(
                width: 150,
                height: 150,
                color: Colors.red,
                child: Center(child: Text('Block preview')),
              ),
              child: Container(
                width: 150,
                height: 150,
                color: Colors.green,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 8,
                    children: [
                      Text('Block'),
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                              'Tapped on gesture inside',
                            ),
                          ));
                        },
                        child: Center(child: Text('Tappable')),
                      ),
                      FilledButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                              'Tapped on button inside',
                            ),
                          ));
                        },
                        child: Center(child: Text('Button')),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}