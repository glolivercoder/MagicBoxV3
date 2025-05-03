import 'package:boxmagic/models/box.dart';
import 'package:boxmagic/models/item.dart';
import 'package:boxmagic/models/user.dart';
import 'package:boxmagic/services/database_helper.dart';
import 'package:boxmagic/services/log_service.dart';

/// Serviço ORM (Object-Relational Mapping) para o BoxMagic
/// 
/// Fornece uma camada de abstração para operações de banco de dados,
/// permitindo trabalhar com objetos em vez de consultas SQL diretas.
class OrmService {
  final DatabaseHelper _db = DatabaseHelper();
  final LogService _logService = LogService();

  // Singleton
  static final OrmService _instance = OrmService._internal();
  
  factory OrmService() {
    return _instance;
  }
  
  OrmService._internal();

  // OPERAÇÕES PARA BOXES

  /// Salva uma caixa (insere se não existir, atualiza se já existir)
  Future<Box> saveBox(Box box) async {
    try {
      int id;
      
      if (box.id == null) {
        // Nova caixa
        id = await _db.insertBox(box);
        _logService.info('Caixa criada: ${box.name}', category: 'orm');
      } else {
        // Caixa existente
        id = box.id!;
        await _db.updateBox(box);
        _logService.info('Caixa atualizada: ${box.name}', category: 'orm');
      }
      
      // Buscar a caixa atualizada do banco
      final updatedBox = await _db.readBox(id);
      return updatedBox ?? box;
    } catch (e) {
      _logService.error('Erro ao salvar caixa: $e', category: 'orm');
      rethrow;
    }
  }

  /// Exclui uma caixa pelo ID
  Future<bool> deleteBox(int id) async {
    try {
      final result = await _db.deleteBox(id);
      final success = result != 0;
      
      if (success) {
        _logService.info('Caixa excluída: ID $id', category: 'orm');
      } else {
        _logService.warning('Caixa não encontrada para exclusão: ID $id', category: 'orm');
      }
      
      return success;
    } catch (e) {
      _logService.error('Erro ao excluir caixa: $e', category: 'orm');
      rethrow;
    }
  }

  /// Busca uma caixa pelo ID
  Future<Box?> getBox(int id) async {
    try {
      final box = await _db.readBox(id);
      
      if (box != null) {
        _logService.info('Caixa encontrada: ${box.name}', category: 'orm');
      } else {
        _logService.info('Caixa não encontrada: ID $id', category: 'orm');
      }
      
      return box;
    } catch (e) {
      _logService.error('Erro ao buscar caixa: $e', category: 'orm');
      rethrow;
    }
  }

  /// Busca todas as caixas
  Future<List<Box>> getAllBoxes() async {
    try {
      final boxes = await _db.getAllBoxes();
      _logService.info('${boxes.length} caixas encontradas', category: 'orm');
      return boxes;
    } catch (e) {
      _logService.error('Erro ao buscar todas as caixas: $e', category: 'orm');
      rethrow;
    }
  }

  /// Busca caixas por termo de pesquisa
  Future<List<Box>> searchBoxes(String query) async {
    try {
      if (query.isEmpty) {
        return await getAllBoxes();
      }
      
      final boxes = await _db.searchBoxes(query);
      _logService.info('${boxes.length} caixas encontradas para a pesquisa "$query"', category: 'orm');
      return boxes;
    } catch (e) {
      _logService.error('Erro ao pesquisar caixas: $e', category: 'orm');
      rethrow;
    }
  }

  // OPERAÇÕES PARA ITEMS

  /// Salva um item no banco de dados
  Future<Item> saveItem(Item item) async {
    try {
      // Verificar se a caixa existe, se o item estiver associado a uma caixa
      if (item.boxId != null) {
        final box = await _db.readBox(item.boxId!);
        if (box == null) {
          throw Exception('A caixa com ID ${item.boxId} não existe');
        }
      }
      
      // Salvar o item
      final savedItem = await _db.saveItem(item);
      _logService.info('Item salvo: ${savedItem.name}', category: 'orm');
      return savedItem;
    } catch (e) {
      _logService.error('Erro ao salvar item: $e', category: 'orm');
      rethrow;
    }
  }

