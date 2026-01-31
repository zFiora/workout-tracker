import 'package:flutter/material.dart';

class SimpleCard extends StatelessWidget {
  const SimpleCard({
    super.key,
    required this.title,
    this.value,
    this.valueWidget,
  });

  final String title;
  final String? value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (valueWidget != null)
              valueWidget!
            else
              Text(value ?? "-", style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
