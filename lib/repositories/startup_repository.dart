import '../models/startup.dart';
import '../services/startup_service.dart';

class StartupRepository {
  final StartupService _service = StartupService();

  Stream<List<Startup>> getStartups() {
    return _service.getStartups();
  }
}