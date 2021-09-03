import 'package:flutter/material.dart';
import 'package:soundpool_example/platform/ios_options.dart';

class PlatformOptions extends StatelessWidget {
  const PlatformOptions({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    if (TargetPlatform.iOS == platform) {
      return IosOptionsSelector();
    }
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.handyman_outlined),
            SizedBox(height: 4),
            Text('Work in progress'),
          ],
        ),
      ),
    );
  }
}
