import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/initial_setup_repository.dart';

/// docs/04_User_Flows.md §4, Экран 4.2 — "Зачем вам AI Finance?"
/// (multi-select). No backend field exists for this yet, see
/// InitialSetupRepository's doc comment.
class SaveUsageGoals {
  const SaveUsageGoals(this._repository);

  final InitialSetupRepository _repository;

  Future<void> call(List<String> goalKeys) {
    return _repository.saveUsageGoals(goalKeys);
  }
}

final saveUsageGoalsProvider = Provider<SaveUsageGoals>((ref) {
  return SaveUsageGoals(ref.watch(initialSetupRepositoryProvider));
});
