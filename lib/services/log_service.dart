import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Níveis de log do sistema
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Representa uma entrada de log no sistema
class LogEntry {
  final LogLevel level;
  final String message;
  final String? stackTrace;
  final String timestamp;
  final String? category;

  LogEntry({
    required this.level,
    required this.message,
    this.stackTrace,
    required this.timestamp,
    this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'level': level.toString().split('.').last,
      'message': message,
      'stackTrace': stackTrace,
      'timestamp': timestamp,
      'category': category,
    };
  }

  factory LogEntry.fromMap(Map<String, dynamic> map) {
    return LogEntry(
      level: LogLevel.values.firstWhere(
        (e) => e.toString().split('.').last == map['level'],
        orElse: () => LogLevel.info,
      ),
      message: map['message'] ?? '',
      stackTrace: map['stackTrace'],
      timestamp: map['timestamp'] ?? DateTime.now().toIso8601String(),
      category: map['category'],
    );
  }

  String toJson() => jsonEncode(toMap());

  factory LogEntry.fromJson(String source) => LogEntry.fromMap(jsonDecode(source));

  @override
  String toString() {
    return '[$timestamp] ${level.toString().split('.').last.toUpperCase()}: $message${stackTrace != null ? '\n$stackTrace' : ''}';
  }
}

/// Serviço de log para substituir o uso de print em código de produção
/// Seguindo as regras de código limpo definidas no projeto
class LogService {
  static final LogService _instance = LogService._internal();
  
  factory LogService() {
    return _instance;
  }
  
  LogService._internal();
  
  static const int _maxLogEntries = 1000; // Limite de entradas de log armazenadas
  static const String _logsKey = 'boxmagic_logs';
  static const String _logsEnabledKey = 'boxmagic_logs_enabled';
  static const String _logFileName = 'MAGICBOX.log';
  
  final List<LogEntry> _logs = [];
  bool _isDebugMode = true;
  bool _initialized = false;
  bool _enabled = true; // Por padrão, o logging está ativado
  
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Carregar configuração de ativação/desativação
      await _loadLoggingState();

