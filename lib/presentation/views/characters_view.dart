import 'package:flutter/material.dart';
import '../../core/di/dependency_injection.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/account_entity.dart';
import '../../domain/models/character_entity.dart';
import '../../domain/models/extensions/character_ui.dart';
import '../controllers/characters_state_viewmodel.dart';
import '../controllers/characters_view_model.dart';
import '../widgets/account_summary_card.dart';
import '../widgets/app_drawer.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/star_rating.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../helper_dev/fakes/factories.dart';

/// Página de listagem de personagens
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
    // _viewModel.loadCharacters();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // _viewModel.refresh();
  }

  Future<void> _deleteCharacter(Character character) async {
    // await _viewModel.deleteCharacter(character.id);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${character.name} removido')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personagens'),
        actions: [
          // Botão de direção da ordenação
          Watch((context) {
            final order = _viewModel.charactersState.sortOrder.value;
            return IconButton(
              icon: Icon(
                order == SortOrder.ascending
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
              ),
              tooltip: order == SortOrder.ascending
                  ? 'Ascendente'
                  : 'Descendente',
              // onPressed: () {},
              onPressed: _viewModel.charactersState.toggleSortOrder,
            );
          }),
          // Botão de ordenação
          Watch((context) {
            final currentSort = _viewModel.charactersState.sortBy.value;
            return PopupMenuButton<SortBy>(
              icon: const Icon(Icons.sort),
              tooltip: 'Ordenar',
              onSelected: _viewModel.charactersState.setSortBy,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: SortBy.name,
                  child: Row(
                    children: [
                      Icon(
                        Icons.sort_by_alpha,
                        color: currentSort == SortBy.name
                            ? Colors.amber
                            // ? Theme.of(context).colorScheme.secondary
                            : null,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Nome',
                        style: currentSort == SortBy.name
                            ? TextStyle(
                                color: Colors.amber,
                                // color: Theme.of(context).colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: SortBy.level,
                  child: Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        color: currentSort == SortBy.level
                            ? Colors.amber
                            : null,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Level',
                        style: currentSort == SortBy.level
                            ? TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: SortBy.stars,
                  child: Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: currentSort == SortBy.stars
                            ? Colors.amber
                            : null,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Estrelas',
                        style: currentSort == SortBy.stars
                            ? TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
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
              final isLoading =
                  _viewModel.commands.getAllCharactersCommand.isExecuting.value;
              // final isLoading = false;
              // final characters = CharacterFactory.list(10);

              if (isLoading) {
                return LoadingIndicator(message: 'Carregando personagens...');
              }

              final characters = _viewModel.charactersState.state.value;

              if (characters.isEmpty) {
                return EmptyState();
              }

              return RefreshIndicator(
                onRefresh: () async {
                  // await _viewModel.refresh();
                },
                child: ListView.builder(
                  padding: AppSpacing.paddingMd,
                  itemCount: characters.length,
                  itemBuilder: (context, index) {
                    final character = characters[index];
                    return CharacterListItem(
                      character: character,
                      onDelete: () => _deleteCharacter(character),
                      onTap: () {},
                      // onTap: () => context.push(
                      //   AppRoutes.editarPersonagemComId(character.id),
                      // ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: Watch((context) {
        final isExecuting =
            _viewModel.commands.createCharacterCommand.isExecuting.value;

        return FloatingActionButton(
          onPressed: isExecuting
              ? null
              : () async {
                  final character = CharacterFactory.list(1).first;
                  await _viewModel.commands.addCharacter(character);
                },
          child: isExecuting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.add),
        );
      }),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.xxl,
        ),
        child: Column(
          // mainAxisSize: MainAxisSize.max,
          // mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(
              Icons.people_outline,
              size: 72,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Nenhum personagem encontrado',
              textAlign: TextAlign.center,
              style: context.textStyles.titleMedium?.semiBold,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Adicione seu primeiro personagem usando o botão +',
              textAlign: TextAlign.center,
              style: context.textStyles.bodyMedium?.withColor(
                Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Item da lista de personagens
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
    return Dismissible(
      key: Key(character.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: AppSpacing.lg),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onTap();
          return false;
        } else {
          return await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirmar exclusão'),
                  content: Text('Deseja realmente excluir ${character.name}?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Excluir'),
                    ),
                  ],
                ),
              ) ??
              false;
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onDelete();
        }
      },
      child: Card(
        color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.9),
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: AppSpacing.paddingMd,
            child: Row(
              children: [
                // Indicador de raridade
                Container(
                  width: 4,
                  height: 60,
                  decoration: BoxDecoration(
                    color: character.rarity.color,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Conteúdo principal
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
                            style: context.textStyles.labelLarge?.withColor(
                              Theme.of(context).colorScheme.onSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Icon(
                            character.characterClass.icon,
                            size: 16,
                            color: character.characterClass.color,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            character.characterClass.displayName,
                            style: context.textStyles.bodySmall?.withColor(
                              Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
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
    );
  }
}

class FilterPanel extends StatelessWidget {
  final CharactersViewModel viewModel;

  const FilterPanel({super.key, required this.viewModel});

  CharactersStateViewmodel get state => viewModel.charactersState;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final filtersCount = state.activeFiltersCount.value;
      final isExpanded = state.isFilterPanelExpanded.value;

      return Container(
        margin: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.85),
              Theme.of(context).colorScheme.secondary,
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
          color: Theme.of(context).colorScheme.secondary,
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 1,
            ),
          ),
        ),
        child: Column(
          children: [
            // Cabeçalho do painel
            InkWell(
              onTap: state.toggleFilterPanel,
              child: Padding(
                padding: AppSpacing.paddingMd,
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_list,
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Filtros',
                      style: context.textStyles.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    if (filtersCount > 0) ...[
                      const SizedBox(width: 6),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$filtersCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],

                    const Spacer(),

                    if (filtersCount > 0)
                      TextButton.icon(
                        onPressed: state.clearFilters,
                        icon: const Icon(Icons.clear, size: 16),
                        label: const Text('Limpar'),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onSecondary,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                  ],
                ),
              ),
            ),

            // Conteúdo do painel (expansível)
            if (isExpanded)
              // if (_isExpanded)
              SizedBox(
                width: double.infinity,
                child: _FiltersContent(state: state)),
          ],
        ),
      );
    });
  }
}

class _FiltersContent extends StatelessWidget {
  const _FiltersContent({required this.state});

  final CharactersStateViewmodel state;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 450),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filtro de Raridade
                Text(
                  'Raridade',
                  style: context.textStyles.labelLarge?.semiBold,
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: CharacterRarity.values.map((rarity) {
                    // final isSelected = widget
                    //     .viewModel
                    //     .selectedRarities
                    //     .value
                    //     .contains(rarity);
                    // final isSelected = false;
                    final isSelected = state.selectedRarities.value.contains(
                      rarity,
                    );

                    return FilterChip(
                      label: Text(
                        rarity.displayName,
                        style: TextStyle(color: rarity.color),
                      ),
                      selected: isSelected,
                      onSelected: (_) => state.toggleRarity(rarity),
                      // onSelected: (_) {},
                      // onSelected: (_) =>
                      //     widget.viewModel.toggleRarityFilter(rarity),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),

                // Filtro de Classe
                Text('Classe', style: context.textStyles.labelLarge?.semiBold),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  alignment: WrapAlignment.start,
                  children: CharacterClass.values.map((characterClass) {
                    // final isSelected = widget
                    //     .viewModel
                    //     .selectedClasses
                    //     .value
                    //     .contains(characterClass);
                    // final isSelected = false;
                    final isSelected = state.selectedClasses.value.contains(
                      characterClass,
                    );
                    return FilterChip(
                      label: Text(
                        characterClass.displayName,
                        style: TextStyle(color: characterClass.color),
                      ),
                      selected: isSelected,
                      onSelected: (_) => state.toggleClass(characterClass),
                      // onSelected: (_) {},
                      // onSelected: (_) => widget.viewModel.toggleClassFilter(
                      //   characterClass,
                      // ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),

                // Filtro de Level
                Text('Level', style: context.textStyles.labelLarge?.semiBold),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: LevelFilter.values.map((filter) {
                    return FilterChip(
                      label: Text(
                        filter.label,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSecondary,
                        ),
                      ),
                      selected: state.levelFilter.value == filter,
                      onSelected: (_) => state.setLevelFilter(filter),
                    );
                  }).toList(),
                ),
                // Wrap(
                //   spacing: AppSpacing.xs,
                //   runSpacing: AppSpacing.xs,
                //   children: [
                //     FilterChip(
                //       label: Text(
                //         'Todos',
                //         style: TextStyle(
                //           color: Theme.of(context).colorScheme.onSecondary,
                //         ),
                //       ),
                //       // selected:
                //       //     widget.viewModel.levelFilter.value ==
                //       //     LevelFilter.all,
                //       // selected: false,
                //       selected:
                //           _viewModel.charactersState.levelFilter.value ==
                //           LevelFilter.all,
                //       onSelected: (_) => _viewModel.charactersState
                //           .setLevelFilter(LevelFilter.all),
                //       // onSelected: (_) {},
                //       // onSelected: (_) =>
                //       //     widget.viewModel.setLevelFilter(LevelFilter.all),
                //     ),
                //     FilterChip(
                //       label: Text(
                //         'Abaixo de 30',
                //         style: TextStyle(
                //           color: Theme.of(context).colorScheme.onSecondary,
                //         ),
                //       ),
                //       // selected:
                //       //     widget.viewModel.levelFilter.value ==
                //       //     LevelFilter.below30,
                //       // selected: false,
                //       selected:
                //           _viewModel.charactersState.levelFilter.value ==
                //           LevelFilter.below30,
                //       onSelected: (_) => _viewModel.charactersState
                //           .setLevelFilter(LevelFilter.below30),
                //       // onSelected: (_) {},
                //       // onSelected: (_) => widget.viewModel.setLevelFilter(
                //       //   LevelFilter.below30,
                //     ),

                //     FilterChip(
                //       label: Text(
                //         'Abaixo de 60',
                //         style: TextStyle(
                //           color: Theme.of(context).colorScheme.onSecondary,
                //         ),
                //       ),
                //       // selected:
                //       //     widget.viewModel.levelFilter.value ==
                //       //     LevelFilter.below60,
                //       // selected: false,
                //       // onSelected: (_) {},
                //       selected:
                //           _viewModel.charactersState.levelFilter.value ==
                //           LevelFilter.below60,
                //       onSelected: (_) => _viewModel.charactersState
                //           .setLevelFilter(LevelFilter.below60),
                //       // onSelected: (_) => widget.viewModel.setLevelFilter(
                //       //   LevelFilter.below60,
                //     ),

                //     FilterChip(
                //       label: Text(
                //         'Até 70',
                //         style: TextStyle(
                //           color: Theme.of(context).colorScheme.onSecondary,
                //         ),
                //       ),
                //       // selected:
                //       //     widget.viewModel.levelFilter.value ==
                //       //     LevelFilter.upTo70,
                //       // selected: false,
                //       // onSelected: (_) {},
                //       selected:
                //           _viewModel.charactersState.levelFilter.value ==
                //           LevelFilter.upTo70,
                //       onSelected: (_) => _viewModel.charactersState
                //           .setLevelFilter(LevelFilter.upTo70),
                //       // onSelected: (_) => widget.viewModel.setLevelFilter(
                //       //   LevelFilter.upTo70,
                //       // ),
                //     ),
                //     FilterChip(
                //       label: Text(
                //         'Level 80',
                //         style: TextStyle(
                //           color: Theme.of(context).colorScheme.onSecondary,
                //         ),
                //       ),
                //       // selected:
                //       //     widget.viewModel.levelFilter.value ==
                //       //     LevelFilter.max80,
                //       // selected: false,
                //       // onSelected: (_) {},
                //       selected:
                //           _viewModel.charactersState.levelFilter.value ==
                //           LevelFilter.max80,
                //       onSelected: (_) => _viewModel.charactersState
                //           .setLevelFilter(LevelFilter.max80),
                //       // onSelected: (_) => widget.viewModel.setLevelFilter(
                //       //   LevelFilter.max80,
                //       // ),
                //     ),
                //   ],
                // ),
              ],
            ),
          ),
        ),
      );
    });
  }
}