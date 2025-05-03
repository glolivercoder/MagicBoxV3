import 'dart:convert';
import 'dart:io';
import 'package:boxmagic/models/box.dart';
import 'package:boxmagic/models/item.dart';
import 'package:boxmagic/models/user.dart';
import 'package:boxmagic/services/log_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serviço responsável pela persistência de dados
/// 
/// Fornece métodos para salvar e carregar dados, independente da plataforma
/// (web ou dispositivos móveis)
class PersistenceService {
  static final PersistenceService _instance = PersistenceService._internal();
  final LogService _logService = LogService();

  // Chaves para armazenamento
  static const String _boxesKey = 'boxes';
  static const String _itemsKey = 'items';
  static const String _usersKey = 'users';

  // Chaves adicionais para configurações
  static const String _backupDirKey = 'backup_directory';
  static const String _lastBackupKey = 'last_backup_date';

  // Construtor privado para implementação do Singleton
  PersistenceService._internal();

  // Factory para retornar a instância única
  factory PersistenceService() {
    return _instance;
  }

  /// Salva todos os dados
  Future<bool> saveAllData({
    required List<Box> boxes,
    required List<Item> items,
    required List<User> users,
  }) async {
    try {
      _logService.info('Salvando todos os dados', category: 'persistence');
      
      final prefs = await SharedPreferences.getInstance();
      
      // Converter para JSON
      final boxesJson = jsonEncode(boxes.map((box) => box.toMap()).toList());
      final itemsJson = jsonEncode(items.map((item) => item.toMap()).toList());
      final usersJson = jsonEncode(users.map((user) => user.toMap()).toList());
      
      // Salvar no SharedPreferences
      await prefs.setString(_boxesKey, boxesJson);
      await prefs.setString(_itemsKey, itemsJson);
      await prefs.setString(_usersKey, usersJson);
      
      _logService.info(
        'Dados salvos com sucesso: ${boxes.length} caixas, ${items.length} itens, ${users.length} usuários',
        category: 'persistence'
      );
      
      return true;
    } catch (e) {
      _logService.error('Erro ao salvar dados: $e', category: 'persistence');
      return false;
    }
  }

  /// Carrega todos os dados
  Future<Map<String, dynamic>> loadAllData() async {
    try {
      _logService.info('Carregando todos os dados', category: 'persistence');
      
      final prefs = await SharedPreferences.getInstance();
      
      // Carregar do SharedPreferences
      final boxesJson = prefs.getString(_boxesKey);
      final itemsJson = prefs.getString(_itemsKey);
      final usersJson = prefs.getString(_usersKey);
      
      // Converter de JSON
      List<Box> boxes = [];
      List<Item> items = [];
      List<User> users = [];
      
      if (boxesJson != null) {
        final List<dynamic> boxesList = jsonDecode(boxesJson);
        boxes = boxesList.map((boxMap) => Box.fromMap(boxMap)).toList();
      }
      
      if (itemsJson != null) {
        final List<dynamic> itemsList = jsonDecode(itemsJson);
        items = itemsList.map((itemMap) => Item.fromMap(itemMap)).toList();
      }
      
      if (usersJson != null) {
        final List<dynamic> usersList = jsonDecode(usersJson);
        users = usersList.map((userMap) => User.fromMap(userMap)).toList();
      }
      
      // Se não houver usuários, criar um administrador padrão
      if (users.isEmpty) {
        final now = DateTime.now().toIso8601String();
        users.add(User(
          name: 'Administrador',
          email: 'admin@boxmagic.com',
          role: 'Administrador',
          isActive: true,
          createdAt: now,
        ));
      }
      
      _logService.info(
        'Dados carregados com sucesso: ${boxes.length} caixas, ${items.length} itens, ${users.length} usuários',
        category: 'persistence'
      );
      
      return {
        'boxes': boxes,
        'items': items,
        'users': users,
      };
    } catch (e) {
      _logService.error('Erro ao carregar dados: $e', category: 'persistence');
      
      // Retornar listas vazias em caso de erro
      return {
        'boxes': <Box>[],
        'items': <Item>[],
        'users': <User>[],
      };
    }
  }

