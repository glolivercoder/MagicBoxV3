import 'package:flutter/material.dart';
import 'package:boxmagic/services/log_service.dart';
import 'package:boxmagic/screens/boxes_screen.dart';
import 'package:boxmagic/screens/items_screen.dart';
import 'package:boxmagic/screens/users_screen.dart';
import 'package:boxmagic/screens/settings_screen.dart'; // Adicione essa linha
import 'package:boxmagic/screens/logs_screen.dart'; // Adicione essa linha

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final LogService _logService = LogService();

  // Referências para as telas
  late final BoxesScreen _boxesScreen;
  late final ItemsScreen _itemsScreen;
  late final UsersScreen _usersScreen;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // Inicializar as telas
    _boxesScreen = const BoxesScreen();
    _itemsScreen = const ItemsScreen();
    _usersScreen = const UsersScreen();
    
    _screens = [
      _boxesScreen,
      _itemsScreen,
      _usersScreen,
    ];
    
    _initializeLogService();
  }

  Future<void> _initializeLogService() async {
    _logService.info('Aplicativo iniciado', category: 'app');
  }

  // Métodos para ações da barra de ferramentas
  void _showBarcodeScanner() {
    if (_selectedIndex == 0) {
      _logService.info('Iniciando scanner de código de barras', category: 'scanner');
      _boxesScreen.showBarcodeScanner(context);
    }
  }

  void _showBoxIdRecognition() {
    if (_selectedIndex == 0) {
      _logService.info('Iniciando reconhecimento de ID de caixa', category: 'recognition');
      _boxesScreen.showBoxIdRecognition(context);
    }
  }

  void _showPrintLabelsDialog() {
    if (_selectedIndex == 0) {
      _logService.info('Abrindo diálogo de impressão de etiquetas', category: 'print');
      _boxesScreen.showPrintLabelsDialog(context);
    }
  }

  void _showNewBoxDialog() {
    if (_selectedIndex == 0) {
      _logService.info('Abrindo diálogo de nova caixa', category: 'box');
      _boxesScreen.showNewBoxDialog(context);
    } else if (_selectedIndex == 1) {
      _logService.info('Abrindo diálogo de nova caixa a partir da tela de itens', category: 'box');
      _itemsScreen.showNewBoxDialog(context);
    }
  }

  void _generateReport() {
    if (_selectedIndex == 1) {
      _logService.info('Gerando relatório de itens', category: 'report');
      _itemsScreen.generateReport(context);
    }
  }

  void _showObjectRecognition() {
    if (_selectedIndex == 1) {
      _logService.info('Iniciando reconhecimento de objeto', category: 'recognition');
      _itemsScreen.showObjectRecognition(context);
    }
  }

  void _openSettings() {
    _logService.info('Abrindo configurações', category: 'navigation');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  void _openLogs() {
    _logService.info('Tela de logs aberta pelo usuário', category: 'navigation');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LogsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/images/magicbox_mascot.png',
            fit: BoxFit.contain,
            width: 84,
            height: 84,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.inventory_2,
                size: 64,
                color: Colors.white,
              );
            },
          ),
        ),
        title: const Text(
          'MagicBox',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Botões específicos para a aba de Caixas
          if (_selectedIndex == 0) ...[
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: _showBarcodeScanner,
              tooltip: 'Escanear código de barras',
            ),
            IconButton(
              icon: const Icon(Icons.camera_alt),
              onPressed: _showBoxIdRecognition,
              tooltip: 'Reconhecer ID com IA',
            ),
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: _showPrintLabelsDialog,
              tooltip: 'Imprimir etiquetas',
            ),
          ],

          // Botões específicos para a aba de Objetos
          if (_selectedIndex == 1) ...[
            IconButton(
              icon: const Icon(Icons.add_box),
              onPressed: _showNewBoxDialog,
              tooltip: 'Criar nova caixa',
            ),
            IconButton(
              icon: const Icon(Icons.summarize),
              onPressed: _generateReport,
              tooltip: 'Gerar relatório',
            ),
            IconButton(
              icon: const Icon(Icons.camera_alt),
              onPressed: _showObjectRecognition,
              tooltip: 'Identificar objeto com IA',
            ),
          ],

          // Botão de logs (sempre visível)
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _openLogs,
            tooltip: 'Logs do sistema',
          ),

          // Botão de configurações (sempre visível)
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
            tooltip: 'Configurações',
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inbox),
            label: 'Caixas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Objetos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Usuários',
          ),
        ],
      ),
    );
  }
}
