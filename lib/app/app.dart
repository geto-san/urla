import 'package:flutter/material.dart';
import '../features/camera/view/camera_screen.dart';
import '../features/camera/viewmodel/camera_viewmodel.dart';

class URLAApp extends StatelessWidget {
  final CameraViewModel viewModel;

  const URLAApp({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'URLA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: CameraScreen(viewModel: viewModel),
    );
  }

  
}