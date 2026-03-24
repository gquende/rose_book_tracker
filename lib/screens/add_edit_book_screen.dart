import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/book.dart';
import '../providers/book_provider.dart';
import '../services/scanner_service.dart';

class AddEditBookScreen extends StatefulWidget {
  final Book? book;
  const AddEditBookScreen({super.key, this.book});

  @override
  State<AddEditBookScreen> createState() => _AddEditBookScreenState();
}

class _AddEditBookScreenState extends State<AddEditBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _genreController;
  late TextEditingController _pagesController;
  late TextEditingController _currentPageController;
  late TextEditingController _notesController;
  late TextEditingController _locationController;
  late TextEditingController _purchaseDateController;

  DateTime? _selectedPurchaseDate;
  String _selectedStatus = 'want-to-read';
  double _rating = 0.0;
  bool _isSaving = false;
  bool _isLoadingScan = false;
  File? _imageFile;

  final List<String> _statusOptions = ['want-to-read', 'currently-reading', 'completed'];

  @override
  void initState() {
    super.initState();
    final book = widget.book;
    _titleController = TextEditingController(text: book?.title ?? '');
    _authorController = TextEditingController(text: book?.author ?? '');
    _genreController = TextEditingController(text: book?.genre ?? '');
    _pagesController = TextEditingController(text: book?.totalPages.toString() ?? '');
    _currentPageController = TextEditingController(text: book?.currentPage.toString() ?? '0');
    _notesController = TextEditingController(text: book?.notes ?? '');
    _locationController = TextEditingController(text: book?.location ?? '');
    _selectedPurchaseDate = book?.purchaseDate;
    _purchaseDateController = TextEditingController(
        text: _selectedPurchaseDate != null ? DateFormat('dd/MM/yyyy').format(_selectedPurchaseDate!) : ''
    );

    if (book != null) {
      _selectedStatus = book.status;
      _rating = book.rating;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _genreController.dispose();
    _pagesController.dispose();
    _currentPageController.dispose();
    _notesController.dispose();
    _locationController.dispose();
    _purchaseDateController.dispose();
    super.dispose();
  }

  // --- PESQUISA POR ISBN VIA PROVIDER/REPOSITORY ---
  Future<void> _fetchBookByIsbn(String isbn) async {
    final cleanIsbn = isbn.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanIsbn.isEmpty) return;

    setState(() => _isLoadingScan = true);

    try {
      final bookProvider = Provider.of<BookProvider>(context, listen: false);
      final info = await bookProvider.searchByIsbn(cleanIsbn);

      if (info != null) {
        _fillFormWithGoogleData(info);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Livro encontrado!'), backgroundColor: Colors.green),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Código não reconhecido como um livro.'), backgroundColor: Colors.orange),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro de ligação. Verifica a internet.'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingScan = false);
    }
  }

  void _fillFormWithGoogleData(Map<String, dynamic> info) {
    setState(() {
      _titleController.text = info['title'] ?? '';
      _authorController.text = (info['authors'] as List?)?.join(', ') ?? '';
      _genreController.text = (info['categories'] as List?)?.first ?? '';
      _pagesController.text = info['pageCount']?.toString() ?? '';
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final bookData = Book(
        id: widget.book?.id ?? '',
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        genre: _genreController.text.trim(),
        totalPages: int.tryParse(_pagesController.text) ?? 0,
        currentPage: int.tryParse(_currentPageController.text) ?? 0,
        status: _selectedStatus,
        rating: _rating,
        notes: _notesController.text.trim(),
        timestamp: widget.book?.timestamp ?? DateTime.now(),
        location: _locationController.text.trim(),
        purchaseDate: _selectedPurchaseDate,
      );

      await Provider.of<BookProvider>(context, listen: false).saveBook(bookData, _imageFile);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book != null ? 'Editar Livro' : 'Novo Livro'),
        actions: [
          if (_isLoadingScan)
            const Center(child: Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
          else
            IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: () async {
                  String? isbn = await ScannerService.scanBarcode(context);
                  if (isbn != null) _fetchBookByIsbn(isbn);
                }
            ),
          IconButton(icon: const Icon(Icons.camera_alt), onPressed: _pickImage),
          IconButton(icon: const Icon(Icons.check), onPressed: _isSaving ? null : _saveForm),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_imageFile != null) ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(_imageFile!, height: 200, width: double.infinity, fit: BoxFit.cover)),
              const SizedBox(height: 15),
              TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'Título *', border: OutlineInputBorder()), validator: (val) => val!.isEmpty ? 'Obrigatório' : null),
              const SizedBox(height: 15),
              TextFormField(controller: _authorController, decoration: const InputDecoration(labelText: 'Autor *', border: OutlineInputBorder()), validator: (val) => val!.isEmpty ? 'Obrigatório' : null),
              const SizedBox(height: 15),
              TextFormField(controller: _locationController, decoration: const InputDecoration(labelText: 'Localização (Estante/Sala)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.place))),
              const SizedBox(height: 15),
              TextFormField(
                controller: _purchaseDateController,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Data de Compra', border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_today)),
                onTap: () async {
                  DateTime? picked = await showDatePicker(context: context, initialDate: _selectedPurchaseDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime.now());
                  if (picked != null) setState(() { _selectedPurchaseDate = picked; _purchaseDateController.text = DateFormat('dd/MM/yyyy').format(picked); });
                },
              ),
              const SizedBox(height: 15),
              TextFormField(controller: _genreController, decoration: const InputDecoration(labelText: 'Género', border: OutlineInputBorder())),
              const SizedBox(height: 15),
              Row(children: [
                Expanded(child: TextFormField(controller: _pagesController, decoration: const InputDecoration(labelText: 'Total Pág.', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(child: TextFormField(controller: _currentPageController, decoration: const InputDecoration(labelText: 'Pág. Atual', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
              ]),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(labelText: 'Estado', border: OutlineInputBorder()),
                items: _statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s == 'want-to-read' ? 'Quero ler' : s == 'currently-reading' ? 'A ler' : 'Lido'))).toList(),
                onChanged: (val) => setState(() => _selectedStatus = val!),
              ),
              const SizedBox(height: 10),
              Slider(value: _rating, min: 0, max: 5, divisions: 10, label: _rating.toString(), onChanged: (val) => setState(() => _rating = val)),
              TextFormField(controller: _notesController, decoration: const InputDecoration(labelText: 'Notas', border: OutlineInputBorder()), maxLines: 2),
            ],
          ),
        ),
      ),
    );
  }
}
