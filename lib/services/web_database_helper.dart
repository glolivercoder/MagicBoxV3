import 'dart:async';
import 'dart:html' as html;
import 'dart:indexed_db';
import 'dart:convert';
import 'package:boxmagic/models/box.dart';
import 'package:boxmagic/models/item.dart';
import 'package:boxmagic/models/user.dart';
import 'package:boxmagic/services/log_service.dart';
import 'package:flutter/foundation.dart';

/// Classe responsável por gerenciar o armazenamento de dados no navegador
/// usando IndexedDB para a versão web do aplicativo.
class WebDatabaseHelper {
  static final WebDatabaseHelper _instance = WebDatabaseHelper._internal();
  static Database? _database;
  final LogService _logService = LogService();

  // Nome do banco de dados
  static const String _databaseName = 'boxmagic_web.db';
  
  // Versão do banco de dados
  static const int _databaseVersion = 1;

  // Nomes das stores (equivalentes às tabelas no SQLite)
  static const String storeBoxes = 'boxes';
  static const String storeItems = 'items';
  static const String storeUsers = 'users';

  // Construtor privado para implementação do Singleton
  WebDatabaseHelper._internal();

  // Factory para retornar a instância única
  factory WebDatabaseHelper() {
    return _instance;
  }

  // Getter para acessar a instância do banco de dados
  Future<Database> get database async {
    if (_database != null) return _database!;
    
    _database = await _initDatabase();
    return _database!;
  }

  // Inicializa o banco de dados
  Future<Database> _initDatabase() async {
    _logService.info('Inicializando banco de dados web', category: 'database');
    
    try {
      // Abrir/criar o banco de dados IndexedDB
      final IdbFactory idb = html.window.indexedDB!;
      final openDBRequest = idb.open(_databaseName, version: _databaseVersion,
        onUpgradeNeeded: (VersionChangeEvent event) {
          final Database db = event.target.result;
          
          // Criar as stores se não existirem
          if (!db.objectStoreNames!.contains(storeBoxes)) {
            db.createObjectStore(storeBoxes, keyPath: 'id', autoIncrement: true);
          }
          
          if (!db.objectStoreNames!.contains(storeItems)) {
            db.createObjectStore(storeItems, keyPath: 'id', autoIncrement: true);
          }
          
          if (!db.objectStoreNames!.contains(storeUsers)) {
            db.createObjectStore(storeUsers, keyPath: 'id', autoIncrement: true);
          }
          
          _logService.info('Stores criadas com sucesso', category: 'database');
        }
      );
      
      return await openDBRequest.onSuccess.first.then((_) {
        _logService.info('Banco de dados web inicializado com sucesso', category: 'database');
        
        // Criar usuário administrador padrão se não existir
        _createDefaultAdminUser(openDBRequest.result);
        
        return openDBRequest.result;
      });
    } catch (e) {
      _logService.error('Erro ao inicializar banco de dados web: $e', category: 'database');
      rethrow;
    }
  }

  // Criar usuário administrador padrão
  Future<void> _createDefaultAdminUser(Database db) async {
    try {
      final Transaction transaction = db.transaction(storeUsers, 'readonly');
      final ObjectStore store = transaction.objectStore(storeUsers);
      
      // Verificar se já existe algum usuário
      final countRequest = store.count();
      final int count = await countRequest.onSuccess.first.then((_) => countRequest.result as int);
      
      if (count == 0) {
        // Não existem usuários, criar o admin
        final now = DateTime.now().toIso8601String();
        final adminUser = {
          'name': 'Administrador',
          'email': 'admin@boxmagic.com',
          'role': 'Administrador',
          'isActive': 1,
          'createdAt': now,
        };
        
        final Transaction writeTransaction = db.transaction(storeUsers, 'readwrite');
        final ObjectStore writeStore = writeTransaction.objectStore(storeUsers);
        
        writeStore.add(adminUser);
        await writeTransaction.completed;
        
        _logService.info('Usuário administrador padrão criado', category: 'database');
      }
    } catch (e) {
      _logService.error('Erro ao criar usuário administrador: $e', category: 'database');
    }
  }

