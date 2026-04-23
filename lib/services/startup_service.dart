import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/startup.dart';

class StartupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Startup>> getStartups() {
    return _firestore
        .collection('startups')
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Startup.fromMap(doc.id, doc.data());
      }).toList();
    });
  }
}