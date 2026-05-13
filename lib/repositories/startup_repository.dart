import '../models/startup.dart';
import '../services/startup_service.dart';

class StartupRepository {
  final StartupService _service = StartupService();

  Future<List<Startup>> listStartups() {
    return _service.listStartups();
  }
}