  // OPERAÇÕES PARA BOXES

  /// Insere uma nova caixa no banco de dados
  Future<int> insertBox(Box box) async {
    final db = await database;
    
    _logService.info('Inserindo caixa: ${box.name}', category: 'database');
    
    try {
      final Transaction transaction = db.transaction(storeBoxes, 'readwrite');
      final ObjectStore store = transaction.objectStore(storeBoxes);
      
      // Converter a caixa para Map
      final boxMap = box.toMap();
      
      // Se o ID for nulo, remover a chave para permitir autoincremento
      if (boxMap['id'] == null) {
        boxMap.remove('id');
      }
      
      // Adicionar a caixa
      final request = store.add(boxMap);
      
      // Aguardar a conclusão e retornar o ID
      final newId = await request.onSuccess.first.then((_) => request.result as int);
      await transaction.completed;
      
      return newId;
    } catch (e) {
      _logService.error('Erro ao inserir caixa: $e', category: 'database');
      rethrow;
    }
  }

  /// Atualiza uma caixa existente no banco de dados
  Future<int> updateBox(Box box) async {
    final db = await database;
    
    if (box.id == null) {
      throw Exception('Não é possível atualizar uma caixa sem ID');
    }
    
    _logService.info('Atualizando caixa ID ${box.id}', category: 'database');
    
    try {
      final Transaction transaction = db.transaction(storeBoxes, 'readwrite');
      final ObjectStore store = transaction.objectStore(storeBoxes);
      
      // Converter a caixa para Map
      final boxMap = box.toMap();
      
      // Atualizar a caixa
      store.put(boxMap);
      await transaction.completed;
      
      return box.id!;
    } catch (e) {
      _logService.error('Erro ao atualizar caixa: $e', category: 'database');
      rethrow;
    }
  }

  /// Exclui uma caixa do banco de dados
  Future<int> deleteBox(int id) async {
    final db = await database;
    
    _logService.info('Excluindo caixa ID $id', category: 'database');
    
    try {
      // Primeiro excluir todos os itens relacionados
      await _deleteItemsByBoxId(id);
      
      // Agora excluir a caixa
      final Transaction transaction = db.transaction(storeBoxes, 'readwrite');
      final ObjectStore store = transaction.objectStore(storeBoxes);
      
      store.delete(id);
      await transaction.completed;
      
      return 1; // Sucesso
    } catch (e) {
      _logService.error('Erro ao excluir caixa: $e', category: 'database');
      rethrow;
    }
  }

  // Excluir todos os itens de uma caixa
  Future<void> _deleteItemsByBoxId(int boxId) async {
    final db = await database;
    
    try {
      // Primeiro precisamos obter todos os itens da caixa
      final items = await getItemsByBox(boxId);
      
      if (items.isNotEmpty) {
        final Transaction transaction = db.transaction(storeItems, 'readwrite');
        final ObjectStore store = transaction.objectStore(storeItems);
        
        for (final item in items) {
          if (item.id != null) {
            store.delete(item.id);
          }
        }
        
        await transaction.completed;
      }
    } catch (e) {
      _logService.error('Erro ao excluir itens da caixa: $e', category: 'database');
      rethrow;
    }
  }

  /// Busca uma caixa pelo ID
  Future<Box?> getBox(int id) async {
    final db = await database;
    
    try {
      final Transaction transaction = db.transaction(storeBoxes, 'readonly');
      final ObjectStore store = transaction.objectStore(storeBoxes);
      
      final request = store.getObject(id);
      
      final result = await request.onSuccess.first.then((_) => request.result);
      
      if (result == null) {
        return null;
      }
      
      // Buscar a contagem de itens para esta caixa
      final itemCount = await _getItemCountForBox(id);
      
      // Adicionar a contagem de itens ao mapa
      final boxMap = result as Map<dynamic, dynamic>;
      boxMap['itemCount'] = itemCount;
      
      // Converter para Map<String, dynamic>
      final Map<String, dynamic> stringMap = {};
      boxMap.forEach((key, value) {
        stringMap[key.toString()] = value;
      });
      
      return Box.fromMap(stringMap);
    } catch (e) {
      _logService.error('Erro ao buscar caixa: $e', category: 'database');
      rethrow;
    }
  }

