import 'package:flutter/material.dart';
import 'package:seelai_app/shared/widgets/vista_loader.dart';

class AppLoadingPage extends StatelessWidget {
  const AppLoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: VistaLoader(size: 120)));
  }
}
