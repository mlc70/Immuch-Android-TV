import 'package:flutter/material.dart';

class TvBuildIdentity extends StatelessWidget {
  const TvBuildIdentity({super.key});
  @override
  Widget build(BuildContext context) {
    const branch = String.fromEnvironment('TV_BRANCH', defaultValue: 'local');
    const commit = String.fromEnvironment('TV_COMMIT', defaultValue: 'uncommitted');
    const run = String.fromEnvironment('TV_BUILD', defaultValue: 'local');
    final shortCommit = commit.substring(0, commit.length < 12 ? commit.length : 12);
    return Text('TV r$run • $branch • $shortCommit', maxLines: 1, overflow: TextOverflow.ellipsis);
  }
}
