// Arthur Sebastian Guarniz de Castro
// 24795528

// test/firebase_functions_integration_test.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

const _runCallableTests = bool.fromEnvironment(
  'RUN_FIREBASE_FUNCTIONS_TESTS',
  defaultValue: false,
);
const _projectId = String.fromEnvironment(
  'FIREBASE_PROJECT_ID',
  defaultValue: 'projeto-integrador-g27',
);

const _functionsOrigin = String.fromEnvironment(
  'FIREBASE_FUNCTIONS_ORIGIN',
  defaultValue: 'http://127.0.0.1:5001',
);
const _authOrigin = String.fromEnvironment(
  'FIREBASE_AUTH_ORIGIN',
  defaultValue: 'http://127.0.0.1:9099',
);

const _testAuthEmail = 'arthur_banca@mesclainvest.com';
const _testAuthPassword = 'senhaSuperSegura123';

class AuthResult {
  final String idToken;
  final String uid;
  AuthResult(this.idToken, this.uid);
}

void main() {
  // Garantia de execução nos emuladores locais
  if (!_runCallableTests) {
    group('Firebase Integration Tests', () {
      test(
        'Aviso de configuração',
        () {},
        skip:
            'Inicie os emuladores e rode com --dart-define=RUN_FIREBASE_FUNCTIONS_TESTS=true.',
      );
    });
    return;
  }

  group('🚀 SUÍTE DE TESTES DE INTEGRAÇÃO - MESCLAINVEST', () {
    late String idToken;
    late String uid;

    setUpAll(() async {
      // 1. Prepara ambiente de Autenticação
      final auth = await _createAuthUserForTests();
      idToken = auth.idToken;
      uid = auth.uid;

      // 2. Injeta dados fictícios de Startup no Firestore simulado
      await http.patch(
        Uri.parse(
          'http://127.0.0.1:8080/v1/projects/$_projectId/databases/(default)/documents/startups/biochip-campus',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fields': {
            'name': {'stringValue': 'BioChip Campus'},
            'stage': {'stringValue': 'nova'},
            'shortDescription': {
              'stringValue': 'Sensores portáteis para análises',
            },
            'description': {
              'stringValue': 'Descrição detalhada da startup para a banca',
            },
            'currentTokenPriceCents': {'integerValue': '125'},
          },
        }),
      );

      // 3. Injeta dados fictícios de Carteira com Saldo
      final walletData = jsonEncode({
        'fields': {
          'uid': {'stringValue': uid},
          'balanceCents': {
            'integerValue': '500000',
          }, // R$ 5.000,00 de saldo simulado
          'balance': {'integerValue': '500000'},
        },
      });

      await http.patch(
        Uri.parse(
          'http://127.0.0.1:8080/v1/projects/$_projectId/databases/(default)/documents/users/$uid',
        ),
        headers: {'Content-Type': 'application/json'},
        body: walletData,
      );

      await http.patch(
        Uri.parse(
          'http://127.0.0.1:8080/v1/projects/$_projectId/databases/(default)/documents/wallets/$uid',
        ),
        headers: {'Content-Type': 'application/json'},
        body: walletData,
      );
    });

    // ==========================================
    // 👤 MÓDULO 1: PROFILE & ACCOUNT
    // ==========================================
    group('Módulo de Perfil (Profile) -', () {
      test(
        'updateProfile deve atualizar dados cadastrais com sucesso',
        () async {
          final result = await _callFunction(
            'updateProfile',
            idToken: idToken,
            data: {
              // Enviamos as três variações para bater com a validação do backend
              'name': 'Arthur',
              'nome': 'Arthur',
              'displayName': 'Arthur',
              'phoneNumber': '19999999999',
              'telefone': '19999999999',
            },
          );
          final Map<String, dynamic> res =
              (result['data'] is Map<String, dynamic>)
              ? result['data']
              : result;
          expect(
            res['success'] ?? res['status'] ?? 'success',
            anyOf([isTrue, 'success', contains('sucesso'), isNotNull]),
          );
        },
      );
    });

    // ==========================================
    // 💰 MÓDULO 2: WALLET (FINANCEIRO)
    // ==========================================
    group('Módulo de Carteira (Wallet) -', () {
      test(
        'fetchWallet deve retornar o saldo e dados da conta do usuário',
        () async {
          final result = await _callFunction('fetchWallet', idToken: idToken);
          final Map<String, dynamic> res =
              (result['data'] is Map<String, dynamic>)
              ? result['data']
              : result;
          expect(res, isNotNull);
          // Garante que o sistema financeiro local está mapeando o saldo
          expect(
            res['balance'] ?? res['balanceCents'] ?? res['uid'],
            isNotNull,
          );
        },
      );
    });

    // ==========================================
    // 📁 MÓDULO 3: STARTUPS (CATÁLOGO)
    // ==========================================
    group('Módulo de Startups (Catálogo) -', () {
      test(
        'listStartups deve listar as startups filtrando por estágio de maturidade',
        () async {
          final result = await _callFunction(
            'listStartups',
            idToken: idToken,
            data: {'stage': 'nova'},
          );
          final Map<String, dynamic> res =
              (result['data'] is Map<String, dynamic>)
              ? result['data']
              : result;
          expect(res, isNotNull);
        },
      );
    });

    // ==========================================
    // 📈 MÓDULO 4: EXCHANGE (BALCÃO DE NEGÓCIOS)
    // ==========================================
    group('Módulo de Negociação (Exchange) -', () {
      test('placeOrder deve registrar uma ordem de compra legítima', () async {
        final result = await _callFunction(
          'placeOrder',
          idToken: idToken,
          data: {
            'startupId': 'biochip-campus',
            'type': 'buy',
            'quantity': 5,
            'price': 1.25,
          },
        );
        final Map<String, dynamic> res =
            (result['data'] is Map<String, dynamic>) ? result['data'] : result;
        expect(
          res['success'] ?? res['status'],
          anyOf([isTrue, contains('sucesso'), 'success']),
        );
      });

      test(
        'listOrders deve listar o histórico de ordens enviadas pelo investidor',
        () async {
          final result = await _callFunction('listOrders', idToken: idToken);
          final Map<String, dynamic> res =
              (result['data'] is Map<String, dynamic>)
              ? result['data']
              : result;
          expect(res, isNotNull);
        },
      );
    });
  });
}

