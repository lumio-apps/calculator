import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'neo.dart';
import 'settings.dart';

/// The history list with search and pinned entries.
class HistorySheet extends StatefulWidget {
  const HistorySheet({super.key, required this.onPick});

  /// Called with the result of the tapped entry.
  final ValueChanged<String> onPick;

  @override
  State<HistorySheet> createState() => _HistorySheetState();
}

class _HistorySheetState extends State<HistorySheet> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(String entry, String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase().replaceAll(' ', '').replaceAll('-', '−');
    return entry.toLowerCase().replaceAll(' ', '').contains(q);
  }

  Widget _tile(BuildContext context, AppSettings settings, String entry, {required bool pinned}) {
    final g = NeoStyle.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 12, right: 0),
      title: Text(formatExpression(entry, settings.numberStyle), textAlign: TextAlign.right),
      trailing: IconButton(
        tooltip: pinned ? 'Unpin' : 'Pin to top',
        icon: Icon(pinned ? Icons.push_pin : Icons.push_pin_outlined, color: pinned ? g.op : g.textDim),
        onPressed: () => settings.togglePin(entry),
      ),
      onTap: () {
        widget.onPick(entry.split(' = ').last);
        Navigator.pop(context);
      },
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: entry.replaceAll('−', '-')));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied')));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.of(context);
    final query = _search.text.trim();
    final pinned = settings.pinned.where((e) => _matches(e, query)).toList();
    final recent = settings.history.where((e) => _matches(e, query)).toList();
    final isEmpty = settings.history.isEmpty && settings.pinned.isEmpty;
    final labelStyle = Theme.of(context).textTheme.labelLarge;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: isEmpty
              ? const SizedBox(height: 160, child: Center(child: Text('No history yet')))
              : ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search history',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                icon: const Icon(Icons.close),
                                onPressed: () => setState(_search.clear),
                              ),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (pinned.isNotEmpty) ...[
                      Padding(padding: const EdgeInsets.fromLTRB(4, 8, 4, 0), child: Text('Pinned', style: labelStyle)),
                      for (final h in pinned) _tile(context, settings, h, pinned: true),
                      if (recent.isNotEmpty)
                        Padding(padding: const EdgeInsets.fromLTRB(4, 12, 4, 0), child: Text('Recent', style: labelStyle)),
                    ],
                    for (final h in recent) _tile(context, settings, h, pinned: false),
                    if (pinned.isEmpty && recent.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: Text('Nothing found')),
                      ),
                    if (settings.history.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          settings.clearHistory();
                          if (settings.pinned.isEmpty) Navigator.pop(context);
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: Text(settings.pinned.isEmpty ? 'Clear history' : 'Clear history (keeps pinned)'),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
