// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:workout_tracker/common/widgets/myCustomeScaffoldView.dart';

class MeasuresPage extends StatelessWidget {
  const MeasuresPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MyCustomeScaffoldView(
      title: 'Measures',
      body: Column(children: [Text('data')]),
    );
  }
}
