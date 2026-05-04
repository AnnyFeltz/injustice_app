import '../../core/failure/failure.dart';
import '../../core/patterns/command.dart';
import '../../domain/facades/character_facade_usecases_interface.dart';
import '../../domain/models/character_entity.dart';
import '../commands/character_commands.dart';
import 'package:signals_flutter/signals_flutter.dart';

class CharacterEditViewModel {
  final ICharacterFacadeUseCases _facade;
  late final UpdateCharacterCommand _updateCharacterCommand;

  CharacterEditViewModel(this._facade) {
    _updateCharacterCommand = UpdateCharacterCommand(_facade);
    _observeUpdateCharacter();
  }

  // Getter para o comando
  UpdateCharacterCommand get updateCharacterCommand => _updateCharacterCommand;

  // Observador para o update (caso você precise reagir ao sucesso ou erro na tela de edição)
  void _observeUpdateCharacter() {
    effect(() {
      if (_updateCharacterCommand.isExecuting.value) return;

      final result = _updateCharacterCommand.result.value;
      if (result == null) return;

      result.fold(
        onSuccess: (updatedCharacter) {
          // Ações de sucesso caso precise (ex: atualizar estado local)
          _updateCharacterCommand.clear();
        },
        onFailure: (err) {
          // Ações em caso de erro (ex: mostrar mensagem)
          _updateCharacterCommand.clear();
        },
      );
    });
  }

  Future<void> updateCharacter(Character character) async {
    await _updateCharacterCommand.executeWith((character: character));
  }
}