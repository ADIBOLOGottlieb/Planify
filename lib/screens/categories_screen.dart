import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/category_provider.dart';
import '../utils/app_constants.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catProvider = context.watch<CategoryProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catégories'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context, null),
        child: const Icon(Icons.add_rounded),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Actives', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...catProvider.categories
              .where((c) => !c.estArchivee)
              .map((c) => _CategoryTile(cat: c, onEdit: () => _openForm(context, c))),
          const SizedBox(height: 16),
          const Text('Archivées', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...catProvider.archivees.map((c) => _CategoryTile(cat: c, onEdit: () => _openForm(context, c))),
        ],
      ),
    );
  }

  void _openForm(BuildContext context, Categorie? cat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _CategoryForm(cat: cat),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final Categorie cat;
  final VoidCallback onEdit;

  const _CategoryTile({required this.cat, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final color = AppHelpers.hexToColor(cat.couleur);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(AppHelpers.getCategoryIcon(cat.icone), color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cat.nom, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(cat.type, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_rounded)),
          IconButton(
            onPressed: () => context
                .read<CategoryProvider>()
                .archiver(cat.id, archive: !cat.estArchivee),
            icon: Icon(cat.estArchivee ? Icons.unarchive_rounded : Icons.archive_rounded),
          ),
        ],
      ),
    );
  }
}

class _CategoryForm extends StatefulWidget {
  final Categorie? cat;
  const _CategoryForm({this.cat});

  @override
  State<_CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends State<_CategoryForm> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  String _type = 'depense';
  String _icon = 'more_horiz';
  String _color = '#546E7A';

  final _icons = const [
    'home',
    'restaurant',
    'directions_car',
    'local_hospital',
    'school',
    'sports_esports',
    'checkroom',
    'phone_android',
    'more_horiz',
    'work',
    'storefront',
    'laptop',
    'trending_up',
    'attach_money',
  ];

  final _colors = const [
    '#1E6B5E',
    '#F4A627',
    '#E53935',
    '#1E88E5',
    '#8E24AA',
    '#00ACC1',
    '#F4511E',
    '#6D4C41',
    '#546E7A',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.cat != null) {
      _nomCtrl.text = widget.cat!.nom;
      _type = widget.cat!.type;
      _icon = widget.cat!.icone;
      _color = widget.cat!.couleur;
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = context.read<AuthProvider>().currentUser!.id;
    final catProvider = context.read<CategoryProvider>();
    if (widget.cat == null) {
      await catProvider.ajouter(
        nom: _nomCtrl.text.trim(),
        icone: _icon,
        couleur: _color,
        type: _type,
        userId: userId,
      );
    } else {
      await catProvider.modifier(widget.cat!.copyWith(
        nom: _nomCtrl.text.trim(),
        icone: _icon,
        couleur: _color,
      ));
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.cat == null ? 'Nouvelle catégorie' : 'Modifier la catégorie',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nomCtrl,
              decoration: const InputDecoration(labelText: 'Nom'),
              validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 12),
            const Text('Type', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            Row(
              children: ['depense', 'revenu'].map((t) {
                final sel = _type == t;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _type = t),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? AppConstants.primaryColor : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(t[0].toUpperCase() + t.substring(1),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: sel ? Colors.white : Colors.grey,
                              fontWeight: FontWeight.w500)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            const Text('Icône', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _icons.map((i) {
                final sel = _icon == i;
                return GestureDetector(
                  onTap: () => setState(() => _icon = i),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: sel ? AppConstants.primaryColor.withValues(alpha: 0.15) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: sel ? AppConstants.primaryColor : Colors.transparent),
                    ),
                    child: Icon(AppHelpers.getCategoryIcon(i),
                        size: 18, color: sel ? AppConstants.primaryColor : Colors.grey),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            const Text('Couleur', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _colors.map((c) {
                final sel = _color == c;
                final color = AppHelpers.hexToColor(c);
                return GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: sel ? Colors.black : Colors.transparent, width: 2),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _save, child: const Text('Enregistrer')),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
