import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'companion_io.dart';

class WatchRoot {
  const WatchRoot(this.path, this.accepts, this.depth);
  final String path;
  final bool Function(String name) accepts;
  final int depth;
}

List<WatchRoot> defaultWatchRoots() => [
  WatchRoot('$homeDirectory/.codex/sessions', (n) => n.endsWith('.jsonl'), 7),
  WatchRoot('$homeDirectory/.claude/projects', (n) => n.endsWith('.jsonl'), 7),
  WatchRoot(
    '$homeDirectory/.gemini/tmp',
    (n) => RegExp(r'^session-.*\.jsonl?$').hasMatch(n),
    4,
  ),
  WatchRoot(companionStateDir, (n) => n == 'claude-metrics.json', 0),
];

/// Signals when CLI usage logs change. Native file events give low latency;
/// a metadata-only poll covers directories created later or missed events.
/// The collectors remain responsible for reading allowed usage files.
class UsageWatcher {
  UsageWatcher(
    this.onChange, {
    List<WatchRoot>? roots,
    this.debounce = const Duration(milliseconds: 250),
    this.maxWait = const Duration(seconds: 1),
    Duration poll = const Duration(seconds: 10),
  }) : roots = roots ?? defaultWatchRoots() {
    ready = _scan();
    _poll = Timer.periodic(poll, (_) => unawaited(_scan()));
  }

  final void Function() onChange;
  final List<WatchRoot> roots;
  final Duration debounce, maxWait;
  late final Future<void> ready;
  late final Timer _poll;
  final _subscriptions = <String, StreamSubscription<FileSystemEvent>>{};
  final _fingerprints = <String, String>{};
  Timer? _debounce, _deadline;
  var _stopped = false, _scanning = false, _initialized = false;

  void _flush() {
    _debounce?.cancel();
    _deadline?.cancel();
    _debounce = _deadline = null;
    if (!_stopped) onChange();
  }

  void _changed() {
    if (_stopped) return;
    _debounce?.cancel();
    _debounce = Timer(debounce, _flush);
    _deadline ??= Timer(maxWait, _flush);
  }

  Future<void> _scan() async {
    if (_stopped || _scanning) return;
    _scanning = true;
    try {
      for (final root in roots) {
        final type = await FileSystemEntity.type(root.path, followLinks: false);
        if (_stopped) return;
        if (type == FileSystemEntityType.notFound) {
          if (_fingerprints.remove(root.path) != null) {
            await _subscriptions.remove(root.path)?.cancel();
            _changed();
          }
          continue;
        }
        if (type != FileSystemEntityType.directory) continue;
        _subscriptions[root.path] ??= _watch(root);
        final next = await _fingerprint(root);
        if (_stopped) return;
        final previous = _fingerprints[root.path];
        if (previous != null && next != previous) _changed();
        // A directory created after startup must also trigger collection.
        if (previous == null && _initialized) _changed();
        _fingerprints[root.path] = next;
      }
    } finally {
      _scanning = false;
      _initialized = true;
    }
  }

  StreamSubscription<FileSystemEvent> _watch(WatchRoot root) {
    final stream = Directory(root.path).watch(recursive: root.depth > 0);
    late final StreamSubscription<FileSystemEvent> sub;
    sub = stream.listen(
      (event) {
        if (root.accepts(event.path.split('/').last)) _changed();
      },
      onError: (Object _) {
        sub.cancel();
        _subscriptions.remove(root.path);
      },
      cancelOnError: true,
    );
    return sub;
  }

  /// Hashes path, size and modification time only; never file contents.
  Future<String> _fingerprint(WatchRoot root) async {
    final walked = await walkFiles(
      root.path,
      accepts: root.accepts,
      maxDepth: root.depth,
    );
    final buffer = StringBuffer();
    for (final path in walked.files) {
      try {
        final stat = await File(path).stat();
        if (stat.type != FileSystemEntityType.file) continue;
        buffer.writeln(
          '$path:${stat.size}:${stat.modified.microsecondsSinceEpoch}:${stat.changed.microsecondsSinceEpoch}',
        );
      } catch (_) {
        // A session can rotate while it is being scanned.
      }
    }
    return sha256.convert(utf8.encode(buffer.toString())).toString();
  }

  void close() {
    _stopped = true;
    _poll.cancel();
    _debounce?.cancel();
    _deadline?.cancel();
    for (final sub in _subscriptions.values) {
      unawaited(sub.cancel());
    }
    _subscriptions.clear();
  }
}
