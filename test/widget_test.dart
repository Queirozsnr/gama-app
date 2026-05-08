import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gama_app/main.dart';

void main() {
  testWidgets('App renderiza sem erros', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: GamaApp()));
    await tester.pump();
  });
}
