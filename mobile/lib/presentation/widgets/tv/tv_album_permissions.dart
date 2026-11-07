bool tvAlbumCanEdit(Map<String, dynamic> album, String? userId) {
  if (userId == null) {
    return false;
  }
  if (album['ownerId'] == userId) {
    return true;
  }
  return (album['albumUsers'] as List? ?? []).any((entry) {
    final member = entry as Map;
    return (member['user'] as Map?)?['id'] == userId && member['role'] == 'editor';
  });
}
