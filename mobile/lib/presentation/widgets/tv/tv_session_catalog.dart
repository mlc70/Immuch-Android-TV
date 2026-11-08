/// One catalog per open photo-actions dialog. Memberships are refreshed separately.
class TvSessionCatalog<T> {
  TvSessionCatalog(this._loader);

  final Future<List<T>> Function() _loader;
  Future<List<T>>? _request;

  Future<List<T>> load() {
    final cached = _request;
    if (cached != null) {
      return cached;
    }
    late final Future<List<T>> request;
    request = Future<List<T>>.sync(_loader).onError((Object error, StackTrace stack) {
      if (identical(_request, request)) {
        _request = null;
      }
      Error.throwWithStackTrace(error, stack);
    });
    _request = request;
    return request;
  }

  void invalidate() => _request = null;
}