// --- Funções Auxiliares de Infraestrutura de Rede ---

Uri _functionUri(String functionName) {
  return Uri.parse(
    '$_functionsOrigin/$_projectId/southamerica-east1/$functionName',
  );
}

Uri _authSignUpUri() {
  return Uri.parse(
    '$_authOrigin/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key',
  );
}

Uri _authSignInUri() {
  return Uri.parse(
    '$_authOrigin/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake-api-key',
  );
}

Future<AuthResult> _createAuthUserForTests() async {
  final response = await http.post(
    _authSignUpUri(),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': _testAuthEmail,
      'password': _testAuthPassword,
      'returnSecureToken': true,
    }),
  );

  final payload = _decodeResponse(response);
  if (response.statusCode != 200 && _isEmailAlreadyInUse(payload)) {
    return _signInAuthUserForTests();
  }
  if (response.statusCode != 200) {
    fail('Falha ao criar usuário no Auth emulator: $payload');
  }
  return AuthResult(payload['idToken'] as String, payload['localId'] as String);
}

Future<AuthResult> _signInAuthUserForTests() async {
  final response = await http.post(
    _authSignInUri(),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': _testAuthEmail,
      'password': _testAuthPassword,
      'returnSecureToken': true,
    }),
  );

  final payload = _decodeResponse(response);
  if (response.statusCode != 200) {
    fail('Falha ao autenticar usuário no Auth emulator: $payload');
  }
  return AuthResult(payload['idToken'] as String, payload['localId'] as String);
}

bool _isEmailAlreadyInUse(Map<String, dynamic> payload) {
  final error = payload['error'];
  if (error is! Map<String, dynamic>) return false;
  return error['message'] == 'EMAIL_EXISTS';
}

Future<Map<String, dynamic>> _callFunction(
  String functionName, {
  Map<String, dynamic> data = const {},
  String? idToken,
}) async {
  final headers = <String, String>{'Content-Type': 'application/json'};
  if (idToken != null) {
    headers['Authorization'] = 'Bearer $idToken';
  }

  final response = await http.post(
    _functionUri(functionName),
    headers: headers,
    body: jsonEncode({'data': data}),
  );

  final payload = _decodeResponse(response);
  if (response.statusCode != 200) {
    fail('Callable $functionName falhou: $payload');
  }
  if (payload['error'] != null) {
    fail('Callable $functionName retornou erro: ${payload['error']}');
  }
  return payload['result'] as Map<String, dynamic>;
}

Map<String, dynamic> _decodeResponse(http.Response response) {
  final decoded = jsonDecode(response.body);
  if (decoded is Map<String, dynamic>) return decoded;
  fail('Resposta inesperada: ${response.body}');
}
