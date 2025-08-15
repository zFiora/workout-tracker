// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:workout_tracker/common/widgets/myCustomeScaffoldView.dart';

class TemplatesPage extends StatelessWidget {
  const TemplatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MyCustomeScaffoldView(
      title: 'Templates',
      body: Column(children: [Text('data')]),
    );
  }
}
