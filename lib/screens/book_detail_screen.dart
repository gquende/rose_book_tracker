import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/book.dart';
import '../providers/book_provider.dart';
import '../config/routes.dart';

class BookDetailScreen extends StatefulWidget {
  final Book book;

  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final Color rosaBebe = const Color(0xFFFFB7C5);
  String _externalDescription = "A carregar descrição da API...";
  String? _apiImageUrl;
  bool _isSearchingSimilar = false;

  @override
  void initState() {
    super.initState();
    _fetchExternalData();
  }

  // --- BUSCAR SINOPSE E IMAGEM DA API ---
  Future<void> _fetchExternalData() async {
    try {
      final bookProvider = Provider.of<BookProvider>(context, listen: false);
      final data = await bookProvider.fetchBookDescription(widget.book.title);

      if (mounted && data != null) {
        setState(() {
          _externalDescription = data['description'] ?? "Sem descrição disponível.";
          _apiImageUrl = data['imageUrl'];
        });
      } else if (mounted) {
        setState(() => _externalDescription = "Informação extra não encontrada.");
      }
    } catch (e) {
      if (mounted) setState(() => _externalDescription = "Erro ao ligar à API externa.");
    }
  }

  // --- GPS: ENCONTRAR LIVRARIAS ---
  Future<void> _procurarLivrarias() async {
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=livrarias+proximas');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Não foi possível abrir o mapa';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao abrir o GPS')),
        );
      }
    }
  }

  // --- PARTILHAR LIVRO ---
  void _shareBook() {
    final String message =
        "Estou a ler '${widget.book.title}' de ${widget.book.author}. Minha avaliação: ${widget.book.rating}/5!";
    Share.share(message);
  }

  // --- DIÁLOGO DE SESSÃO DE LEITURA ---
  void _showReadingSessionDialog(BuildContext context) {
    final pageController = TextEditingController();
    final durationController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Registar Sessão de Leitura"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Página atual: ${widget.book.currentPage}"),
            const SizedBox(height: 15),
            TextField(
              controller: pageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Leste até que página?", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Duração (minutos)", border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              int newPage = int.tryParse(pageController.text) ?? widget.book.currentPage;
              int duration = int.tryParse(durationController.text) ?? 0;

              await Provider.of<BookProvider>(context, listen: false)
                  .addReadingSession(
                  bookId: widget.book.id,
                  startPage: widget.book.currentPage,
                  endPage: newPage,
                  duration: duration,
              );
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text("Registar"),
          ),
        ],
      ),
    );
  }

  // --- LIVROS SEMELHANTES VIA API ---
  Future<void> _showSimilarBooks() async {
    setState(() => _isSearchingSimilar = true);
    try {
      final similarBooks = await Provider.of<BookProvider>(context, listen: false)
          .fetchSimilarBooks(widget.book.author);

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Mais livros deste autor", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: similarBooks.length,
                  itemBuilder: (context, i) {
                    final info = similarBooks[i]['volumeInfo'];
                    return ListTile(
                      leading: const Icon(Icons.book),
                      title: Text(info['title'] ?? 'Sem título'),
                      subtitle: Text(info['authors']?.join(', ') ?? 'Autor desconhecido'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro ao buscar livros semelhantes")),
        );
      }
    } finally {
      setState(() => _isSearchingSimilar = false);
    }
  }

  // --- ELIMINAR LIVRO ---
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Livro'),
        content: Text('Remover "${widget.book.title}" da estante?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              await Provider.of<BookProvider>(context, listen: false).deleteBook(widget.book.id);
              if (context.mounted) {
                Navigator.pop(ctx);
                Navigator.pop(context);
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _parseColor(dynamic colorData) {
    if (colorData is Color) return colorData;
    if (colorData is int) return Color(colorData);
    return Colors.grey;
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final purchaseDate = widget.book.purchaseDate != null
        ? DateFormat('dd/MM/yyyy').format(widget.book.purchaseDate!)
        : 'Não registada';

    final String displayNotes = (widget.book.notes == null || widget.book.notes!.isEmpty)
        ? 'Sem notas para este livro.'
        : widget.book.notes!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text('Detalhes do Livro', style: TextStyle(color: Colors.black87)),
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: _shareBook),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.addEditBook, arguments: widget.book),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- CAPA DO LIVRO (DA API) ---
            Center(
              child: Container(
                height: 250,
                width: 170,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(15.0),
                  boxShadow: [
                    BoxShadow(color: rosaBebe.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))
                  ],
                  image: _apiImageUrl != null
                      ? DecorationImage(image: NetworkImage(_apiImageUrl!), fit: BoxFit.cover)
                      : null,
                ),
                child: _apiImageUrl == null
                    ? Icon(Icons.book, size: 80, color: rosaBebe.withOpacity(0.5))
                    : null,
              ),
            ),
            const SizedBox(height: 30),

            // --- TÍTULO E AUTOR ---
            Text(widget.book.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 5),
            Text('por ${widget.book.author}', style: TextStyle(fontSize: 18, color: Colors.grey[600], fontStyle: FontStyle.italic)),
            const SizedBox(height: 20),

            // --- STATUS E PROGRESSO ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(widget.book.statusDisplay, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  backgroundColor: _parseColor(widget.book.statusColor),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                Text('${(widget.book.progressPercentage * 100).toStringAsFixed(0)}% Lido',
                    style: TextStyle(fontWeight: FontWeight.bold, color: rosaBebe)),
              ],
            ),

            // --- CARD DE PROGRESSO COM SESSÃO DE LEITURA ---
            const SizedBox(height: 15),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Progresso de Leitura', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('${(widget.book.progressPercentage * 100).toStringAsFixed(0)}%'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: widget.book.progressPercentage,
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(10),
                      backgroundColor: Colors.grey[200],
                      color: Colors.green,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Página ${widget.book.currentPage} de ${widget.book.totalPages}'),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.green, size: 30),
                          onPressed: () => _showReadingSessionDialog(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // --- DETALHES DO LIVRO ---
            const Divider(height: 40),
            _buildDetailRow(Icons.category, 'Género:', widget.book.genre),
            _buildDetailRow(Icons.star, 'Avaliação:', '${widget.book.rating} / 5.0'),
            _buildDetailRow(Icons.location_on, 'Localização:',
                (widget.book.location == null || widget.book.location!.isEmpty) ? 'Não definida' : widget.book.location!),
            _buildDetailRow(Icons.shopping_bag, 'Comprado em:', purchaseDate),
            _buildDetailRow(Icons.calendar_today, 'Adicionado:', _formatDate(widget.book.timestamp)),

            // --- NOTAS ---
            const SizedBox(height: 25),
            const Text('Minhas Notas:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(displayNotes, style: const TextStyle(fontSize: 15, height: 1.5)),
            ),

            // --- SINOPSE (GOOGLE BOOKS) ---
            const SizedBox(height: 30),
            const Text('Sinopse (Google Books):', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              _externalDescription,
              style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.6),
              textAlign: TextAlign.justify,
            ),

            // --- BOTÃO LIVROS SEMELHANTES ---
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _isSearchingSimilar
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.auto_stories),
                label: const Text("Descobrir livros semelhantes"),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                onPressed: _isSearchingSimilar ? null : _showSimilarBooks,
              ),
            ),

            // --- BOTÃO GPS ---
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _procurarLivrarias,
                icon: const Icon(Icons.location_on, color: Colors.white),
                label: const Text('ENCONTRAR LIVRARIAS PRÓXIMAS',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent.withOpacity(0.8),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: rosaBebe),
          const SizedBox(width: 15),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
