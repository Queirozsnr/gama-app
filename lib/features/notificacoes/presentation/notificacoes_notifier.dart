import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/token_storage.dart';
import '../data/notificacoes_remote_data_source.dart';
import '../domain/notificacao.dart';

final notificacoesDataSourceProvider = Provider<NotificacoesRemoteDataSource>(
  (ref) => NotificacoesRemoteDataSource(ref.watch(dioClientProvider)),
);

final notificacoesNotifierProvider =
    AsyncNotifierProvider<NotificacoesNotifier, List<Notificacao>>(
  NotificacoesNotifier.new,
);

class NotificacoesNotifier extends AsyncNotifier<List<Notificacao>> {
  HubConnection? _hub;

  @override
  Future<List<Notificacao>> build() async {
    final notificacoes = await _carregarDoServidor();
    unawaited(_conectarSignalR());
    ref.onDispose(_desconectar);
    return notificacoes;
  }

  Future<List<Notificacao>> _carregarDoServidor() =>
      ref.read(notificacoesDataSourceProvider).listar();

  Future<void> _conectarSignalR() async {
    final token = await ref.read(tokenStorageProvider).read();
    if (token == null) return;

    final hubUrl = '$kBaseUrl/hubs/notificacoes';

    _hub = HubConnectionBuilder()
        .withUrl(
          hubUrl,
          options: HttpConnectionOptions(
            accessTokenFactory: () async => token,
            skipNegotiation: false,
          ),
        )
        .withAutomaticReconnect()
        .build();

    _hub!.on('notificacao', (args) {
      if (args == null || args.isEmpty) return;
      final data = args[0];
      if (data is! Map<String, dynamic>) return;
      final nova = Notificacao.fromJson(data);
      state.whenData((lista) {
        state = AsyncData([nova, ...lista]);
      });
    });

    try {
      await _hub!.start();
      debugPrint('SignalR: conectado ao hub de notificações');
    } catch (e) {
      debugPrint('SignalR: erro ao conectar — $e');
    }
  }

  void _desconectar() {
    _hub?.stop();
    _hub = null;
  }

  Future<void> marcarLida(int id) async {
    await ref.read(notificacoesDataSourceProvider).marcarLida(id);
    state.whenData((lista) {
      state = AsyncData([
        for (final n in lista) n.id == id ? n.copyWith(lida: true) : n,
      ]);
    });
  }

  Future<void> marcarTodasLidas() async {
    await ref.read(notificacoesDataSourceProvider).marcarTodasLidas();
    state.whenData((lista) {
      state = AsyncData([for (final n in lista) n.copyWith(lida: true)]);
    });
  }
}
