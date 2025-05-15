import 'package:go_router/go_router.dart';
import 'package:seminari_flutter/screens/auth/login_screen.dart';
import 'package:seminari_flutter/screens/auth/register_screen.dart';
import 'package:seminari_flutter/screens/edit_screen.dart';
import 'package:seminari_flutter/screens/home_screen.dart';
import 'package:seminari_flutter/screens/contactList_screen.dart';
import 'package:seminari_flutter/screens/perfil_screen.dart';
import 'package:seminari_flutter/services/auth_service.dart';
import 'package:seminari_flutter/widgets/Layout.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AuthService().isLoggedIn ? '/' : '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => LoginPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => RegisterPage(),
    ),
    GoRoute(
      path: '/contactList',
      builder: (context, state) => LayoutWrapper(
        title: 'Chat',
        child: ContactListScreen(),
      ),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => LayoutWrapper(
        title: 'Home',
        child: HomeScreen(),
      ),
      routes: [
        GoRoute(
          path: 'edit',
          builder: (context, state) => const EditScreen(),
        ),
        GoRoute(
          path: 'profile',
          builder: (context, state) => LayoutWrapper(
            title: 'Profile',
            child: ProfileScreen(),
          ),
        ),
      ],
    ),
  ],
);
