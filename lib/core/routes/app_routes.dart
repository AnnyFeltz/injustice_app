import '../../domain/models/account_entity.dart';
import '../../presentation/views/about_view.dart';
import '../../presentation/views/account_create_view.dart';
import '../../presentation/views/characters_view.dart';
import '../../presentation/views/home_view.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

/// Route names for easier referencing
class AppRouteNames {
  static const home = 'home';
  static const about = 'about';
  static const accountCreate = 'account_create';
  static const characters = 'characters';
  static const editCharacter = 'edit_character';
}

/// Paths to keep URL structure consistent
class AppPaths {
  static const home = '/home';
  static const about = '/about';
  static const accountCreate = '/account-create';
  static const characters = '/characters';
  static const editCharacter = '/edit/:id';
}

/// app routers using go_router
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: AppPaths.home,
    routes: <RouteBase>[
      GoRoute(
        path: AppPaths.home,
        name: AppRouteNames.home,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: HomeView()),
      ),
      GoRoute(
        path: AppPaths.accountCreate,
        name: AppRouteNames.accountCreate,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: AccountCreateView()),
      ),
      GoRoute(
        path: AppPaths.characters,
        name: AppRouteNames.characters,
        pageBuilder: (context, state) {
          final account = state.extra as Account;
          return NoTransitionPage(child: CharactersView(account: account));
        },
      ),
      GoRoute(
        path: AppPaths.about,
        name: AppRouteNames.about,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: AboutView()),
      ),
      GoRoute(
        path: AppPaths.editCharacter,
        name: AppRouteNames.editCharacter,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!; // Captura o ID da URL
          return NoTransitionPage(
            child: Scaffold(
              appBar: AppBar(title: const Text('Editando')),
              body: Center(child: Text('Editando o personagem ID: $id')),
            ),
          );
        },
      ),
    ],
  );
}
