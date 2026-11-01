import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immich_mobile/presentation/widgets/tv/tv_build_identity.dart';

// Run with the explicit TV_BRANCH, TV_COMMIT and TV_BUILD defines in the TV workflow.
void main() {
  testWidgets('TV build visibly identifies branch, run and source revision', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: TvBuildIdentity())));
    expect(find.text('TV r42 • feature/test • 0123456789ab'), findsOneWidget);
  });
}
