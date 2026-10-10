import 'package:flutter/material.dart';

class PrivacyShield extends StatefulWidget {
  const PrivacyShield({required this.child, super.key});
  final Widget child;
  @override
  State<PrivacyShield> createState() => _PrivacyState();
}

class _PrivacyState extends State<PrivacyShield> with WidgetsBindingObserver {
  bool hidden = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Android native map surfaces may take window focus while the activity is
    // still visible. FLAG_SECURE protects its recents snapshot at the OS level.
    final nativeFocus =
        Theme.of(context).platform == TargetPlatform.android &&
        state == AppLifecycleState.inactive;
    if (mounted) {
      setState(
        () => hidden = state != AppLifecycleState.resumed && !nativeFocus,
      );
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      widget.child,
      if (hidden)
        Positioned.fill(
          child: ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: const Center(child: Icon(Icons.pets_outlined, size: 48)),
          ),
        ),
    ],
  );
}