  // Obter a contagem de itens para uma caixa
  Future<int> _getItemCountForBox(int boxId) async {
    final db = await database;
    
    try {
      final Transaction transaction = db.transaction(storeItems, 'readonly');
      final ObjectStore store = transaction.objectStore(storeItems);
      
      // Não há suporte direto para COUNT no IndexedDB, então precisamos obter todos os itens
      // e contar manualmente
      final request = store.openCursor();
      
      int count = 0;
      await for (final event in request.onSuccess) {
        final cursor = event.target.result as Cursor?;
        if (cursor == null) {
          break;
        }
        
        final item = cursor.value as Map<dynamic, dynamic>;
        if (item['boxId'] == boxId) {
          count++;
        }
        
        cursor.next();
      }
      
      return count;
    } catch (e) {
      _logService.error('Erro ao contar itens da caixa: $e', category: 'database');
      return 0;
    }
  }

  /// Busca todas as caixas
  Future<List<Box>> getAllBoxes() async {
    final db = await database;
    
    try {
      final Transaction transaction = db.transaction(storeBoxes, 'readonly');
      final ObjectStore store = transaction.objectStore(storeBoxes);
      
      final request = store.getAll();
      
      final result = await request.onSuccess.first.then((_) => request.result as List);
      
      // Converter para List<Box>
      final List<Box> boxes = [];
      
      for (final boxData in result) {
        final boxMap = boxData as Map<dynamic, dynamic>;
        
        // Buscar a contagem de itens para esta caixa
        final int boxId = boxMap['id'] as int;
        final itemCount = await _getItemCountForBox(boxId);
        
        // Adicionar a contagem de itens ao mapa
        boxMap['itemCount'] = itemCount;
        
        // Converter para Map<String, dynamic>
        final Map<String, dynamic> stringMap = {};
        boxMap.forEach((key, value) {
          stringMap[key.toString()] = value;
        });
        
        boxes.add(Box.fromMap(stringMap));
      }
      
      // Ordenar por nome
      boxes.sort((a, b) => a.name.compareTo(b.name));
      
      return boxes;
    } catch (e) {
      _logService.error('Erro ao buscar todas as caixas: $e', category: 'database');
      rethrow;
    }
  }

  /// Busca caixas por nome ou localização
  Future<List<Box>> searchBoxes(String query) async {
    final db = await database;
    
    try {
      final Transaction transaction = db.transaction(storeBoxes, 'readonly');
      final ObjectStore store = transaction.objectStore(storeBoxes);
      
      final request = store.getAll();
      
      final result = await request.onSuccess.first.then((_) => request.result as List);
      
      // Converter para List<Box>
      final List<Box> boxes = [];
      final queryLower = query.toLowerCase();
      
      for (final boxData in result) {
        final boxMap = boxData as Map<dynamic, dynamic>;
        
        // Verificar se a caixa corresponde à pesquisa
        final name = (boxMap['name'] as String).toLowerCase();
        final location = boxMap['location'] != null ? (boxMap['location'] as String).toLowerCase() : '';
        final description = boxMap['description'] != null ? (boxMap['description'] as String).toLowerCase() : '';
        
        if (name.contains(queryLower) || 
            location.contains(queryLower) || 
            description.contains(queryLower)) {
          
          // Buscar a contagem de itens para esta caixa
          final int boxId = boxMap['id'] as int;
          final itemCount = await _getItemCountForBox(boxId);
          
          // Adicionar a contagem de itens ao mapa
          boxMap['itemCount'] = itemCount;
          
          // Converter para Map<String, dynamic>
          final Map<String, dynamic> stringMap = {};
          boxMap.forEach((key, value) {
            stringMap[key.toString()] = value;
          });
          
          boxes.add(Box.fromMap(stringMap));
        }
      }
      
      // Ordenar por nome
      boxes.sort((a, b) => a.name.compareTo(b.name));
      
      return boxes;
    } catch (e) {
      _logService.error('Erro ao pesquisar caixas: $e', category: 'database');
      rethrow;
    }
  }

