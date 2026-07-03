// ignore_for_file: file_names
import 'package:flutter/material.dart';

/// Shared page scaffold: flat surface app bar with a bold Space Grotesk
/// title, safe-area body and optional pull-to-refresh.
class MyCustomeScaffoldView extends StatefulWidget {
  final String? title;
  final Widget body;
  final bool showAppBar;
  final bool showNavigationBar;
  final bool isMainPage;
  final Color? appBarColor;
  final Color? backgroundColor;
  final bool enableRefresh;
  final Future<void> Function()? onRefresh;
  final PreferredSizeWidget? customAppBar;
  final Widget? navigationBar;

  const MyCustomeScaffoldView({
    super.key,
    this.title = "",
    required this.body,
    this.showAppBar = true,
    this.showNavigationBar = true,
    this.isMainPage = false,
    this.appBarColor,
    this.backgroundColor,
    this.enableRefresh = false,
    this.onRefresh,
    this.customAppBar,
    this.navigationBar,
  });

  @override
  State<StatefulWidget> createState() {
    return _MyCustomeScaffoldView();
  }
}

class _MyCustomeScaffoldView extends State<MyCustomeScaffoldView> {
  final Key _pageKey = UniqueKey();

  Future<void> _refresh() async {
    if (widget.onRefresh != null) {
      await widget.onRefresh!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldBackground =
        widget.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor;

    Widget pageBody = widget.enableRefresh
        ? RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: widget.body,
            ),
          )
        : widget.body;

    return Scaffold(
      key: _pageKey,
      backgroundColor: scaffoldBackground,
      appBar: widget.showAppBar
          ? (widget.customAppBar ??
                AppBar(
                  title: Text(widget.title ?? ""),
                  centerTitle: true,
                  backgroundColor: widget.appBarColor ?? scaffoldBackground,
                  automaticallyImplyLeading: !widget.isMainPage,
                ))
          : null,
      body: SafeArea(child: pageBody),
      bottomNavigationBar: widget.showNavigationBar
          ? widget.navigationBar
          : null,
    );
  }
}
