import 'package:flutter_test/flutter_test.dart';

import 'package:petshop_app/main.dart';

void main() {
  testWidgets('App abre na tela de splash', (WidgetTester tester) async {
    await tester.pumpWidget(const BanhoTosaApp());

    //verifica se o texto da splash aparece
    expect(find.text('Banho & Tosa App'), findsOneWidget);

    //avanca o tempo simulado em 3 segundos, para que o timer
    //da SplashScreen seja concluído antes do teste terminar
    await tester.pump(const Duration(seconds: 3));
  });
}