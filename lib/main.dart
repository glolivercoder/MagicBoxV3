import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:boxmagic/services/log_service.dart';
import 'package:boxmagic/services/database_helper.dart';
import 'package:boxmagic/services/preferences_service.dart';
import 'package:boxmagic/screens/main_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar o serviço de log
  final logService = LogService();
  await logService.initialize();
  logService.info('Aplicativo iniciado', category: 'app');

  // Inicializar o banco de dados
  try {
    // Se estiver na web, não precisa configurar o SQLite
    if (!kIsWeb) {
      // Configurar o SQLite FFI para desktop/mobile
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    
    // Inicializar o DatabaseHelper (funciona tanto na web quanto em dispositivos móveis)
    final dbHelper = DatabaseHelper();
    
    // Na web, não chamamos o getter database, pois ele lança uma exceção
    if (!kIsWeb) {
      await dbHelper.database;
    }
    
    logService.info('Banco de dados inicializado com sucesso', category: 'database');
  } catch (e) {
    logService.error('Erro ao inicializar banco de dados: $e', category: 'database');
  }

  // Run the app
  runApp(const BoxMagicApp());
}

class BoxMagicApp extends StatelessWidget {
  const BoxMagicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BoxMagic',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2), // Primary color from HTML reference
          primary: const Color(0xFF1976D2),
          secondary: const Color(0xFFF50057), // Secondary color from HTML reference
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1976D2),
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF1976D2),
          foregroundColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2),
          primary: const Color(0xFF1976D2),
          secondary: const Color(0xFFF50057),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const MainScreen(),
    );
  }
}
