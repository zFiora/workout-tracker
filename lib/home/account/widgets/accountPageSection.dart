import 'package:flutter/material.dart';
import 'package:workout_tracker/common/widgets/uiKit.dart';

class AccountPageSection extends StatelessWidget {
  const AccountPageSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: title,
            padding: const EdgeInsets.only(left: 2, bottom: 8),
          ),
          // Even 10px gaps between tiles; spacing lives here rather than on
          // each tile's Card margin so every section aligns identically.
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            children[i],
          ],
        ],
      ),
    );
  }
}
