import 'dart:convert';
import 'package:http/http.dart' as http;

class GoogleBooksService {
  static const String _baseUrl = 'https://www.googleapis.com/books/v1/volumes';

  /// Pesquisa um livro por ISBN e retorna os dados do volumeInfo
  Future<Map<String, dynamic>?> fetchBookByIsbn(String isbn) async {
    final cleanIsbn = isbn.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanIsbn.isEmpty) return null;

    try {
      final url = Uri.parse('$_baseUrl?q=isbn:$cleanIsbn');
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['totalItems'] != null && data['totalItems'] > 0) {
          return data['items'][0]['volumeInfo'] as Map<String, dynamic>;
        }
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  /// Busca descrição e imagem de capa por título
  Future<Map<String, dynamic>?> fetchBookDescription(String title) async {
    try {
      final url = Uri.parse('$_baseUrl?q=intitle:$title');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['items'] != null && data['items'].isNotEmpty) {
          final info = data['items'][0]['volumeInfo'];
          return {
            'description': info['description'] ?? 'Sem descrição disponível.',
            'imageUrl': info['imageLinks']?['thumbnail'],
          };
        }
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  /// Busca livros semelhantes pelo mesmo autor
  Future<List<dynamic>> fetchSimilarBooks(String author) async {
    try {
      final url = Uri.parse('$_baseUrl?q=inauthor:$author&maxResults=5');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['items'] ?? [];
      }
    } catch (e) {
      rethrow;
    }
    return [];
  }
}
