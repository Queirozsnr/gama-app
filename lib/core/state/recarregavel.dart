import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lista que sabe buscar de novo com os filtros atuais, sem passar por loading.
/// Usada ao voltar para uma aba (as abas do shell ficam vivas e não recarregam
/// sozinhas) e ao voltar para o app.
mixin RecarregavelEmSegundoPlano<T> on AutoDisposeAsyncNotifier<T> {
  /// Busca os dados com os filtros, busca e paginação que estão valendo agora.
  Future<T> buscarComFiltrosAtuais();

  /// Em caso de erro mantém o que já está na tela: é uma atualização de fundo.
  Future<void> recarregarEmSegundoPlano() async {
    if (state.isLoading) return;
    try {
      state = AsyncData(await buscarComFiltrosAtuais());
    } catch (_) {}
  }
}
