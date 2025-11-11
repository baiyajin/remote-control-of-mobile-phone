import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/device_list_screen.dart';
import 'services/device_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DeviceService()),
      ],
      child: MaterialApp(
        title: '远程控制',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const DeviceListScreen(),
      ),
    );
  }
}