  // OPERAÇÕES PARA ITEMS

  /// Insere um novo item no banco de dados
  Future<int> insertItem(Item item) async {
    final db = await database;
    
    _logService.info('Inserindo item: ${item.name}', category: 'database');
    
    try {
      final Transaction transaction = db.transaction(storeItems, 'readwrite');
      final ObjectStore store = transaction.objectStore(storeItems);
      
      // Converter o item para Map
      final itemMap = item.toMap();
      
      // Se o ID for nulo, remover a chave para permitir autoincremento
      if (itemMap['id'] == null) {
        itemMap.remove('id');
      }
      
      // Adicionar o item
      final request = store.add(itemMap);
      
      // Aguardar a conclusão e retornar o ID
      final newId = await request.onSuccess.first.then((_) => request.result as int);
      await transaction.completed;
      
      return newId;
    } catch (e) {
      _logService.error('Erro ao inserir item: $e', category: 'database');
      rethrow;
    }
  }

  /// Atualiza um item existente no banco de dados
  Future<int> updateItem(Item item) async {
    final db = await database;
    
    if (item.id == null) {
      throw Exception('Não é possível atualizar um item sem ID');
    }
    
    _logService.info('Atualizando item ID ${item.id}', category: 'database');
    
    try {
      final Transaction transaction = db.transaction(storeItems, 'readwrite');
      final ObjectStore store = transaction.objectStore(storeItems);
      
      // Converter o item para Map
      final itemMap = item.toMap();
      
      // Atualizar o item
      store.put(itemMap);
      await transaction.completed;
      
      return item.id!;
    } catch (e) {
      _logService.error('Erro ao atualizar item: $e', category: 'database');
      rethrow;
    }
  }

  /// Exclui um item do banco de dados
  Future<int> deleteItem(int id) async {
    final db = await database;
    
    _logService.info('Excluindo item ID $id', category: 'database');
    
    try {
      final Transaction transaction = db.transaction(storeItems, 'readwrite');
      final ObjectStore store = transaction.objectStore(storeItems);
      
      store.delete(id);
      await transaction.completed;
      
      return 1; // Sucesso
    } catch (e) {
      _logService.error('Erro ao excluir item: $e', category: 'database');
      rethrow;
    }
  }

  /// Busca um item pelo ID
  Future<Item?> getItem(int id) async {
    final db = await database;
    
    try {
      final Transaction transaction = db.transaction(storeItems, 'readonly');
      final ObjectStore store = transaction.objectStore(storeItems);
      
      final request = store.getObject(id);
      
      final result = await request.onSuccess.first.then((_) => request.result);
      
      if (result == null) {
        return null;
      }
      
      // Converter para Map<String, dynamic>
      final itemMap = result as Map<dynamic, dynamic>;
      final Map<String, dynamic> stringMap = {};
      itemMap.forEach((key, value) {
        stringMap[key.toString()] = value;
      });
      
      // Atualizar o timestamp de última visualização
      await updateItemLastViewed(id);
      
      return Item.fromMap(stringMap);
    } catch (e) {
      _logService.error('Erro ao buscar item: $e', category: 'database');
      rethrow;
    }
  }

  /// Busca todos os itens
  Future<List<Item>> getAllItems() async {
    final db = await database;
    
    try {
      final Transaction transaction = db.transaction(storeItems, 'readonly');
      final ObjectStore store = transaction.objectStore(storeItems);
      
      final request = store.getAll();
      
      final result = await request.onSuccess.first.then((_) => request.result as List);
      
      // Converter para List<Item>
      final List<Item> items = [];
      
      for (final itemData in result) {
        final itemMap = itemData as Map<dynamic, dynamic>;
        
        // Converter para Map<String, dynamic>
        final Map<String, dynamic> stringMap = {};
        itemMap.forEach((key, value) {
          stringMap[key.toString()] = value;
        });
        
        items.add(Item.fromMap(stringMap));
      }
      
      // Ordenar por nome
      items.sort((a, b) => a.name.compareTo(b.name));
      
      return items;
    } catch (e) {
      _logService.error('Erro ao buscar todos os itens: $e', category: 'database');
      rethrow;
    }
  }

