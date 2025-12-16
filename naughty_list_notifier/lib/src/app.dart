import 'package:flutter/material.dart';
import 'package:naughty_list_notifier/src/utils/routing/routing.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Naughty List Notifier',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
    );
  }
}
