import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../services/google_books_service.dart';

class BookRepository {
  final FirestoreService _firestoreService;
  final StorageService _storageService;
  final GoogleBooksService _googleBooksService;

  BookRepository({
    FirestoreService? firestoreService,
    StorageService? storageService,
    GoogleBooksService? googleBooksService,
  })  : _firestoreService = firestoreService ?? FirestoreService(),
        _storageService = storageService ?? StorageService(),
        _googleBooksService = googleBooksService ?? GoogleBooksService();

  /// Stream em tempo real dos livros do utilizador
  Stream<List<Book>> getBooksStream(String userId) {
    return _firestoreService.getBooksStream(userId);
  }

  /// Guardar livro (criar ou actualizar) com upload de imagem opcional
  Future<void> saveBook(String userId, Book book, File? imageFile) async {
    String? imageUrl = book.imageUrl;

    // Upload de imagem se fornecida
    if (imageFile != null) {
      String bookId = book.id.isEmpty
          ? DateTime.now().millisecondsSinceEpoch.toString()
          : book.id;
      imageUrl = await _storageService.uploadBookCover(userId, bookId, imageFile);
    }

    // Preenchimento automático: se o livro está completo, a página actual = total
    int finalCurrentPage = book.currentPage;
    if (book.status.toLowerCase() == 'completed' || book.status == 'Lido') {
      finalCurrentPage = book.totalPages;
    }

    final bookToSave = book.copyWith(
      imageUrl: imageUrl,
      currentPage: finalCurrentPage,
    );

    if (book.id.isEmpty) {
      await _firestoreService.addBook(userId, bookToSave);
    } else {
      await _firestoreService.updateBook(userId, book.id, bookToSave);
    }
  }

  /// Eliminar livro
  Future<void> deleteBook(String userId, String bookId) async {
    await _firestoreService.deleteBook(userId, bookId);
  }

  /// Registar sessão de leitura com actualização de progresso
  Future<void> addReadingSession({
    required String userId,
    required String bookId,
    required int startPage,
    required int endPage,
    required int duration,
  }) async {
    final sessionData = {
      'bookId': bookId,
      'startPage': startPage,
      'endPage': endPage,
      'duration': duration,
      'date': FieldValue.serverTimestamp(),
    };

    await _firestoreService.addReadingSession(userId, sessionData);
    await _firestoreService.updateBookProgress(userId, bookId, endPage);
  }

  // --- Delegação para Google Books API ---

  /// Pesquisa livro por ISBN
  Future<Map<String, dynamic>?> searchByIsbn(String isbn) {
    return _googleBooksService.fetchBookByIsbn(isbn);
  }

  /// Busca descrição e imagem de um livro por título
  Future<Map<String, dynamic>?> fetchBookDescription(String title) {
    return _googleBooksService.fetchBookDescription(title);
  }

  /// Busca livros semelhantes por autor
  Future<List<dynamic>> fetchSimilarBooks(String author) {
    return _googleBooksService.fetchSimilarBooks(author);
  }
}
