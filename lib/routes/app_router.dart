import 'package:go_router/go_router.dart';
import 'package:seminari_flutter/screens/auth/login_screen.dart';
import 'package:seminari_flutter/screens/auth/register_screen.dart';
import 'package:seminari_flutter/screens/complete_profile_screen.dart';
import 'package:seminari_flutter/screens/edit_screen.dart';
import 'package:seminari_flutter/screens/home_screen.dart';
import 'package:seminari_flutter/screens/contactList_screen.dart';
import 'package:seminari_flutter/screens/perfil_screen.dart';
import 'package:seminari_flutter/widgets/Layout.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    // Ruta de Login
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),

    // Ruta de Registro
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),

    // Ruta de Contact List (Chat)
    GoRoute(
      path: '/contactList',
      builder: (context, state) => LayoutWrapper(
        title: 'Chat',
        child: const ContactListScreen(),
      ),
    ),

    // Ruta de Home
    GoRoute(
      path: '/',
      builder: (context, state) => LayoutWrapper(
        title: 'Home',
        child: const HomeScreen(),
      ),
      routes: [
        // Subruta de Editar Perfil
        GoRoute(
          path: 'edit',
          builder: (context, state) => const EditScreen(),
        ),

        // Subruta de Perfil
        GoRoute(
          path: 'profile',
          builder: (context, state) => LayoutWrapper(
            title: 'Profile',
            child: const ProfileScreen(),
          ),
        ),

        // Subruta de Completar Perfil
        GoRoute(
          path: 'complete-profile',
          builder: (context, state) => CompleteProfileScreen(),
        ),
      ],
    ),
  ],
);
