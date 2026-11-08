import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immich_mobile/presentation/widgets/tv/tv_photo_actions.dart';
import 'package:immich_mobile/presentation/widgets/tv/tv_album_permissions.dart';

void main() {
  test('albumUsers grants editors writes and keeps viewers read only', () {
    Map<String, dynamic> album(String role) => {
      'ownerId': 'owner',
      'albumUsers': [
        {
          'user': {'id': 'member'},
          'role': role,
        },
      ],
    };
    expect(tvAlbumCanEdit(album('viewer'), 'owner'), isTrue);
    expect(tvAlbumCanEdit(album('editor'), 'member'), isTrue);
    expect(tvAlbumCanEdit(album('viewer'), 'member'), isFalse);
    expect(tvAlbumCanEdit(album('editor'), 'other'), isFalse);
    expect(tvAlbumCanEdit(album('editor'), null), isFalse);
  });
  Future<void> open(
    WidgetTester tester, {
    Future<void> Function()? favorite,
    VoidCallback? rotate,
    Future<List<TvPhotoAction>> Function()? tags,
    Future<List<TvPhotoAction>> Function()? albums,
    Future<List<TvPhotoAction>> Function()? rating,
  }) async {
    tester.view.physicalSize = const Size(960, 540);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showTvPhotoActions(
                context: context,
                details: () async => [const TvPhotoAction('Camera: test', null)],
                albums: albums ?? () async => [const TvPhotoAction('No writable albums', null)],
                tags: tags ?? () async => [],
                rating: rating,
                rotate: rotate ?? () {},
                favorite: favorite,
                isFavorite: false,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('submenu Back stays in panel; outer Back restores photo', (tester) async {
    await open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.text('Camera: test'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Rotate clockwise (display only)'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Photo Actions'), findsNothing);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('opening OK release does not activate Details; rotate stays local', (tester) async {
    var rotations = 0;
    await open(tester, rotate: () => rotations++);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(rotations, 1);
    expect(find.text('Photo Actions'), findsOneWidget);
  });

  testWidgets('favorite failure reports retry without changing favorite label', (tester) async {
    var calls = 0;
    await open(
      tester,
      favorite: () async {
        if (++calls == 1) throw StateError('offline');
      },
    );
    for (var i = 0; i < 4; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not complete action'), findsOneWidget);
    expect(find.text('Add to Favorites'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.text('Remove from Favorites'), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets('long tag lists reach offscreen rows and reload after toggle', (tester) async {
    var selected = false;
    await open(
      tester,
      favorite: () async {},
      tags: () async => List.generate(
        40,
        (i) => TvPhotoAction('Tag $i ${selected ? 'assigned' : 'unassigned'}', () => selected = !selected),
      ),
    );
    for (var i = 0; i < 3; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    for (var i = 0; i < 39; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
    }
    expect(find.text('Tag 39 unassigned'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(selected, isTrue);
    expect(find.text('Tag 39 assigned'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Manage Albums toggles several memberships in place without Done or focus jump', (tester) async {
    final members = <String>{};
    final names = ['Alpha', 'Beta', 'Gamma'];
    var calls = 0;
    await open(
      tester,
      favorite: () async {},
      albums: () async => [
        for (final name in names)
          TvPhotoAction(
            '${members.contains(name) ? '★ ' : ''}$name',
            () async {
              calls++;
              if (!members.add(name)) members.remove(name);
            },
            emphasized: members.contains(name),
          ),
      ],
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.text('Manage Albums'), findsOneWidget);
    // Success feedback may say Done; it must not become a navigation row.
    expect(find.widgetWithText(ListTile, 'Done'), findsNothing);
    expect(find.text('Alpha'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(members, contains('Alpha'));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(members, contains('Beta'));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(members, contains('Gamma'));
    expect(calls, 3);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Photo Actions'), findsOneWidget);
  });

  testWidgets('rating supports five stars and clearing without closing the panel', (tester) async {
    int? value;
    await open(
      tester,
      favorite: () async {},
      rating: () async => [
        for (var stars = 1; stars <= 5; stars++) TvPhotoAction('$stars stars', () => value = stars),
        TvPhotoAction('Clear Rating', () => value = null),
      ],
    );
    for (var i = 0; i < 5; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    for (var i = 0; i < 4; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(value, 5);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(value, isNull);
    expect(find.text('Star Rating'), findsOneWidget);
    expect(find.textContaining('Delete'), findsNothing);
  });

  testWidgets('unsupported mutations remain disabled', (tester) async {
    await open(tester);
    for (var i = 0; i < 6; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.textContaining('Delete'), findsNothing);
    expect(find.text('Photo Actions'), findsOneWidget);
    expect(find.text('Done'), findsNothing);
  });

  testWidgets('tag search isolates typing and Back restores unfiltered menu', (tester) async {
    await open(
      tester,
      favorite: () async {},
      tags: () async => [const TvPhotoAction('Add: Alps', null), const TvPhotoAction('Remove: Beach', null)],
    );
    for (var i = 0; i < 3; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'beach');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('Remove: Beach'), findsOneWidget);
    expect(find.text('Add: Alps'), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Photo Actions'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
