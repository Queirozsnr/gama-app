import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_notifier.dart';

class SelectGroupScreen extends ConsumerStatefulWidget {
  const SelectGroupScreen({super.key});

  @override
  ConsumerState<SelectGroupScreen> createState() => _SelectGroupScreenState();
}

class _SelectGroupScreenState extends ConsumerState<SelectGroupScreen> {
  int? _loadingId;

  Future<void> _selecionar(int grupoId) async {
    setState(() => _loadingId = grupoId);
    try {
      await ref.read(authNotifierProvider.notifier).selectGroup(grupoId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final grupos = ref.watch(authNotifierProvider).valueOrNull?.availableGroups ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Selecione o Grupo')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: grupos.length,
        separatorBuilder: (_, _) => const Divider(),
        itemBuilder: (context, index) {
          final grupo = grupos[index];
          final isLoading = _loadingId == grupo.id;
          return ListTile(
            leading: const Icon(Icons.store),
            title: Text(grupo.nome),
            trailing: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: _loadingId != null ? null : () => _selecionar(grupo.id),
          );
        },
      ),
    );
  }
}
