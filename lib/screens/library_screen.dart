import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../src/state/capsulas_state.dart';
import '../src/models/capsula.dart';
import '../src/routes.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String? _selected;
  bool _searching = false;
  List<Capsula> _results = const [];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CapsulasState>();
    final all = state.all;
    final categories = all.map((e) => e.category).toSet().toList()..sort();
    return Scaffold(
      appBar: AppBar(title: const Text('Biblioteca')),
      body: Column(
        children: [
          _SearchBar(
            onChanged: (text) {
              final q = text.trim();
              final live = _filterClientSide(all, q);
              setState(() {
                _searching = q.isNotEmpty;
                _results = q.isEmpty ? const [] : live;
              });
            },
            onSubmit: (text) async {
              final q = text.trim();
              setState(() => _searching = q.isNotEmpty);
              if (q.isEmpty) {
                setState(() => _results = const []);
                return;
              }
              // Mantener la búsqueda en servidor como respaldo, la local es inmediata.
              final results = await state.search(q);
              if (!mounted) return;
              setState(() => _results = results.isNotEmpty ? results : _filterClientSide(all, q));
            },
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _CategoryChip(
                  label: 'Todos',
                  selected: _selected == null || _selected == 'Todos',
                  onTap: () => setState(() => _selected = 'Todos'),
                ),
                ...categories.map((c) => _CategoryChip(
                      label: c,
                      selected: _selected == c,
                      onTap: () => setState(() => _selected = c),
                    )),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _searching
                ? _SearchResultsList(
                    results: _filterByCategory(_results, _selected),
                  )
                : (_selected == null || _selected == 'Todos')
                    // Lado cliente para "Todos"
                    ? (all.isEmpty
                        ? const Center(child: Text('Sin cápsulas'))
                        : ListView.builder(
                            itemCount: all.length,
                            itemBuilder: (context, i) => _CapsulaTile(all[i]),
                          ))
                    // Flujo desde servidor para una categoría específica
                    : StreamBuilder<List<Capsula>>(
                        stream: state.repo.watchByCategory(_selected!),
                        builder: (context, snap) {
                          final data = snap.data ?? const <Capsula>[];
                          if (snap.connectionState == ConnectionState.waiting && data.isEmpty) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (data.isEmpty) return const Center(child: Text('Sin cápsulas'));
                          return ListView.builder(
                            itemCount: data.length,
                            itemBuilder: (context, i) => _CapsulaTile(data[i]),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  List<Capsula> _filterByCategory(List<Capsula> list, String? selected) {
    if (selected == null || selected == 'Todos') return list;
    return list.where((c) => c.category == selected).toList();
  }

  List<Capsula> _filterClientSide(List<Capsula> source, String q) {
    if (q.isEmpty) return const [];
    final nq = _normalize(q);
    return source.where((c) {
        final haystack = [c.title, c.category, c.description]
          .whereType<String>()
          .map(_normalize)
          .join(' ');
      return haystack.contains(nq);
    }).toList();
  }

  String _normalize(String s) {
    final lower = s.toLowerCase();
    // Eliminación básica de diacríticos
    const accents = {
      'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n',
    };
    final buf = StringBuffer();
    for (final ch in lower.runes) {
      final c = String.fromCharCode(ch);
      buf.write(accents[c] ?? c);
    }
    return buf.toString();
  }
}

class _CapsulaTile extends StatelessWidget {
  final Capsula c;
  const _CapsulaTile(this.c);
  @override
  Widget build(BuildContext context) {
    final state = context.watch<CapsulasState>();
    final fav = state.isFavorite(c.id);
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: cs.primary.withValues(alpha: .12),
        child: Text(c.title.isNotEmpty ? c.title[0].toUpperCase() : '■', style: TextStyle(color: cs.primary)),
      ),
      title: Text(c.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: _CategoryBadge(label: c.category),
      ),
      trailing: IconButton(
        icon: Icon(fav ? Icons.favorite : Icons.favorite_border, color: fav ? Colors.red : null),
        onPressed: () => state.toggleFavorite(c.id),
      ),
      onTap: () => Navigator.pushNamed(context, Routes.detail, arguments: c),
    );
  }
}

class _SearchBar extends StatefulWidget {
  final ValueChanged<String>? onChanged;
  final ValueChanged<String> onSubmit;
  const _SearchBar({this.onChanged, required this.onSubmit});
  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final _ctrl = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _ctrl,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: 'Buscar cápsula...',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: (t) {
          final oc = widget.onChanged;
          if (oc != null) oc(t);
          // Limpieza en vivo cuando la entrada queda vacía
          if (t.trim().isEmpty) widget.onSubmit('');
        },
        onSubmitted: widget.onSubmit,
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip({required this.label, this.selected = false, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: .15)
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

class _SearchResultsList extends StatelessWidget {
  final List<Capsula> results;
  const _SearchResultsList({required this.results});
  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) return const Center(child: Text('Sin resultados'));
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, i) => _CapsulaTile(results[i]),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String label;
  const _CategoryBadge({required this.label});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
