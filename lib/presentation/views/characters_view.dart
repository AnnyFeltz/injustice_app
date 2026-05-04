import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart'; // Adicionado pacote slidable
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
import 'character_edit_view.dart';

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
 }

 @override
 void didChangeDependencies() {
  super.didChangeDependencies();
 }

 Future<void> _deleteCharacter(Character character) async {
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
       onPressed: _viewModel.charactersState.toggleSortOrder,
      );
     }),
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
              : null,
           ),
           const SizedBox(width: AppSpacing.sm),
           Text(
            'Nome',
            style: currentSort == SortBy.name
              ? const TextStyle(
                color: Colors.amber,
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
              ? const TextStyle(
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
              ? const TextStyle(
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

       if (isLoading) {
        return LoadingIndicator(message: 'Carregando personagens...');
       }

       final characters = _viewModel.charactersState.state.value;

       if (characters.isEmpty) {
        return const EmptyState();
       }

       return RefreshIndicator(
        onRefresh: () async {
         await _viewModel.commands.fetchCharacters();
        },
        child: ListView.builder(
         padding: AppSpacing.paddingMd,
         itemCount: characters.length,
         itemBuilder: (context, index) {
          final character = characters[index];
          return CharacterListItem(
           character: character,
           onDelete: () => _deleteCharacter(character),
           onTap: () async {
            final result = await Navigator.push(
             context,
             MaterialPageRoute(
              builder: (context) => CharacterEditView(character: character),
             ),
            );

            if (result == true && mounted) {
             _viewModel.commands.fetchCharacters(); 

             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
               content: Text('Personagem alterado com sucesso!'),
              ),
             );
            }
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
  return Padding(
   // Adicionamos o padding aqui para substituir a margem do card
   padding: const EdgeInsets.only(bottom: AppSpacing.md),
   child: Slidable(
    key: Key(character.id),
    // Painel esquerdo (arrastando da esquerda para a direita)
    startActionPane: ActionPane(
     motion: const ScrollMotion(),
     children: [
      SlidableAction(
       onPressed: (context) {
        onTap(); // Ação de editar
       },
       backgroundColor: Colors.blue,
       foregroundColor: Colors.white,
       borderRadius: BorderRadius.circular(AppRadius.md), // Altura e cantos ajustados
       icon: Icons.edit,
       label: 'Editar',
      ),
     ],
    ),
    // Painel direito (arrastando da direita para a esquerda)
    endActionPane: ActionPane(
     motion: const ScrollMotion(),
     children: [
      SlidableAction(
       onPressed: (context) async {
        // Confirmação antes de excluir
        final confirm = await showDialog<bool>(
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
        ) ?? false;

        if (confirm) {
         onDelete();
        }
       },
       backgroundColor: Colors.red,
       foregroundColor: Colors.white,
       borderRadius: BorderRadius.circular(AppRadius.md),
       icon: Icons.delete,
       label: 'Excluir',
      ),
     ],
    ),
    child: Card(
     color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.9),
     // Zera a margem do card, pois agora está no Padding do Slidable
     margin: EdgeInsets.zero, 
     child: InkWell(
      onTap: () {}, // Deixa o clique simples inativo, permitindo arrastar sem ativar sem querer
      onDoubleTap: onTap, // 2 cliques para editar
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
    margin: const EdgeInsets.only(
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
     border: Border(
      bottom: BorderSide(
       color: Theme.of(context).colorScheme.outlineVariant,
       width: 1,
      ),
     ),
    ),
    child: Column(
     children: [
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
             foregroundColor:
               Theme.of(context).colorScheme.onSecondary,
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
      if (isExpanded)
       SizedBox(
        width: double.infinity,
        child: _FiltersContent(state: state),
       ),
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
        Text(
         'Raridade',
         style: context.textStyles.labelLarge?.semiBold,
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
         spacing: AppSpacing.xs,
         runSpacing: AppSpacing.xs,
         children: CharacterRarity.values.map((rarity) {
          final isSelected =
            state.selectedRarities.value.contains(rarity);

          return FilterChip(
           label: Text(
            rarity.displayName,
            style: TextStyle(color: rarity.color),
           ),
           selected: isSelected,
           onSelected: (_) => state.toggleRarity(rarity),
          );
         }).toList(),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Classe', style: context.textStyles.labelLarge?.semiBold),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
         spacing: AppSpacing.xs,
         runSpacing: AppSpacing.xs,
         alignment: WrapAlignment.start,
         children: CharacterClass.values.map((characterClass) {
          final isSelected =
            state.selectedClasses.value.contains(characterClass);
          return FilterChip(
           label: Text(
            characterClass.displayName,
            style: TextStyle(color: characterClass.color),
           ),
           selected: isSelected,
           onSelected: (_) => state.toggleClass(characterClass),
          );
         }).toList(),
        ),
        const SizedBox(height: AppSpacing.md),
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
       ],
      ),
     ),
    ),
   );
  });
 }
}