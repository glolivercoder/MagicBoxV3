// Arquivo corrigido: orm_service.dart
// Correções principais:
// 1. Substituído operador '>' por '!= 0' em comparações com valores booleanos
// 2. Implementado método getItem para substituir chamada a readItem

// Trecho corrigido do método deleteBox
Future<int> deleteBox(int boxId) async {
  try {
    final result = await _databaseHelper.deleteBox(boxId);
    
    // Atualizar o cache
    if (result != 0) {  // Corrigido: substituir '>' por '!= 0' para comparar com valor booleano
      _boxCache.remove(boxId);
      _boxItemsCache.remove(boxId);
      
      // Remover itens do cache
      _itemCache.removeWhere((key, item) => item.boxId == boxId);
    }
    
    _logService.info(
      'Caixa excluída: $boxId',
      category: 'orm',
    );
    
    return result;
  } catch (e, stackTrace) {
    _logService.error(
      'Erro ao excluir caixa',
      error: e,
      stackTrace: stackTrace,
      category: 'orm',
    );
    rethrow;
  }
}

// Trecho corrigido do método deleteItem
Future<int> deleteItem(int itemId) async {
  try {
    // Obter o item antes de excluí-lo para saber a qual caixa ele pertence
    final item = _itemCache[itemId];
    
    final result = await _databaseHelper.deleteItem(itemId);
    
    // Atualizar o cache
    if (result != 0) {  // Corrigido: substituir '>' por '!= 0' para comparar com valor booleano
      _itemCache.remove(itemId);
      
      // Remover o item da lista de itens da caixa
      if (item != null && _boxItemsCache.containsKey(item.boxId)) {
        _boxItemsCache[item.boxId]!.removeWhere((i) => i.id == itemId);
      }
    }
    
    _logService.info(
      'Item excluído: $itemId',
      category: 'orm',
    );
    
    return result;
  } catch (e, stackTrace) {
    _logService.error(
      'Erro ao excluir item',
      error: e,
      stackTrace: stackTrace,
      category: 'orm',
    );
    rethrow;
  }
}

// Trecho corrigido do método moveItemToBox
Future<int> moveItemToBox(int itemId, int newBoxId) async {
  try {
    // Verificar se o item existe
    final item = await getItem(itemId);  // Corrigido: substituir readItem por getItem
    if (item == null) {
      throw Exception('Item não encontrado: $itemId');
    }
    
    // Verificar se a caixa de destino existe
    final box = await _databaseHelper.readBox(newBoxId);
    if (box == null) {
      throw Exception('Caixa de destino não encontrada: $newBoxId');
    }
    
    // Atualizar o item com a nova caixa
    final updatedItem = item.copyWith(
      boxId: newBoxId,
    );
    
    final result = await updateItem(updatedItem);
    
    _logService.info(
      'Item movido: $itemId para caixa $newBoxId',
      category: 'orm',
    );
    
    return result;
  } catch (e, stackTrace) {
    _logService.error(
      'Erro ao mover item',
      error: e,
      stackTrace: stackTrace,
      category: 'orm',
    );
    rethrow;
  }
}

// Método getItem implementado para substituir chamada a readItem
Future<Item?> getItem(int itemId) async {
  try {
    // Verificar se o item está em cache
    if (_itemCache.containsKey(itemId)) {
      return _itemCache[itemId];
    }

    // Carregar o item do banco de dados
    final item = await _databaseHelper.readItem(itemId);

    // Atualizar o cache
    if (item != null) {
      _itemCache[itemId] = item;
    }

    return item;
  } catch (e, stackTrace) {
    _logService.error(
      'Erro ao obter item',
      error: e,
      stackTrace: stackTrace,
      category: 'orm',
    );
    rethrow;
  }
}
