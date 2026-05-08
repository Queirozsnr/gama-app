import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_notifier.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('GAMA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.build_circle, size: 80, color: Colors.blueGrey),
            const SizedBox(height: 16),
            Text(
              'Bem-vindo ao GAMA',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            if (authState?.grupoOficinaId != null) ...[
              const SizedBox(height: 8),
              Text(
                'Grupo #${authState!.grupoOficinaId}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
