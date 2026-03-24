import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/book_provider.dart';
import '../services/notification_service.dart';
import '../widgets/book_statistics_chart.dart';
import '../config/routes.dart';

class BookListScreen extends StatefulWidget {
  final String? filterStatus;
  const BookListScreen({super.key, this.filterStatus});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  final Color rosaBebe = const Color(0xFFFFB7C5);

  // --- MENU DE ADIÇÃO (SCANNER / MANUAL) ---
  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        height: 180,
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.qr_code_scanner, color: Colors.blue),
              title: const Text("Scanear Código ISBN"),
              onTap: () async {
                Navigator.pop(ctx);
                final String? barcode = await Navigator.pushNamed(context, AppRoutes.scanner) as String?;
                if (barcode != null && mounted) {
                  Navigator.pushNamed(context, AppRoutes.addEditBook);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_note, color: Colors.orange),
              title: const Text("Inserir Manualmente"),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, AppRoutes.addEditBook);
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- GPS ---
  Future<void> _openNearbyLibraries() async {
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=livrarias');
    final Uri geoUrl = Uri.parse('geo:0,0?q=livrarias');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(geoUrl)) {
        await launchUrl(geoUrl);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao abrir o GPS.')));
      }
    }
  }

  // --- LEMBRETE COM NOTIFICAÇÃO ---
  Future<void> _scheduleReminder() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'A QUE HORAS QUERES LER?',
    );

    if (picked != null) {
      await NotificationService.testInstant();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lembrete configurado com sucesso!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _getFilteredLabel() {
    switch (widget.filterStatus) {
      case 'completed': return 'Livros Lidos';
      case 'currently-reading': return 'Livros a Ler';
      case 'want-to-read': return 'Quero Ler';
      default: return 'Meus Livros';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookProvider = Provider.of<BookProvider>(context);
    final stats = bookProvider.getStatistics();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
            widget.filterStatus == null ? 'A MINHA BIBLIOTECA' : _getFilteredLabel().toUpperCase(),
            style: const TextStyle(color: Colors.black45, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2)
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.notifications_active_outlined, color: rosaBebe),
            onSelected: (value) {
              if (value == 'notif') _scheduleReminder();
              if (value == 'gps') _openNearbyLibraries();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'notif',
                child: Row(children: [Icon(Icons.alarm, color: Colors.blue), SizedBox(width: 10), Text("Definir Lembrete")]),
              ),
              const PopupMenuItem(
                value: 'gps',
                child: Row(children: [Icon(Icons.map_outlined, color: Colors.green), SizedBox(width: 10), Text("Livrarias (GPS)")]),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: Colors.blueGrey),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(_getFilteredLabel(), style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: rosaBebe))),
                if (widget.filterStatus != null)
                  IconButton(
                    icon: const Icon(Icons.filter_list_off),
                    onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.bookList),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<BookProvider>(
              builder: (context, provider, child) {
                var books = provider.books;
                if (widget.filterStatus != null) {
                  books = books.where((b) => b.status == widget.filterStatus).toList();
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  children: [
                    if (widget.filterStatus == null) BookStatisticsChart(stats: stats),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                      child: Text(
                          'Lista de ${_getFilteredLabel()}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54)
                      ),
                    ),

                    if (books.isEmpty)
                      const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text('Nenhum livro encontrado.')))
                    else
                      ...books.map((book) {
                        Color statusColor;
                        switch (book.status) {
                          case 'completed': statusColor = Colors.green; break;
                          case 'currently-reading': statusColor = Colors.blue; break;
                          case 'want-to-read': statusColor = Colors.orange; break;
                          default: statusColor = rosaBebe;
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: BorderSide(color: statusColor.withOpacity(0.3), width: 1),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: statusColor.withOpacity(0.1),
                              child: Icon(Icons.book, color: statusColor),
                            ),
                            title: Text(book.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(book.author),
                            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                            onTap: () => Navigator.pushNamed(context, AppRoutes.bookDetail, arguments: book),
                          ),
                        );
                      }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: rosaBebe,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("NOVO LIVRO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showAddOptions(context),
      ),
    );
  }
}
