import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:immich_mobile/presentation/widgets/tv/tv_session_catalog.dart';

void main() {
  test('one dialog shares an in-flight catalog and reuses it until invalidated', () async {
    var loads = 0;
    final reply = Completer<List<String>>();
    final catalog = TvSessionCatalog<String>(() {
      loads++;
      return loads == 1 ? reply.future : Future.value(['refreshed']);
    });
    final first = catalog.load();
    final second = catalog.load();
    expect(loads, 1);
    reply.complete(['album']);
    expect(await first, ['album']);
    expect(await second, ['album']);
    expect(await catalog.load(), ['album']);
    expect(loads, 1);
    catalog.invalidate();
    expect(await catalog.load(), ['refreshed']);
    expect(loads, 2);
  });

  test('failed loads are retried and another dialog gets its own catalog', () async {
    var loads = 0;
    Future<List<String>> fetch() async {
      if (++loads == 1) throw StateError('offline');
      return ['album'];
    }

    final catalog = TvSessionCatalog(fetch);
    await expectLater(catalog.load(), throwsStateError);
    expect(await catalog.load(), ['album']);
    expect(await TvSessionCatalog(fetch).load(), ['album']);
    expect(loads, 3);
  });
}
