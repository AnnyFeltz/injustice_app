import '../../core/failure/failure.dart';
import '../../core/patterns/command.dart';
import '../../domain/models/character_entity.dart';
import '../commands/character_commands.dart';
import 'characters_state_viewmodel.dart';
import 'package:signals_flutter/signals_flutter.dart';

class CharactersCommandsViewModel {
  final CharactersStateViewmodel state;
  final GetAllCharactersCommand _getAccountCommand;
  final CreateCharacterCommand _createCharacterCommand;
  final DeleteCharacterCommand _deleteCharacterCommand; 
  
  // Variável para guardar o id que estamos tentando deletar
  String? _deletedCharacterId;

  CharactersCommandsViewModel({
    required this.state,
    required GetAllCharactersCommand getAccountCommand,
    required CreateCharacterCommand createCharacterCommand,
    required DeleteCharacterCommand deleteCharacterCommand,
  })  : _getAccountCommand = getAccountCommand,
        _createCharacterCommand = createCharacterCommand,
        _deleteCharacterCommand = deleteCharacterCommand {
    // Observers para cada comando
    _observeGetAllCharacters();
    _observeCreateCharacter();
    _observeDeleteCharacter(); 
  }

  // ========================================================
  //   GETTERS PARA WIDGETS USAREM DIRETAMENTE OS COMANDOS
  // ========================================================
  GetAllCharactersCommand get getAllCharactersCommand => _getAccountCommand;
  CreateCharacterCommand get createCharacterCommand => _createCharacterCommand;
  DeleteCharacterCommand get deleteCharacterCommand => _deleteCharacterCommand;

  // ========================================================
  //   MÉTODO GENÉRICO DE OBSERVAÇÃO DE COMANDOS
  // ========================================================
  void _observeCommand<T>(
    Command<T, Failure> command, {
    required void Function(T data) onSuccess,
    void Function(Failure err)? onFailure,
  }) {
    effect(() {
      // 1) Ignora enquanto está executando
      if (command.isExecuting.value) return;

      // 2) Ignora até existir um resultado
      final result = command.result.value;
      if (result == null) return;

      // 3) Sucesso ou falha
      result.fold(
        onSuccess: (data) {
          state.clearMessage(); // sempre limpa erros em sucesso
          onSuccess(data); // ação específica para esse comando
          command.clear();
        },
        onFailure: (err) {
          state.setMessage(err.msg); // registra o erro no estado
          if (onFailure != null) onFailure(err);
          command.clear();
        },
      );
    });
  }

  // ========================================================
  //   OBSERVERS ESPECÍFICOS
  // ========================================================

  void _observeGetAllCharacters() {
    _observeCommand<List<Character>>(
      _getAccountCommand,
      onSuccess: (characters) {
        state.clearMessage(); 
        state.state.value = characters;
      },
      onFailure: (err) =>
          state.setMessage(err.msg), 
    );
  }

  void _observeCreateCharacter() {  
    _observeCommand<Character>(
      _createCharacterCommand,
      onSuccess: (newCharacter) {
        final currentList = state.state.value;
        state.state.value = [...currentList, newCharacter]; 
      },
      onFailure: (err) =>
          state.setMessage(err.msg), 
    );
  }
  
  void _observeDeleteCharacter() {
    _observeCommand<dynamic>(
      _deleteCharacterCommand,
      onSuccess: (_) {
        if (_deletedCharacterId != null) {
          // Atualização otimizada da tela: remove da lista local
          final currentList = List<Character>.from(state.state.value);
          currentList.removeWhere((char) => char.id == _deletedCharacterId);
          state.state.value = currentList;
          _deletedCharacterId = null;
        } else {
          fetchCharacters();
        }
      },
      onFailure: (err) {
        _deletedCharacterId = null;
        state.setMessage(err.msg);
      },
    );
  }

  // ========================================================
  //   MÉTODOS PÚBLICOS (CHAMADOS PELOS WIDGETS)
  // ========================================================
  
  Future<void> fetchCharacters() async {
    state.clearMessage(); 
    await _getAccountCommand.executeWith(());
  }

  Future<void> addCharacter(Character character) async {
    state.clearMessage(); 
    await _createCharacterCommand.executeWith((character: character));
  }

  Future<void> deleteCharacter(String id) async {
    state.clearMessage(); 
    _deletedCharacterId = id; // Marca qual ID estamos deletando
    await _deleteCharacterCommand.executeWith((id: id)); 
  }
}