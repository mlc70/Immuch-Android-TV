bool tvAlbumCanEdit(Map<String, dynamic> album, String? userId) {
  if (userId == null) {
    return false;
  }
  // Older servers expose ownership directly; current servers use an owner role
  // in albumUsers, alongside editor and viewer roles.
  if (album['ownerId'] == userId || (album['owner'] as Map?)?['id'] == userId) {
    return true;
  }
  return (album['albumUsers'] as List? ?? []).any((entry) {
    final member = entry as Map;
    return (member['user'] as Map?)?['id'] == userId &&
        (member['role'] == 'owner' || member['role'] == 'editor');
  });
}
