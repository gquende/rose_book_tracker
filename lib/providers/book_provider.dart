import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/book.dart';
import '../repositories/book_repository.dart';

class BookProvider with ChangeNotifier {
  final BookRepository _repository;
  List<Book> _books = [];
  String _searchQuery = '';
  String? _userId;
  bool _isLoading = false;
  StreamSubscription? _subscription;

  BookProvider({BookRepository? repository})
      : _repository = repository ?? BookRepository();

  // Getters
  bool get isLoading => _isLoading;

  // Lista de livros filtrada pela pesquisa
  List<Book> get books {
    if (_searchQuery.isEmpty) return _books;
    return _books.where((book) =>
        book.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        book.author.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  // Atualiza o ID do utilizador e sincroniza os dados
  void updateUserId(String? uid) {
    if (_userId == uid) return;
    _userId = uid;

    // Cancelar listener anterior para evitar memory leak
    _subscription?.cancel();
    _subscription = null;

    if (_userId == null) {
      _books = [];
      _isLoading = false;
      notifyListeners();
    } else {
      _fetchBooks();
    }
  }

  // --- LISTAGEM EM TEMPO REAL ---
  void _fetchBooks() {
    if (_userId == null) return;
    _isLoading = true;

    _subscription = _repository.getBooksStream(_userId!).listen(
      (books) {
        _books = books;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint("Erro ao carregar livros: $e");
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // --- GUARDAR LIVRO (CRIAR OU ACTUALIZAR) ---
  Future<void> saveBook(Book book, File? imageFile) async {
    if (_userId == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.saveBook(_userId!, book, imageFile);
    } catch (e) {
      debugPrint("Erro ao guardar livro: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- ELIMINAR LIVRO ---
  Future<void> deleteBook(String id) async {
    if (_userId == null) return;
    await _repository.deleteBook(_userId!, id);
  }

  // --- SESSÕES DE LEITURA ---
  Future<void> addReadingSession({
    required String bookId,
    required int startPage,
    required int endPage,
    required int duration,
  }) async {
    if (_userId == null) return;
    try {
      await _repository.addReadingSession(
        userId: _userId!,
        bookId: bookId,
        startPage: startPage,
        endPage: endPage,
        duration: duration,
      );
    } catch (e) {
      debugPrint("Erro na sessão: $e");
    }
  }

  // --- INTEGRAÇÃO API (GOOGLE BOOKS) ---
  Future<Map<String, dynamic>?> searchByIsbn(String isbn) {
    return _repository.searchByIsbn(isbn);
  }

  Future<Map<String, dynamic>?> fetchBookDescription(String title) {
    return _repository.fetchBookDescription(title);
  }

  Future<List<dynamic>> fetchSimilarBooks(String author) {
    return _repository.fetchSimilarBooks(author);
  }

  // --- ESTATÍSTICAS ---
  Map<String, int> getStatistics() {
    return {
      'total': _books.length,
      'completed': _books.where((b) => b.status == 'completed' || b.status == 'Lido').length,
      'currentlyReading': _books.where((b) => b.status == 'currently-reading' || b.status == 'A Ler').length,
      'wantToRead': _books.where((b) => b.status == 'want-to-read' || b.status == 'Quero Ler').length,
    };
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
