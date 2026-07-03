import 'package:flutter/material.dart';
import 'myCustomTextField.dart';

class MyCustomSearchField extends StatelessWidget {
  final Function(String) onChanged;

  const MyCustomSearchField({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return MyCustomTextField(
      hint: "Search exercises",
      icon: Icons.search_rounded,
      onChanged: onChanged,
    );
  }
}
