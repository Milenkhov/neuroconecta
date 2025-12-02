import 'package:flutter/material.dart';
import '../src/models/capsula.dart';
import '../src/routes.dart';
import 'package:provider/provider.dart';
import '../src/state/capsulas_state.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final passed = ModalRoute.of(context)?.settings.arguments;
    final initial = passed is List<Capsula> ? passed : <Capsula>[];
    return _SearchScaffold(initialResults: initial);
  }
}

class _SearchScaffold extends StatefulWidget {
  final List<Capsula> initialResults;
  const _SearchScaffold({required this.initialResults});
  @override
  State<_SearchScaffold> createState() => _SearchScaffoldState();
}

class _SearchScaffoldState extends State<_SearchScaffold> {
  final _ctrl = TextEditingController();
  List<Capsula> _results = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _results = widget.initialResults;
  }

  Future<void> _runSearch(BuildContext context) async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _loading = true);
    final repo = context.read<CapsulasState>();
    final found = await repo.search(text);
    setState(() {
      _results = found;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _ctrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Ej: respiración, dislexia...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onSubmitted: (_) => _runSearch(context),
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: _results.isEmpty
                ? const Center(child: Text('Sin resultados'))
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, i) {
                      final c = _results[i];
                      return ListTile(
                        title: Text(c.title),
                        subtitle: Text(c.category),
                        onTap: () => Navigator.pushNamed(context, Routes.detail, arguments: c),
                      );
                    },
                  ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _runSearch(context),
        child: const Icon(Icons.search),
      ),
    );
  }
}
