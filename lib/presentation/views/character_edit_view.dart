import 'package:flutter/material.dart';
import '../../core/di/dependency_injection.dart';
import '../../domain/models/character_entity.dart';
import '../../core/theme/app_theme.dart';
import '../controllers/characters_view_model.dart';

class CharacterEditView extends StatefulWidget {
  final Character character;

  const CharacterEditView({super.key, required this.character});

  @override
  State<CharacterEditView> createState() => _CharacterEditViewState();
}

class _CharacterEditViewState extends State<CharacterEditView> {
  late final TextEditingController _nameController;
  late final CharactersViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.character.name);
    _viewModel = injector.get<CharactersViewModel>();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar ${widget.character.name}'),
      ),
      body: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome do Personagem',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () async {
                final updatedName = _nameController.text;

                final updatedCharacter = widget.character.copyWith(
                  name: updatedName,
                );

                await _viewModel.commands.updateCharacter(updatedCharacter);

                Navigator.pop(context, true); 
              },
              child: const Text('Salvar Alterações'),
            ),
          ],
        ),
      ),
    );
  }
}