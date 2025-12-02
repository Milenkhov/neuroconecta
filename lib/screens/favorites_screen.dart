import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../src/state/capsulas_state.dart';
import '../src/models/capsula.dart';
import '../src/routes.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CapsulasState>();
    final favIds = state.favorites;
    final items = state.all.where((c) => favIds.contains(c.id)).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: items.isEmpty
          ? const Center(child: Text('Sin favoritos todavía'))
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, i) => _FavTile(items[i]),
            ),
    );
  }
}

class _FavTile extends StatelessWidget {
  final Capsula c;
  const _FavTile(this.c);
  @override
  Widget build(BuildContext context) {
    final state = context.watch<CapsulasState>();
    return ListTile(
      title: Text(c.title),
      subtitle: Text(c.category),
      trailing: IconButton(
        icon: const Icon(Icons.remove_circle_outline),
        onPressed: () => state.toggleFavorite(c.id),
      ),
      onTap: () => Navigator.pushNamed(context, Routes.detail, arguments: c),
    );
  }
}