  /// Exclui um item pelo ID
  Future<bool> deleteItem(int id) async {
    try {
      final result = await _db.deleteItem(id);
      final success = result != 0;
      
      if (success) {
        _logService.info('Item excluído: ID $id', category: 'orm');
      } else {
        _logService.warning('Item não encontrado para exclusão: ID $id', category: 'orm');
      }
      
      return success;
    } catch (e) {
      _logService.error('Erro ao excluir item: $e', category: 'orm');
      rethrow;
    }
  }

  /// Busca um item pelo ID
  Future<Item?> getItem(int id) async {
    try {
      final item = await _db.getItem(id);
      
      if (item != null) {
        // Atualizar o timestamp de última visualização
        await _db.updateItemLastViewed(id);
        _logService.info('Item encontrado: ${item.name}', category: 'orm');
      } else {
        _logService.info('Item não encontrado: ID $id', category: 'orm');
      }
      
      return item;
    } catch (e) {
      _logService.error('Erro ao buscar item: $e', category: 'orm');
      rethrow;
    }
  }

  /// Busca todos os itens
  Future<List<Item>> getAllItems() async {
    try {
      final items = await _db.getAllItems();
      
      // Carregar o nome da caixa para cada item
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        if (item.boxId != null) {
          final box = await _db.readBox(item.boxId!);
          if (box != null) {
            items[i] = item.copyWith(boxName: box.name);
          }
        }
      }
      
      _logService.info('${items.length} itens encontrados', category: 'orm');
      return items;
    } catch (e) {
      _logService.error('Erro ao obter todos os itens: $e', category: 'orm');
      rethrow;
    }
  }

  /// Busca itens por caixa
  Future<List<Item>> getItemsByBox(int boxId) async {
    try {
      // Verificar se a caixa existe
      final box = await _db.readBox(boxId);
      if (box == null) {
        throw Exception('Caixa não encontrada: ID $boxId');
      }
      
      // Buscar os itens
      final items = await _db.getItemsByBoxId(boxId);
      _logService.info('${items.length} itens encontrados na caixa ${box.name}', category: 'orm');
      return items;
    } catch (e) {
      _logService.error('Erro ao buscar itens da caixa: $e', category: 'orm');
      rethrow;
    }
  }

  /// Busca itens por termo de pesquisa
  Future<List<Item>> searchItems(String query) async {
    try {
      if (query.isEmpty) {
        return await getAllItems();
      }
      
      final items = await _db.searchItems(query);
      _logService.info('${items.length} itens encontrados para a pesquisa "$query"', category: 'orm');
      return items;
    } catch (e) {
      _logService.error('Erro ao pesquisar itens: $e', category: 'orm');
      rethrow;
    }
  }

  /// Busca itens por categoria
  Future<List<Item>> getItemsByCategory(String category) async {
    try {
      final items = await _db.getItemsByCategory(category);
      _logService.info('${items.length} itens encontrados na categoria "$category"', category: 'orm');
      return items;
    } catch (e) {
      _logService.error('Erro ao buscar itens por categoria: $e', category: 'orm');
      rethrow;
    }
  }

  /// Move um item para outra caixa
  Future<bool> moveItem(int itemId, int newBoxId) async {
    try {
      // Verificar se o item existe
      final item = await _db.getItem(itemId);
      if (item == null) {
        _logService.warning('Item não encontrado para mover: ID $itemId', category: 'orm');
        return false;
      }
      
      // Verificar se a caixa de destino existe
      final box = await _db.readBox(newBoxId);
      if (box == null) {
        _logService.warning('Caixa de destino não encontrada: ID $newBoxId', category: 'orm');
        return false;
      }
      
      // Mover o item
      final result = await _db.moveItem(itemId, newBoxId);
      final success = result != 0;
      
      if (success) {
        _logService.info('Item ID $itemId movido para a caixa ${box.name}', category: 'orm');
      } else {
        _logService.warning('Falha ao mover item ID $itemId', category: 'orm');
      }
      
      return success;
    } catch (e) {
      _logService.error('Erro ao mover item: $e', category: 'orm');
      rethrow;
    }
  }

  // OPERAÇÕES PARA USERS

  /// Salva um usuário (insere se não existir, atualiza se já existir)
  Future<User> saveUser(User user) async {
    try {
      int id;
      
      if (user.id == null) {
        // Novo usuário
        id = await _db.insertUser(user);
        _logService.info('Usuário criado: ${user.name}', category: 'orm');
      } else {
        // Usuário existente
        id = user.id!;
        await _db.updateUser(user);
        _logService.info('Usuário atualizado: ${user.name}', category: 'orm');
      }
      
      // Buscar o usuário atualizado do banco
      final updatedUser = await _db.getUser(id);
      return updatedUser ?? user;
    } catch (e) {
      _logService.error('Erro ao salvar usuário: $e', category: 'orm');
      rethrow;
    }
  }

  /// Exclui um usuário pelo ID
  Future<bool> deleteUser(int id) async {
    try {
      final result = await _db.deleteUser(id);
      final success = result != 0;
      
      if (success) {
        _logService.info('Usuário excluído: ID $id', category: 'orm');
      } else {
        _logService.warning('Usuário não encontrado para exclusão: ID $id', category: 'orm');
      }
      
      return success;
    } catch (e) {
      _logService.error('Erro ao excluir usuário: $e', category: 'orm');
      rethrow;
    }
  }

  /// Busca um usuário pelo ID
  Future<User?> getUser(int id) async {
    try {
      final user = await _db.getUser(id);
      
      if (user != null) {
        _logService.info('Usuário encontrado: ${user.name}', category: 'orm');
      } else {
        _logService.info('Usuário não encontrado: ID $id', category: 'orm');
      }
      
      return user;
    } catch (e) {
      _logService.error('Erro ao buscar usuário: $e', category: 'orm');
      rethrow;
    }
  }

  /// Busca um usuário pelo email
  Future<User?> getUserByEmail(String email) async {
    try {
      final user = await _db.getUserByEmail(email);
      
      if (user != null) {
        _logService.info('Usuário encontrado: ${user.name}', category: 'orm');
      } else {
        _logService.info('Usuário não encontrado para o email: $email', category: 'orm');
      }
      
      return user;
    } catch (e) {
      _logService.error('Erro ao buscar usuário por email: $e', category: 'orm');
      rethrow;
    }
  }

  /// Busca todos os usuários
  Future<List<User>> getAllUsers() async {
    try {
      final users = await _db.getAllUsers();
      _logService.info('${users.length} usuários encontrados', category: 'orm');
      return users;
    } catch (e) {
      _logService.error('Erro ao buscar todos os usuários: $e', category: 'orm');
      rethrow;
    }
  }

  /// Ativa ou desativa um usuário
  Future<bool> toggleUserActive(int id, bool isActive) async {
    try {
      final result = await _db.toggleUserActive(id, isActive);
      final success = result != 0;
      
      if (success) {
        _logService.info('Usuário ID $id ${isActive ? 'ativado' : 'desativado'}', category: 'orm');
      } else {
        _logService.warning('Usuário não encontrado para alteração de status: ID $id', category: 'orm');
      }
      
      return success;
    } catch (e) {
      _logService.error('Erro ao alterar status do usuário: $e', category: 'orm');
      rethrow;
    }
  }

  // OPERAÇÕES ESTATÍSTICAS

  /// Obtém estatísticas do banco de dados
  Future<Map<String, dynamic>> getDatabaseStats() async {
    try {
      final stats = await _db.getDatabaseStats();
      _logService.info('Estatísticas do banco de dados obtidas', category: 'orm');
      return stats;
    } catch (e) {
      _logService.error('Erro ao obter estatísticas do banco de dados: $e', category: 'orm');
      rethrow;
    }
  }

  // OPERAÇÕES DE MANUTENÇÃO

  /// Limpa todos os dados do banco de dados (CUIDADO!)
  Future<void> clearDatabase() async {
    try {
      await _db.clearDatabase();
      _logService.warning('Banco de dados limpo completamente', category: 'orm');
    } catch (e) {
      _logService.error('Erro ao limpar banco de dados: $e', category: 'orm');
      rethrow;
    }
  }
}
