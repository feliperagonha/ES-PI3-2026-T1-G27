//Arthur Sebastian Guarniz de Castro
//24795528

class UserModel {
  final String id;
  final String name;
  final String email;
  final double balance; //Saldo da carteira

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.balance = 0.0,
  });

  //Pega os dados que vêm do Firebase (Map) e transforma em um Objeto Dart
  factory UserModel.fromJson(Map<String, dynamic> json, String documentId) {
    return UserModel(
      id: documentId,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      //Converte para double com segurança, caso venha como int do banco
      balance: (json['balance'] ?? 0).toDouble(),
    );
  }

  //Transforma o Objeto Dart em Map para salvar no Firebase
  Map<String, dynamic> toJson() {
    return {'name': name, 'email': email, 'balance': balance};
  }
}
