import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/dependency_injection.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../domain/models/account_entity.dart';
import '../../domain/models/character_entity.dart';
import '../../domain/models/extensions/character_ui.dart';
import '../controllers/characters_state_viewmodel.dart';
import '../controllers/characters_view_model.dart';
import '../widgets/account_summary_card.dart';
import '../widgets/app_drawer.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/star_rating.dart';
import '../../helper_dev/fakes/factories.dart';

class CharactersView extends StatefulWidget {
  final Account account;

  const CharactersView({super.key, required this.account});

  @override
  State<CharactersView> createState() => _CharactersViewState();
}

class _CharactersViewState extends State<CharactersView> {
  late final CharactersViewModel _viewModel;
  Account get account => widget.account;

  @override
  void initState() {
    super.initState();
    _viewModel = injector.get<CharactersViewModel>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.commands.fetchCharacters();
    });
  }

  Future<void> _deleteCharacter(Character character) async {
    final bool confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar exclusão'),
            content: Text('Deseja realmente excluir ${character.name}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar', style: TextStyle(color: Colors.white)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Excluir', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      // await _viewModel.commands.deleteCharacter(character.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${character.name} removido')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personagens'),
        actions: [
          Watch((context) {
            final order = _viewModel.charactersState.sortOrder.value;
            return IconButton(
              icon: Icon(
                order == SortOrder.ascending ? Icons.arrow_upward : Icons.arrow_downward,
              ),
              onPressed: _viewModel.charactersState.toggleSortOrder,
            );
          }),
          Watch((context) {
            final currentSort = _viewModel.charactersState.sortBy.value;
            return PopupMenuButton<SortBy>(
              icon: const Icon(Icons.sort),
              onSelected: _viewModel.charactersState.setSortBy,
              itemBuilder: (context) => [
                _buildSortItem(SortBy.name, 'Nome', Icons.sort_by_alpha, currentSort),
                _buildSortItem(SortBy.level, 'Level', Icons.trending_up, currentSort),
                _buildSortItem(SortBy.stars, 'Estrelas', Icons.star, currentSort),
              ],
            );
          }),
        ],
      ),
      drawer: AppDrawer(), 
      body: Column(
        children: [
          Padding(
            padding: AppSpacing.paddingMd,
            child: AccountSummaryCard(account: account),
          ),
          FilterPanel(viewModel: _viewModel),
          Expanded(
            child: Watch((context) {
              final isLoading = _viewModel.commands.getAllCharactersCommand.isExecuting.value;

              if (isLoading) {
                return const LoadingIndicator(message: 'Carregando personagens...');
              }

              final characters = _viewModel.charactersState.state.value;

              if (characters.isEmpty) {
                return const EmptyState();
              }

              return RefreshIndicator(
                onRefresh: () async => _viewModel.commands.fetchCharacters(),
                child: ListView.builder(
                  padding: AppSpacing.paddingMd,
                  itemCount: characters.length,
                  itemBuilder: (context, index) {
                    final character = characters[index];
                    return CharacterListItem(
                      character: character,
                      onDelete: () => _deleteCharacter(character),
                      onTap: () {
                        context.pushNamed(
                          AppRouteNames.editCharacter,
                          pathParameters: {'id': character.id},
                        );
                      },
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: Watch((context) {
        final isExecuting = _viewModel.commands.createCharacterCommand.isExecuting.value;
        return FloatingActionButton(
          onPressed: isExecuting
              ? null
              : () async {
                  final character = CharacterFactory.list(1).first;
                  await _viewModel.commands.addCharacter(character);
                },
          child: isExecuting
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.add),
        );
      }),
    );
  }

  PopupMenuItem<SortBy> _buildSortItem(SortBy value, String label, IconData icon, SortBy current) {
    final bool isSelected = value == current;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: isSelected ? Colors.amber : null),
          const SizedBox(width: 8),
          Text(label, style: isSelected ? const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold) : null),
        ],
      ),
    );
  }
}

class CharacterListItem extends StatelessWidget {
  final Character character;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const CharacterListItem({
    super.key,
    required this.character,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Slidable(
        key: Key(character.id),
        
        startActionPane: ActionPane(
          motion: DrawerMotion(), // Trava o arraste no estilo gaveta
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (context) => onTap(),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: Icons.edit,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ],
        ),

        endActionPane: ActionPane(
          motion: DrawerMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (context) => onDelete(),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ],
        ),

        child: Card(
          margin: EdgeInsets.zero,
          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.9),
          child: InkWell(
            onTap: () {}, 
            onDoubleTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: AppSpacing.paddingMd,
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 60,
                    decoration: BoxDecoration(
                      color: character.rarity.color,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                character.name,
                                style: context.textStyles.titleMedium?.semiBold,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Nv. ${character.level}',
                              style: context.textStyles.labelLarge,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            Icon(character.characterClass.icon, size: 16, color: character.characterClass.color),
                            const SizedBox(width: 4),
                            Text(character.characterClass.displayName, style: context.textStyles.bodySmall),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        StarRating(stars: character.stars, size: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          const Text('Nenhum personagem encontrado'),
        ],
      ),
    );
  }
}

class FilterPanel extends StatelessWidget {
  final CharactersViewModel viewModel;
  const FilterPanel({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final state = viewModel.charactersState;
      final isExpanded = state.isFilterPanelExpanded.value;

      return Column(
        children: [
          ListTile(
            title: const Text('Filtros'),
            trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
            onTap: state.toggleFilterPanel,
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _FiltersContent(state: state),
            ),
        ],
      );
    });
  }
}

class _FiltersContent extends StatelessWidget {
  final CharactersStateViewmodel state;
  const _FiltersContent({required this.state});

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Raridade', style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8,
            children: CharacterRarity.values.map((r) {
              return FilterChip(
                label: Text(r.displayName),
                selected: state.selectedRarities.value.contains(r),
                onSelected: (_) => state.toggleRarity(r),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          const Text('Classe', style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8,
            children: CharacterClass.values.map((c) {
              return FilterChip(
                label: Text(c.displayName),
                selected: state.selectedClasses.value.contains(c),
                onSelected: (_) => state.toggleClass(c),
              );
            }).toList(),
          ),
        ],
      );
    });
  }
}