      // Carregar logs armazenados
      await _loadLogs();
      _initialized = true;
      log(LogLevel.info, 'LogService inicializado com sucesso', category: 'system');
    } catch (e, stackTrace) {
      // Não podemos usar o próprio log aqui para evitar recursão
      debugPrint('Erro ao inicializar LogService: $e');
      debugPrint(stackTrace.toString());
    }
  }
  
  Future<void> _loadLoggingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_logsEnabledKey) ?? true; // Por padrão, ativado
    } catch (e) {
      debugPrint('Erro ao carregar estado do logging: $e');
      _enabled = true; // Em caso de erro, manter ativado por padrão
    }
  }
  
  Future<bool> setLoggingEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_logsEnabledKey, enabled);
      _enabled = enabled;

      if (enabled) {
        // Registrar que o logging foi ativado
        final entry = LogEntry(
          level: LogLevel.info,
          message: 'Logging ativado pelo usuário',
          timestamp: DateTime.now().toIso8601String(),
          category: 'system',
        );
        _logs.add(entry);
        await _saveLogs();
      }

      return true;
    } catch (e) {
      debugPrint('Erro ao definir estado do logging: $e');
      return false;
    }
  }
  
  Future<bool> isLoggingEnabled() async {
    return _enabled;
  }
  
  void setDebugMode(bool isDebugMode) {
    _isDebugMode = isDebugMode;
  }
  
  void debug(String message, {String? category}) {
    if (_isDebugMode) {
      log(LogLevel.debug, message, category: category);
    }
  }
  
  void info(String message, {String? category}) {
    log(LogLevel.info, message, category: category);
  }
  
  void warning(String message, {String? category}) {
    log(LogLevel.warning, message, category: category);
  }
  
  void error(String message, {Object? error, StackTrace? stackTrace, String? category}) {
    final errorStr = error != null ? ': $error' : '';
    final stackTraceStr = stackTrace?.toString();

    // Adicionar informações do sistema para ajudar no diagnóstico
    final systemInfo = 'Platform: ${kIsWeb ? 'Web' : 'Native'}, '
        'Time: ${DateTime.now().toIso8601String()}';

    log(LogLevel.error, '$message$errorStr\n$systemInfo',
        stackTrace: stackTraceStr,
        category: category);

    // Em modo de desenvolvimento, também imprimir no console para facilitar o debug
    if (kDebugMode) {
      print('❌ ERROR [$category]: $message$errorStr');
      if (stackTraceStr != null) {
        print(stackTraceStr);
      }
    }
  }
  
  void log(LogLevel level, String message, {String? stackTrace, String? category}) {
    if (!_initialized) {
      // Se o serviço não foi inicializado, inicialize-o
      initialize();
    }

    if (!_enabled && level != LogLevel.error) {
      // Se o logging está desativado, ignorar logs que não sejam de erro
      return;
    }

    final timestamp = DateTime.now().toIso8601String();
    final entry = LogEntry(
      level: level,
      message: message,
      stackTrace: stackTrace,
      timestamp: timestamp,
      category: category,
    );

    // Adicionar à lista em memória
    _logs.add(entry);

    // Limitar o número de logs em memória
    if (_logs.length > _maxLogEntries) {
      _logs.removeAt(0);
    }

    // Imprimir no console em modo de desenvolvimento
    if (kDebugMode) {
      final categoryStr = category != null ? '[$category]' : '';
      switch (level) {
        case LogLevel.info:
          debugPrint('ℹ️ INFO: $categoryStr $message');
          break;
        case LogLevel.warning:
          debugPrint('⚠️ WARNING: $categoryStr $message');
          break;
        case LogLevel.error:
          debugPrint('❌ ERROR: $categoryStr $message');
          if (stackTrace != null) {
            debugPrint(stackTrace);
          }
          break;
        case LogLevel.debug:
          debugPrint('🔍 DEBUG: $categoryStr $message');
          break;
      }
    }

    // Salvar logs periodicamente
    _saveLogs();
    
    // Salvar no arquivo de log específico
    _saveToLogFile(entry);
  }
  
  // Obter todos os logs
  List<LogEntry> getLogs() {
    return List.unmodifiable(_logs);
  }

  // Obter logs filtrados por nível
  List<LogEntry> getLogsByLevel(LogLevel level) {
    return _logs.where((log) => log.level == level).toList();
  }

  // Obter logs filtrados por categoria
  List<LogEntry> getLogsByCategory(String category) {
    return _logs.where((log) => log.category == category).toList();
  }
  
  // Obter a contagem de logs
  Future<int> getLogCount() async {
    return _logs.length;
  }

  // Limpar todos os logs
  Future<void> clearLogs() async {
    _logs.clear();
    await _saveLogs();
    log(LogLevel.info, 'Logs limpos', category: 'system');
  }
  
  // Carregar logs do armazenamento
  Future<void> _loadLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = prefs.getStringList(_logsKey) ?? [];

      _logs.clear();
      for (final logJson in logsJson) {
        try {
          final entry = LogEntry.fromJson(logJson);
          _logs.add(entry);
        } catch (e) {
          // Ignorar entradas inválidas
          debugPrint('Erro ao carregar entrada de log: $e');
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar logs: $e');
    }
  }

  // Salvar logs no armazenamento
  Future<void> _saveLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = _logs.map((e) => e.toJson()).toList();
      await prefs.setStringList(_logsKey, logsJson);
    } catch (e) {
      debugPrint('Erro ao salvar logs: $e');
    }
  }
  
  // Salvar log no arquivo específico
  Future<void> _saveToLogFile(LogEntry entry) async {
    if (kIsWeb) {
      // No ambiente web, não podemos salvar em arquivo
      return;
    }
    
    try {
      Directory? directory;
      
      try {
        // Tentar obter o diretório de downloads
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          // Se não existir, tentar o diretório de documentos
          directory = await getExternalStorageDirectory();
        }
      } catch (e) {
        // Em caso de erro, usar o diretório de documentos
        directory = await getApplicationDocumentsDirectory();
      }
      
      if (directory == null) {
        debugPrint('Não foi possível obter o diretório para salvar o log');
        return;
      }
      
      final file = File('${directory.path}/$_logFileName');
      final exists = await file.exists();
      
      // Formatar a entrada de log
      final categoryStr = entry.category != null ? '[${entry.category}]' : '';
      final levelStr = entry.level.toString().split('.').last.toUpperCase();
      final logLine = '${entry.timestamp} [$levelStr] $categoryStr ${entry.message}\n';
      
      if (exists) {
        // Adicionar ao arquivo existente
        await file.writeAsString(logLine, mode: FileMode.append);
      } else {
        // Criar novo arquivo
        await file.writeAsString(logLine);
      }
    } catch (e) {
      debugPrint('Erro ao salvar log no arquivo: $e');
    }
  }
  
  // Exportar logs para um arquivo
  Future<String?> exportLogs() async {
    try {
      if (_logs.isEmpty) {
        return null;
      }

      if (kIsWeb) {
        // Para web, retornamos uma string JSON
        final logsJson = jsonEncode(_logs.map((e) => e.toMap()).toList());
        return logsJson;
      } else {
        // Para dispositivos móveis, salvamos em um arquivo
        Directory? directory;
        
        try {
          // Tentar obter o diretório de downloads
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            // Se não existir, tentar o diretório de documentos
            directory = await getExternalStorageDirectory();
          }
        } catch (e) {
          // Em caso de erro, usar o diretório de documentos
          directory = await getApplicationDocumentsDirectory();
        }
        
        if (directory == null) {
          return null;
        }
        
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final path = '${directory.path}/boxmagic_logs_$timestamp.txt';
        final file = File(path);

        final buffer = StringBuffer();
        for (final entry in _logs) {
          buffer.writeln(entry.toString());
        }

        await file.writeAsString(buffer.toString());
        return path;
      }
    } catch (e, stackTrace) {
      debugPrint('Erro ao exportar logs: $e');
      debugPrint(stackTrace.toString());
      return null;
    }
  }
}