  /// Limpa todos os dados
  Future<bool> clearAllData() async {
    try {
      _logService.warning('Limpando todos os dados', category: 'persistence');
      
      final prefs = await SharedPreferences.getInstance();
      
      // Remover as chaves
      await prefs.remove(_boxesKey);
      await prefs.remove(_itemsKey);
      await prefs.remove(_usersKey);
      
      _logService.info('Dados limpos com sucesso', category: 'persistence');
      
      return true;
    } catch (e) {
      _logService.error('Erro ao limpar dados: $e', category: 'persistence');
      return false;
    }
  }

  /// Exporta todos os dados como JSON
  Future<String> exportAllData({
    required List<Box> boxes,
    required List<Item> items,
    required List<User> users,
  }) async {
    try {
      _logService.info('Exportando todos os dados', category: 'persistence');
      
      final Map<String, dynamic> data = {
        'boxes': boxes.map((box) => box.toMap()).toList(),
        'items': items.map((item) => item.toMap()).toList(),
        'users': users.map((user) => user.toMap()).toList(),
        'exportDate': DateTime.now().toIso8601String(),
        'version': '1.0.0',
      };
      
      final jsonData = jsonEncode(data);
      
      _logService.info('Dados exportados com sucesso', category: 'persistence');
      
      return jsonData;
    } catch (e) {
      _logService.error('Erro ao exportar dados: $e', category: 'persistence');
      throw Exception('Erro ao exportar dados: $e');
    }
  }

  /// Importa todos os dados de um JSON
  Future<Map<String, dynamic>> importAllData(String jsonData) async {
    try {
      _logService.info('Importando dados', category: 'persistence');
      
      final Map<String, dynamic> data = jsonDecode(jsonData);
      
      // Validar o formato dos dados
      if (!data.containsKey('boxes') || !data.containsKey('items') || !data.containsKey('users')) {
        throw Exception('Formato de dados inválido');
      }
      
      // Converter para objetos
      final List<dynamic> boxesList = data['boxes'];
      final List<dynamic> itemsList = data['items'];
      final List<dynamic> usersList = data['users'];
      
      final List<Box> boxes = boxesList.map((boxMap) => Box.fromMap(boxMap)).toList();
      final List<Item> items = itemsList.map((itemMap) => Item.fromMap(itemMap)).toList();
      final List<User> users = usersList.map((userMap) => User.fromMap(userMap)).toList();
      
      _logService.info(
        'Dados importados com sucesso: ${boxes.length} caixas, ${items.length} itens, ${users.length} usuários',
        category: 'persistence'
      );
      
      // Salvar os dados importados
      await saveAllData(boxes: boxes, items: items, users: users);
      
      return {
        'boxes': boxes,
        'items': items,
        'users': users,
      };
    } catch (e) {
      _logService.error('Erro ao importar dados: $e', category: 'persistence');
      throw Exception('Erro ao importar dados: $e');
    }
  }

  /// Obtém o caminho do diretório de backup
  Future<String> getBackupDirectoryPath() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final path = prefs.getString(_backupDirKey);
      
      if (path == null || path.isEmpty) {
        // Retornar um diretório padrão se não estiver configurado
        if (kIsWeb) {
          return 'Downloads';
        } else {
          try {
            final dir = await getApplicationDocumentsDirectory();
            return dir.path;
          } catch (e) {
            _logService.error('Erro ao obter diretório de documentos: $e', category: 'persistence');
            return 'Não configurado';
          }
        }
      }
      
      return path;
    } catch (e) {
      _logService.error('Erro ao obter caminho do diretório de backup: $e', category: 'persistence');
      return 'Erro ao carregar';
    }
  }

  /// Define o caminho do diretório de backup
  Future<bool> setBackupDirectoryPath(String path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_backupDirKey, path);
      _logService.info('Diretório de backup definido: $path', category: 'persistence');
      return true;
    } catch (e) {
      _logService.error('Erro ao definir caminho do diretório de backup: $e', category: 'persistence');
      return false;
    }
  }

  /// Salva a data do último backup
  Future<bool> saveLastBackupDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().toIso8601String();
      await prefs.setString(_lastBackupKey, now);
      _logService.info('Data do último backup atualizada: $now', category: 'persistence');
      return true;
    } catch (e) {
      _logService.error('Erro ao salvar data do último backup: $e', category: 'persistence');
      return false;
    }
  }

  /// Obtém a data do último backup
  Future<String> getLastBackupDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final date = prefs.getString(_lastBackupKey);
      return date ?? 'Nunca';
    } catch (e) {
      _logService.error('Erro ao obter data do último backup: $e', category: 'persistence');
      return 'Erro ao carregar';
    }
  }
}