  /// Busca itens por caixa
  Future<List<Item>> getItemsByBox(int boxId) async {
    final db = await database;
    
    try {
      final Transaction transaction = db.transaction(storeItems, 'readonly');
      final ObjectStore store = transaction.objectStore(storeItems);
      
      final request = store.getAll();
      
      final result = await request.onSuccess.first.then((_) => request.result as List);
      
      // Converter para List<Item>
      final List<Item> items = [];
      
      for (final itemData in result) {
        final itemMap = itemData as Map<dynamic, dynamic>;
        
        // Verificar se o item pertence à caixa
        if (itemMap['boxId'] == boxId) {
          // Converter para Map<String, dynamic>
          final Map<String, dynamic> stringMap = {};
          itemMap.forEach((key, value) {
            stringMap[key.toString()] = value;
          });
          
          items.add(Item.fromMap(stringMap));
        }
      }
      
      // Ordenar por nome
      items.sort((a, b) => a.name.compareTo(b.name));
      
      return items;
    } catch (e) {
      _logService.error('Erro ao buscar itens da caixa: $e', category: 'database');
      rethrow;
    }
  }

  /// Atualiza o timestamp de última visualização de um item
  Future<int> updateItemLastViewed(int id) async {
    final db = await database;
    
    try {
      final Transaction transaction = db.transaction(storeItems, 'readwrite');
      final ObjectStore store = transaction.objectStore(storeItems);
      
      // Obter o item atual
      final request = store.getObject(id);
      
      final result = await request.onSuccess.first.then((_) => request.result);
      
      if (result == null) {
        return 0;
      }
      
      // Atualizar o timestamp
      final itemMap = result as Map<dynamic, dynamic>;
      itemMap['lastViewedAt'] = DateTime.now().toIso8601String();
      
      // Salvar de volta
      store.put(itemMap);
      await transaction.completed;
      
      return 1; // Sucesso
    } catch (e) {
      _logService.error('Erro ao atualizar última visualização do item: $e', category: 'database');
      return 0;
    }
  }

  /// Move um item para outra caixa
  Future<int> moveItem(int itemId, int newBoxId) async {
    final db = await database;
    
    _logService.info('Movendo item ID $itemId para caixa ID $newBoxId', category: 'database');
    
    try {
      final Transaction transaction = db.transaction(storeItems, 'readwrite');
      final ObjectStore store = transaction.objectStore(storeItems);
      
      // Obter o item atual
      final request = store.getObject(itemId);
      
      final result = await request.onSuccess.first.then((_) => request.result);
      
      if (result == null) {
        return 0;
      }
      
      // Atualizar a caixa e o timestamp
      final itemMap = result as Map<dynamic, dynamic>;
      itemMap['boxId'] = newBoxId;
      itemMap['updatedAt'] = DateTime.now().toIso8601String();
      
      // Salvar de volta
      store.put(itemMap);
      await transaction.completed;
      
      return 1; // Sucesso
    } catch (e) {
      _logService.error('Erro ao mover item: $e', category: 'database');
      return 0;
    }
  }

  // OPERAÇÕES PARA USERS
  
  // Implementar conforme necessário...

  // OPERAÇÕES DE MANUTENÇÃO

  /// Limpa todos os dados do banco de dados (CUIDADO!)
  Future<void> clearDatabase() async {
    final db = await database;
    
    _logService.warning('Limpando todo o banco de dados web', category: 'database');
    
    try {
      // Limpar todas as stores
      final Transaction transaction = db.transaction([storeBoxes, storeItems, storeUsers], 'readwrite');
      
      transaction.objectStore(storeBoxes).clear();
      transaction.objectStore(storeItems).clear();
      transaction.objectStore(storeUsers).clear();
      
      await transaction.completed;
      
      // Criar o usuário administrador novamente
      await _createDefaultAdminUser(db);
    } catch (e) {
      _logService.error('Erro ao limpar banco de dados: $e', category: 'database');
      rethrow;
    }
  }
}
