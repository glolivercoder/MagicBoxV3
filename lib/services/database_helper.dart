import 'dart:convert';
import 'package:boxmagic/models/box.dart';
import 'package:boxmagic/models/item.dart';
import 'package:boxmagic/models/user.dart';
import 'package:boxmagic/services/persistence_service.dart';
import 'package:boxmagic/services/log_service.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Classe responsável por gerenciar o banco de dados SQLite
/// 
/// Implementa o padrão Singleton para garantir uma única instância
/// do banco de dados em toda a aplicação.
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  final LogService _logService = LogService();
  final PersistenceService _persistenceService = PersistenceService();

  // Nome do banco de dados
  static const String _databaseName = 'boxmagic.db';
  
  // Versão do banco de dados (incrementar quando houver alterações no schema)
  static const int _databaseVersion = 1;

  // Nomes das tabelas
  static const String tableBoxes = 'boxes';
  static const String tableItems = 'items';
  static const String tableUsers = 'users';
  
  // Listas em memória para armazenar os dados (usado na web)
  List<Box> _boxes = [];
  List<Item> _items = [];
  List<User> _users = [];
  bool _dataLoaded = false;

  // Construtor privado para implementação do Singleton
  DatabaseHelper._internal() {
    // Carregar dados persistentes ao inicializar
    _loadPersistedData();
  }

  // Factory para retornar a instância única
  factory DatabaseHelper() {
    return _instance;
  }
  
  // Método para carregar dados persistentes (usado na web)
  Future<void> _loadPersistedData() async {
    if (!_dataLoaded) {
      try {
        _logService.info('Carregando dados persistentes', category: 'database');

        // Carregar dados do serviço de persistência
        final data = await _persistenceService.loadAllData();
        _boxes = data['boxes'] as List<Box>;
        _items = data['items'] as List<Item>;
        _users = data['users'] as List<User>;
        _dataLoaded = true;

        _logService.info(
          'Dados persistentes carregados com sucesso: ${_boxes.length} caixas, ${_items.length} itens, ${_users.length} usuários',
          category: 'database'
        );
      } catch (e) {
        _logService.error('Erro ao carregar dados persistentes: $e', category: 'database');
        // Inicializar com listas vazias em caso de erro
        _boxes = [];
        _items = [];
        _users = [];
        _dataLoaded = true;
      }
    }
  }

  // Getter para acessar a instância do banco de dados
  Future<Database> get database async {
    if (kIsWeb) {
      // Na web, não usamos SQLite, mas precisamos retornar algo compatível
      throw UnsupportedError(
        'SQLite não é suportado na web. Use os métodos específicos para web.'
      );
    }
    
    if (_database != null) return _database!;
    
    _database = await _initDatabase();
    return _database!;
  }

  // Inicializa o banco de dados (apenas para dispositivos móveis)
  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite não é suportado na web');
    }
    
    _logService.info('Inicializando banco de dados SQLite', category: 'database');
    
    // Obter o caminho para o diretório do banco de dados
    String path = join(await getDatabasesPath(), _databaseName);
    
    // Abrir/criar o banco de dados
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  // Configurar o banco de dados para suportar chaves estrangeiras
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // Criar as tabelas do banco de dados
  Future<void> _onCreate(Database db, int version) async {
    _logService.info('Criando tabelas do banco de dados', category: 'database');
    
    // Tabela de caixas
    await db.execute('''
      CREATE TABLE $tableBoxes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'Geral',
        description TEXT,
        location TEXT,
        qrCode TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT
      )
    ''');
    
    // Tabela de itens
    await db.execute('''
      CREATE TABLE $tableItems (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT,
        description TEXT,
        image TEXT,
        boxId INTEGER NOT NULL,
        tags TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        lastViewedAt TEXT,
        FOREIGN KEY (boxId) REFERENCES $tableBoxes(id) ON DELETE CASCADE
      )
    ''');
    
    // Tabela de usuários
    await db.execute('''
      CREATE TABLE $tableUsers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        role TEXT NOT NULL,
        avatar TEXT,
        isActive INTEGER NOT NULL DEFAULT 1,
        createdAt TEXT NOT NULL,
        updatedAt TEXT
      )
    ''');
    
    // Criar usuário administrador padrão
    final now = DateTime.now().toIso8601String();
    await db.insert(tableUsers, {
      'name': 'Administrador',
      'email': 'admin@boxmagic.com',
      'role': 'Administrador',
      'isActive': 1,
      'createdAt': now,
    });
    
    _logService.info('Tabelas criadas com sucesso', category: 'database');
  }

  // Atualizar o banco de dados quando a versão mudar
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    _logService.info('Atualizando banco de dados da versão $oldVersion para $newVersion', category: 'database');
    
    // Implementar migrações conforme necessário
    if (oldVersion < 2) {
      // Exemplo de migração para a versão 2
      // await db.execute('ALTER TABLE $tableItems ADD COLUMN newColumn TEXT');
    }
  }

  // OPERAÇÕES PARA BOXES

  /// Insere uma nova caixa no banco de dados
  Future<int> insertBox(Box box) async {
    try {
      if (kIsWeb) {
        // Implementação para web
        final nextId = _getNextId(_boxes);
        
        // Garantir que o ID tenha 4 dígitos (entre 1000 e 9999)
        final boxId = nextId < 1000 ? 1000 + nextId : nextId;
        
        final newBox = box.copyWith(
          id: boxId,
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        );
        
        _boxes.add(newBox);
        
        // Persistir dados
        await _persistenceService.saveAllData(
          boxes: _boxes,
          items: _items,
          users: _users,
        );
        
        _logService.info('Caixa inserida com ID: $boxId', category: 'database');
        return boxId;
      } else {
        // Implementação para dispositivos móveis
        final db = await database;
        
        // Obter o maior ID atual para garantir que comece em 1000
        final result = await db.rawQuery('SELECT MAX(id) as maxId FROM $tableBoxes');
        final maxId = result.first['maxId'] as int? ?? 0;
        
        // Garantir que o ID tenha 4 dígitos (entre 1000 e 9999)
        final nextId = maxId < 1000 ? 1000 : maxId + 1;
        
        final boxMap = box.copyWith(
          id: nextId,
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ).toMap();
        
        final id = await db.insert(tableBoxes, boxMap);
        
        _logService.info('Caixa inserida com ID: $id', category: 'database');
        return id;
      }
    } catch (e) {
      _logService.error('Erro ao inserir caixa', error: e, category: 'database');
      return -1;
    }
  }

  /// Atualiza uma caixa existente no banco de dados
  Future<int> updateBox(Box box) async {
    if (box.id == null) {
      throw Exception('Não é possível atualizar uma caixa sem ID');
    }
    
    _logService.info('Atualizando caixa ID ${box.id}', category: 'database');
    
    if (kIsWeb) {
      // Versão web - usar armazenamento em memória
      final index = _boxes.indexWhere((b) => b.id == box.id);
      
      if (index == -1) {
        throw Exception('Caixa não encontrada');
      }
      
      final updatedBox = box.copyWith(
        updatedAt: DateTime.now().toIso8601String(),
      );
      
      _boxes[index] = updatedBox;
      
      // Persistir os dados
      await _persistenceService.saveAllData(
        boxes: _boxes,
        items: _items,
        users: _users,
      );
      
      return 1; // Sucesso
    } else {
      // Versão mobile - usar SQLite
      final db = await database;
      
      return await db.update(
        tableBoxes,
        box.toMap(),
        where: 'id = ?',
        whereArgs: [box.id],
      );
    }
  }

  /// Exclui uma caixa do banco de dados
  Future<int> deleteBox(int id) async {
    _logService.info('Excluindo caixa ID $id', category: 'database');
    
    if (kIsWeb) {
      // Versão web - usar armazenamento em memória
      final index = _boxes.indexWhere((b) => b.id == id);
      
      if (index == -1) {
        return 0; // Não encontrada
      }
      
      // Remover todos os itens da caixa
      _items.removeWhere((item) => item.boxId == id);
      
      // Remover a caixa
      _boxes.removeAt(index);
      
      // Persistir os dados
      await _persistenceService.saveAllData(
        boxes: _boxes,
        items: _items,
        users: _users,
      );
      
      return 1; // Sucesso
    } else {
      // Versão mobile - usar SQLite
      final db = await database;
      
      return await db.delete(
        tableBoxes,
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  /// Busca uma caixa pelo ID
  Future<Box?> readBox(int id) async {
    if (kIsWeb) {
      // Versão web - usar armazenamento em memória
      final box = _boxes.firstWhere(
        (b) => b.id == id,
        orElse: () => Box(
          id: -1,
          name: '',
          category: 'Geral',
          createdAt: '',
        ),
      );
      
      if (box.id == -1) {
        return null;
      }
      
      // Contar itens da caixa
      final itemCount = _items.where((item) => item.boxId == id).length;
      
      // Retornar cópia da caixa com a contagem de itens
      return box.copyWith(itemCount: itemCount);
    } else {
      // Versão mobile - usar SQLite
      final db = await database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        tableBoxes,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isEmpty) {
        return null;
      }
      
      // Buscar a contagem de itens para esta caixa
      final itemCount = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM $tableItems WHERE boxId = ?',
        [id],
      )) ?? 0;
      
      // Adicionar a contagem de itens ao mapa
      maps.first['itemCount'] = itemCount;
      
      return Box.fromMap(maps.first);
    }
  }

  /// Busca todas as caixas
  Future<List<Box>> getAllBoxes() async {
    if (kIsWeb) {
      // Versão web - usar armazenamento em memória
      // Adicionar contagem de itens a cada caixa
      return _boxes.map((box) {
        final itemCount = _items.where((item) => item.boxId == box.id).length;
        return box.copyWith(itemCount: itemCount);
      }).toList();
    } else {
      // Versão mobile - usar SQLite
      final db = await database;
      
      // Consulta para obter todas as caixas com contagem de itens
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT b.*, COUNT(i.id) as itemCount
        FROM $tableBoxes b
        LEFT JOIN $tableItems i ON b.id = i.boxId
        GROUP BY b.id
        ORDER BY b.name
      ''');
      
      return List.generate(maps.length, (i) {
        return Box.fromMap(maps[i]);
      });
    }
  }

  /// Busca caixas por nome ou localização
  Future<List<Box>> searchBoxes(String query) async {
    if (kIsWeb) {
      // Versão web - usar armazenamento em memória
      final queryLower = query.toLowerCase();
      
      // Filtrar caixas que correspondem à consulta
      final filteredBoxes = _boxes.where((box) {
        final name = box.name.toLowerCase();
        final location = box.location?.toLowerCase() ?? '';
        final description = box.description?.toLowerCase() ?? '';
        
        return name.contains(queryLower) || 
               location.contains(queryLower) || 
               description.contains(queryLower);
      }).toList();
      
      // Adicionar contagem de itens a cada caixa
      return filteredBoxes.map((box) {
        final itemCount = _items.where((item) => item.boxId == box.id).length;
        return box.copyWith(itemCount: itemCount);
      }).toList();
    } else {
      // Versão mobile - usar SQLite
      final db = await database;
      
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT b.*, COUNT(i.id) as itemCount
        FROM $tableBoxes b
        LEFT JOIN $tableItems i ON b.id = i.boxId
        WHERE b.name LIKE ? OR b.location LIKE ? OR b.description LIKE ?
        GROUP BY b.id
        ORDER BY b.name
      ''', ['%$query%', '%$query%', '%$query%']);
      
      return List.generate(maps.length, (i) {
        return Box.fromMap(maps[i]);
      });
    }
  }
  
  // Método auxiliar para gerar IDs únicos na versão web
  int _getNextId(List<dynamic> items) {
    if (items.isEmpty) {
      return 1;
    }
    
    // Encontrar o maior ID atual e adicionar 1
    int maxId = 0;
    for (final item in items) {
      if (item.id != null && item.id > maxId) {
        maxId = item.id;
      }
    }
    
    return maxId + 1;
  }

  // OPERAÇÕES PARA ITEMS

  /// Insere um novo item no banco de dados
  Future<int> insertItem(Item item) async {
    final db = await database;
    
    _logService.info('Inserindo item: ${item.name}', category: 'database');
    
    return await db.insert(
      tableItems,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Atualiza um item existente no banco de dados
  Future<int> updateItem(Item item) async {
    final db = await database;
    
    if (item.id == null) {
      throw Exception('Não é possível atualizar um item sem ID');
    }
    
    _logService.info('Atualizando item ID ${item.id}', category: 'database');
    
    return await db.update(
      tableItems,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// Exclui um item do banco de dados
  Future<int> deleteItem(int id) async {
    final db = await database;
    
    _logService.info('Excluindo item ID $id', category: 'database');
    
    return await db.delete(
      tableItems,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Busca um item pelo ID
  Future<Item?> getItem(int id) async {
    if (kIsWeb) {
      // Versão web - usar armazenamento em memória
      final item = _items.firstWhere(
        (i) => i.id == id,
        orElse: () => Item(
          id: -1,
          name: '',
          createdAt: '',
        ),
      );
      
      if (item.id == -1) {
        return null;
      }
      
      return item;
    } else {
      // Versão mobile - usar SQLite
      final db = await database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        tableItems,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isEmpty) {
        return null;
      }
      
      return Item.fromMap(maps.first);
    }
  }

  /// Busca todos os itens
  Future<List<Item>> getAllItems() async {
    if (kIsWeb) {
      // Versão web - usar armazenamento em memória
      _logService.info('${_items.length} itens encontrados', category: 'database');
      return _items;
    } else {
      // Versão mobile - usar SQLite
      final db = await database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        tableItems,
        orderBy: 'name',
      );
      
      _logService.info('${maps.length} itens encontrados', category: 'database');
      
      return List.generate(maps.length, (i) {
        return Item.fromMap(maps[i]);
      });
    }
  }

  /// Busca itens por caixa
  Future<List<Item>> getItemsByBox(int boxId) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      tableItems,
      where: 'boxId = ?',
      whereArgs: [boxId],
      orderBy: 'name',
    );
    
    return List.generate(maps.length, (i) {
      return Item.fromMap(maps[i]);
    });
  }

  /// Busca itens por nome, categoria ou descrição
  Future<List<Item>> searchItems(String query) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      tableItems,
      where: 'name LIKE ? OR category LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'name',
    );
    
    return List.generate(maps.length, (i) {
      return Item.fromMap(maps[i]);
    });
  }

  /// Busca itens por categoria
  Future<List<Item>> getItemsByCategory(String category) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      tableItems,
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'name',
    );
    
    return List.generate(maps.length, (i) {
      return Item.fromMap(maps[i]);
    });
  }

  /// Atualiza o timestamp de última visualização de um item
  Future<int> updateItemLastViewed(int id) async {
    final db = await database;
    
    final now = DateTime.now().toIso8601String();
    
    return await db.update(
      tableItems,
      {'lastViewedAt': now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Move um item para outra caixa
  Future<int> moveItem(int itemId, int newBoxId) async {
    final db = await database;
    
    _logService.info('Movendo item ID $itemId para caixa ID $newBoxId', category: 'database');
    
    return await db.update(
      tableItems,
      {'boxId': newBoxId, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  /// Busca todos os itens de uma caixa específica
  Future<List<Item>> getItemsByBoxId(int boxId) async {
    if (kIsWeb) {
      // Versão web - usar armazenamento em memória
      final filteredItems = _items.where((item) => item.boxId == boxId).toList();
      _logService.info('${filteredItems.length} itens encontrados na caixa $boxId', category: 'database');
      return filteredItems;
    } else {
      // Versão mobile - usar SQLite
      final db = await database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        tableItems,
        where: 'boxId = ?',
        whereArgs: [boxId],
        orderBy: 'name',
      );
      
      _logService.info('${maps.length} itens encontrados na caixa $boxId', category: 'database');
      
      return List.generate(maps.length, (i) {
        return Item.fromMap(maps[i]);
      });
    }
  }

  /// Salva um item (insere se não existir, atualiza se já existir)
  Future<Item> saveItem(Item item) async {
    if (kIsWeb) {
      // Versão web - usar armazenamento em memória
      int id;
      
      if (item.id == null) {
        // Novo item
        id = _getNextId(_items);
        final newItem = Item(
          id: id,
          name: item.name,
          category: item.category,
          description: item.description,
          image: item.image,
          boxId: item.boxId,
          tags: item.tags,
          createdAt: item.createdAt,
          updatedAt: item.updatedAt,
        );
        
        _items.add(newItem);
        _logService.info('Item inserido: ${newItem.name}', category: 'database');
        
        // Persistir os dados
        await _persistenceService.saveAllData(
          boxes: _boxes,
          items: _items,
          users: _users,
        );
        
        return newItem;
      } else {
        // Item existente
        final index = _items.indexWhere((i) => i.id == item.id);
        
        if (index >= 0) {
          _items[index] = item;
          _logService.info('Item atualizado: ${item.name}', category: 'database');
          
          // Persistir os dados
          await _persistenceService.saveAllData(
            boxes: _boxes,
            items: _items,
            users: _users,
          );
          
          return item;
        } else {
          throw Exception('Item não encontrado: ID ${item.id}');
        }
      }
    } else {
      // Versão mobile - usar SQLite
      final db = await database;
      
      int id;
      
      if (item.id == null) {
        // Novo item
        id = await db.insert(
          tableItems,
          item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        
        _logService.info('Item inserido: ${item.name}', category: 'database');
      } else {
        // Item existente
        id = item.id!;
        
        await db.update(
          tableItems,
          item.toMap(),
          where: 'id = ?',
          whereArgs: [id],
        );
        
        _logService.info('Item atualizado: ${item.name}', category: 'database');
      }
      
      // Buscar o item atualizado do banco
      final List<Map<String, dynamic>> maps = await db.query(
        tableItems,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isNotEmpty) {
        return Item.fromMap(maps.first);
      } else {
        // Se não encontrar, retornar o item original
        return item;
      }
    }
  }

  // OPERAÇÕES PARA USERS

  /// Insere um novo usuário no banco de dados
  Future<int> insertUser(User user) async {
    final db = await database;
    
    _logService.info('Inserindo usuário: ${user.name}', category: 'database');
    
    return await db.insert(
      tableUsers,
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Atualiza um usuário existente no banco de dados
  Future<int> updateUser(User user) async {
    final db = await database;
    
    if (user.id == null) {
      throw Exception('Não é possível atualizar um usuário sem ID');
    }
    
    _logService.info('Atualizando usuário ID ${user.id}', category: 'database');
    
    return await db.update(
      tableUsers,
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  /// Exclui um usuário do banco de dados
  Future<int> deleteUser(int id) async {
    final db = await database;
    
    _logService.info('Excluindo usuário ID $id', category: 'database');
    
    return await db.delete(
      tableUsers,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Busca um usuário pelo ID
  Future<User?> getUser(int id) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      tableUsers,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) {
      return null;
    }
    
    return User.fromMap(maps.first);
  }

  /// Busca um usuário pelo email
  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      tableUsers,
      where: 'email = ?',
      whereArgs: [email],
    );
    
    if (maps.isEmpty) {
      return null;
    }
    
    return User.fromMap(maps.first);
  }

  /// Busca todos os usuários
  Future<List<User>> getAllUsers() async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      tableUsers,
      orderBy: 'name',
    );
    
    return List.generate(maps.length, (i) {
      return User.fromMap(maps[i]);
    });
  }

  /// Ativa ou desativa um usuário
  Future<int> toggleUserActive(int id, bool isActive) async {
    final db = await database;
    
    _logService.info('${isActive ? 'Ativando' : 'Desativando'} usuário ID $id', category: 'database');
    
    return await db.update(
      tableUsers,
      {'isActive': isActive ? 1 : 0, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // OPERAÇÕES ESTATÍSTICAS

  /// Retorna estatísticas do banco de dados
  Future<Map<String, dynamic>> getDatabaseStats() async {
    final db = await database;
    
    // Total de caixas
    final boxCount = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM $tableBoxes',
    )) ?? 0;
    
    // Total de itens
    final itemCount = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM $tableItems',
    )) ?? 0;
    
    // Total de usuários
    final userCount = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM $tableUsers',
    )) ?? 0;
    
    // Caixa com mais itens
    final List<Map<String, dynamic>> boxWithMostItems = await db.rawQuery('''
      SELECT b.id, b.name, COUNT(i.id) as itemCount
      FROM $tableBoxes b
      LEFT JOIN $tableItems i ON b.id = i.boxId
      GROUP BY b.id
      ORDER BY itemCount DESC
      LIMIT 1
    ''');
    
    // Categorias mais comuns
    final List<Map<String, dynamic>> topCategories = await db.rawQuery('''
      SELECT category, COUNT(*) as count
      FROM $tableItems
      WHERE category IS NOT NULL AND category != ''
      GROUP BY category
      ORDER BY count DESC
      LIMIT 5
    ''');
    
    return {
      'boxCount': boxCount,
      'itemCount': itemCount,
      'userCount': userCount,
      'boxWithMostItems': boxWithMostItems.isNotEmpty ? boxWithMostItems.first : null,
      'topCategories': topCategories,
      'itemsPerBox': boxCount > 0 ? (itemCount / boxCount).toStringAsFixed(1) : '0',
    };
  }

  // OPERAÇÕES DE MANUTENÇÃO

  /// Limpa todos os dados do banco de dados (CUIDADO!)
  Future<void> clearDatabase() async {
    final db = await database;
    
    _logService.warning('Limpando todo o banco de dados', category: 'database');
    
    await db.delete(tableItems);
    await db.delete(tableBoxes);
    await db.delete(tableUsers);
    
    // Reinicia os contadores de autoincremento
    await db.execute('DELETE FROM sqlite_sequence');
    
    // Cria o usuário administrador novamente
    final now = DateTime.now().toIso8601String();
    await db.insert(tableUsers, {
      'name': 'Administrador',
      'email': 'admin@boxmagic.com',
      'role': 'Administrador',
      'isActive': 1,
      'createdAt': now,
    });
  }

  /// Fecha a conexão com o banco de dados
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
