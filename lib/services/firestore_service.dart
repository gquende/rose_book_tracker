import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Referência à coleção de livros de um utilizador
  CollectionReference _booksCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('books');
  }

  /// Stream em tempo real dos livros do utilizador
  Stream<List<Book>> getBooksStream(String userId) {
    return _booksCollection(userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Book.fromFirestore(doc))
            .toList());
  }

  /// Adicionar livro
  Future<String> addBook(String userId, Book book) async {
    final docRef = await _booksCollection(userId).add(book.toFirestore());
    return docRef.id;
  }

  /// Actualizar livro existente
  Future<void> updateBook(String userId, String bookId, Book book) async {
    await _booksCollection(userId).doc(bookId).update(book.toFirestore());
  }

  /// Eliminar livro
  Future<void> deleteBook(String userId, String bookId) async {
    await _booksCollection(userId).doc(bookId).delete();
  }

  /// Adicionar sessão de leitura
  Future<void> addReadingSession(String userId, Map<String, dynamic> sessionData) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('readingSessions')
        .add(sessionData);
  }

  /// Actualizar progresso de páginas de um livro
  Future<void> updateBookProgress(String userId, String bookId, int currentPage) async {
    await _booksCollection(userId).doc(bookId).update({'currentPage': currentPage});
  }
}
