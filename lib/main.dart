import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:book_library/providers/book_provider.dart';
import 'package:book_library/providers/auth_provider.dart' as src;
import 'package:book_library/providers/settings_provider.dart';
import 'package:book_library/repositories/book_repository.dart';
import 'package:book_library/screens/auth/login_screen.dart';
import 'package:book_library/screens/book_list_screen.dart';
import 'package:book_library/config/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Configuração do Firestore (Requisito 3: Persistência de dados)
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Repository partilhado por toda a app
    final bookRepository = BookRepository();

    return MultiProvider(
      providers: [
        // Provider 1: Autenticação
        ChangeNotifierProvider(create: (_) => src.AuthProvider()),

        // Provider 2: Configurações (Tema Escuro/Claro com persistência)
        ChangeNotifierProvider(create: (_) => SettingsProvider()),

        // Provider 3: Gestão de Livros (ProxyProvider ligado ao Auth)
        ChangeNotifierProxyProvider<src.AuthProvider, BookProvider>(
          create: (_) => BookProvider(repository: bookRepository),
          update: (context, auth, bookProvider) {
            return bookProvider!..updateUserId(auth.user?.uid);
          },
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return MaterialApp(
            title: 'Biblioteca de Livros',
            debugShowCheckedModeBanner: false,
            // Tema dinâmico: Muda conforme o SettingsProvider
            themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFFFFB7C5),
                brightness: Brightness.light,
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
            ),
            // Rotas nomeadas centralizadas
            onGenerateRoute: AppRoutes.onGenerateRoute,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<src.AuthProvider>(context);

    if (authProvider.user != null) {
      return const BookListScreen();
    } else {
      return const LoginScreen();
    }
  }
}
