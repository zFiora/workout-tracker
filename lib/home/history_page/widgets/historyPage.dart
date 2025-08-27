import 'package:flutter/material.dart';
import 'package:workout_tracker/common/widgets/myCustomeScaffoldView.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MyCustomeScaffoldView(
      title: 'History',
      body: Center(child: Text('No old sessions')),
    );
  }
}
