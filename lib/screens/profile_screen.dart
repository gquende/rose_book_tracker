import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as src;
import '../providers/settings_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<src.AuthProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('O Meu Perfil')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_circle, size: 80, color: Color(0xFFFFB7C5)),
            const SizedBox(height: 10),
            Text(
              auth.user?.email ?? 'Utilizador',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'ID: ${auth.user?.uid ?? ""}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // Toggle de tema escuro/claro
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: SwitchListTile(
                title: const Text('Modo Escuro'),
                secondary: Icon(
                  settings.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: const Color(0xFFFFB7C5),
                ),
                value: settings.isDarkMode,
                onChanged: (_) => settings.toggleTheme(),
              ),
            ),

            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                auth.logout();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text('SAIR DA CONTA', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
