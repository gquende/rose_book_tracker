import 'package:flutter/material.dart';
import '../models/book.dart';
import '../screens/book_list_screen.dart';
import '../screens/book_detail_screen.dart';
import '../screens/add_edit_book_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/scanner_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String bookList = '/books';
  static const String bookDetail = '/books/detail';
  static const String addEditBook = '/books/edit';
  static const String profile = '/profile';
  static const String scanner = '/scanner';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case bookList:
        final filterStatus = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => BookListScreen(filterStatus: filterStatus),
        );

      case bookDetail:
        final book = settings.arguments as Book;
        return MaterialPageRoute(
          builder: (_) => BookDetailScreen(book: book),
        );

      case addEditBook:
        final book = settings.arguments as Book?;
        return MaterialPageRoute(
          builder: (_) => AddEditBookScreen(book: book),
        );

      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());

      case scanner:
        return MaterialPageRoute(builder: (_) => ScannerScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Rota não encontrada')),
          ),
        );
    }
  }
}
