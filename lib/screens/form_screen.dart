import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import '../src/state/capsulas_state.dart';
import '../src/models/capsula.dart';

class FormScreen extends StatefulWidget {
  const FormScreen({super.key});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _videoCtrl = TextEditingController();
  final _attachCtrl = TextEditingController();
  final List<String> _attachments = [];

  final _db = FirebaseFirestore.instance.collection('capsulas');

  Future<void> _create() async {
    if (_formKey.currentState?.validate() != true) return;
    final c = Capsula(
      id: '_',
      title: _titleCtrl.text.trim(),
      category: _categoryCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      videoUrl: _videoCtrl.text.trim().isEmpty ? null : _videoCtrl.text.trim(),
      attachments: List<String>.from(_attachments),
    );
    // Use repository to ensure consistent keyword generation
    final state = context.read<CapsulasState>();
    await state.repo.create(c);
    _titleCtrl.clear();
    _categoryCtrl.clear();
    _descCtrl.clear();
    _videoCtrl.clear();
    _attachCtrl.clear();
    _attachments.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Creado')));
  }

  Future<void> _delete(String id) async {
    await _db.doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    if (Firebase.apps.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('CRUD Cápsulas')),
        body: const Center(
          child: Text(
            'Firebase no está configurado. Configura Firebase para usar el CRUD.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final state = context.watch<CapsulasState>();
    return Scaffold(
      appBar: AppBar(title: const Text('CRUD Cápsulas')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _FormHeader(),
            const SizedBox(height: 14),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 8),
                child: Form(
                  key: _formKey,
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SectionHeader(title: 'Datos básicos'),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(labelText: 'Título'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _categoryCtrl,
                    decoration: const InputDecoration(labelText: 'Categoría'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 24),
                  const _SectionHeader(title: 'Multimedia'),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _videoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Video URL (opcional)',
                      helperText: 'Admite enlaces de YouTube (youtube.com / youtu.be) o MP4 directos',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _attachCtrl,
                          decoration: const InputDecoration(labelText: 'Agregar adjunto (URL o nombre)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                        onPressed: () {
                          final t = _attachCtrl.text.trim();
                          if (t.isNotEmpty) {
                            setState(() {
                              _attachments.add(t);
                            });
                            _attachCtrl.clear();
                          }
                        },
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Añadir'),
                      )),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_attachments.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 6,
                        children: _attachments
                            .asMap()
                            .entries
                            .map((e) => Chip(
                                  label: Text(e.value),
                                  onDeleted: () => setState(() => _attachments.removeAt(e.key)),
                                ))
                            .toList(),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _create,
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Crear'),
                        ),
                      ),
                    ],
                  ),
                ],
                  ),
                ),
              ),
            ),
            const Divider(height: 32),
            Expanded(
              child: state.all.isEmpty
                  ? const Center(child: Text('Sin cápsulas'))
                  : ListView.builder(
                      itemCount: state.all.length,
                      itemBuilder: (context, i) {
                        final c = state.all[i];
                        return ListTile(
                          title: Text(c.title),
                          subtitle: Text(c.category),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _delete(c.id),
                          ),
                          onTap: () {
                            _titleCtrl.text = c.title;
                            _categoryCtrl.text = c.category;
                            _descCtrl.text = c.description;
                            _videoCtrl.text = c.videoUrl ?? '';
                            setState(() {
                              _attachments
                                ..clear()
                                ..addAll(c.attachments);
                            });
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormHeader extends StatelessWidget {
  const _FormHeader();
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.indigo, size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Crea cápsulas acogedoras',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Añade títulos, categorías, descripciones y videos para tu comunidad.',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.segment, size: 20),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}