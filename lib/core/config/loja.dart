import 'package:flutter/foundation.dart';

/// Versão distribuída pela Play Store / App Store, gerada com
/// `--dart-define=LOJA=true`. Nela o app não vende plano (só mostra a
/// assinatura e as faturas) e não tem o atualizador próprio do APK.
const kBuildLoja = bool.fromEnvironment('LOJA');

/// Fora das lojas tudo é permitido. Na Play Store dá para informar, em texto
/// e sem link, que os planos ficam no site; na App Store nem isso.
bool get podeMencionarCompraExterna =>
    !kBuildLoja || defaultTargetPlatform != TargetPlatform.iOS;

/// Tira os "Faça upgrade..." das mensagens de limite (inclusive as que vêm
/// da API) quando a loja não permite sugerir a compra.
String semChamadaDeCompra(String mensagem) => podeMencionarCompraExterna
    ? mensagem
    : mensagem.replaceAll(RegExp(r'\s*Faça upgrade[^.]*\.'), '').trim();
