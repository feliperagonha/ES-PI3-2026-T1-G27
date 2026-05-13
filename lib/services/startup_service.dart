// Felipe Ragonha
// RA: 24023900

// Juliano Perusso
// RA: 24023434

import 'package:cloud_functions/cloud_functions.dart';
import '../models/startup.dart';

class StartupService {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'southamerica-east1',
  );

  Future<List<Startup>> listStartups() async {
    final callable = _functions.httpsCallable('listStartups');

    final result = await callable.call();

    final response = Map<String, dynamic>.from(result.data);

    final startupsData = List<Map<String, dynamic>>.from(
      (response['data'] as List).map(
            (item) => Map<String, dynamic>.from(item),
      ),
    );

    return startupsData.map((data) {
      return Startup.fromMap(data['id'], data);
    }).toList();
  }
}