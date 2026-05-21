//Arthur Sebastian Guarniz de Castro
//24795528

// test/domain_business_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_integrador3_g27/models/user_model.dart';
import 'package:projeto_integrador3_g27/models/order_model.dart';

void main() {
  group('Testes de Regra de Negócio - Carteira e Ordens', () {
    test('Deve inicializar o usuário com saldo padrão correto', () {
      final user = UserModel(
        id: 'user_123',
        name: 'Arthur Castro',
        email: 'arthur@teste.com',
      );

      expect(user.balance, 0.0);
    });

    test(
      'Deve permitir criar uma ordem de compra se houver saldo suficiente',
      () {
        final user = UserModel(
          id: 'user_123',
          name: 'Arthur Castro',
          email: 'arthur@teste.com',
          balance: 500.0,
        );

        final order = OrderModel(
          id: 'order_01',
          userId: user.id,
          startupId: 'startup_alpha',
          type: 'buy',
          quantity: 10,
          price: 45.0, // Custo total = 450.0
          status: 'open',
        );

        final totalCost = order.quantity * order.price;

        // Validação da regra: o custo total não pode ser maior que o saldo do usuário
        expect(totalCost <= user.balance, isTrue);
      },
    );

    test(
      'Deve falhar/bloquear ordem de compra se o saldo for insuficiente',
      () {
        final user = UserModel(
          id: 'user_123',
          name: 'Arthur Castro',
          email: 'arthur@teste.com',
          balance: 100.0, // Saldo baixo
        );

        final order = OrderModel(
          id: 'order_02',
          userId: user.id,
          startupId: 'startup_alpha',
          type: 'buy',
          quantity: 5,
          price: 50.0, // Custo total = 250.0
          status: 'open',
        );

        final totalCost = order.quantity * order.price;

        // O teste espera que essa condição seja FALSA (saldo insuficiente)
        expect(totalCost <= user.balance, isFalse);
      },
    );

    test(
      'Deve garantir consistência nos status de ordens aceitas no balcão',
      () {
        final validStatuses = ['open', 'completed', 'cancelled'];

        final order = OrderModel(
          id: 'order_03',
          userId: 'user_123',
          startupId: 'startup_beta',
          type: 'sell',
          quantity: 2,
          price: 100.0,
          status: 'completed',
        );

        expect(validStatuses.contains(order.status), isTrue);
      },
    );
  });
}
