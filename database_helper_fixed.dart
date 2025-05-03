// Arquivo corrigido: database_helper.dart
// Correções principais:
// 1. Implementado método readItem que estava faltando
// 2. Corrigido parâmetro incorreto no construtor de Item (imageUrl → image)

// Método readItem implementado
Future<Item?> readItem(int id) async {
  _logService.info('Lendo item com ID: $id', category: 'database');
  
  // Garantir que os dados foram carregados
  if (!_dataLoaded) {
    await _loadPersistedData();
  }

  final db = await instance.database;

  if (kIsWeb || db == null) {
    // Buscar na lista em memória
    _logService.debug('Usando implementação web para ler item', category: 'database');
    
    final item = _items.firstWhere(
      (item) => item.id == id,
      orElse: () => Item(
        id: -1, 
        name: '', 
        boxId: -1, 
        description: '', 
        image: '',  // Corrigido: imageUrl → image
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
    
    if (item.id == -1) {
      _logService.warning('Item com ID $id não encontrado na memória', category: 'database');
      return null;
    }
    
    _logService.info('Item encontrado na memória: ${item.name}', category: 'database');
    return item;
  }

  // Para dispositivos móveis, usar SQLite
  _logService.debug('Usando implementação mobile para ler item', category: 'database');
  final maps = await db.query(
    'items',
    where: 'id = ?',
    whereArgs: [id],
  );

  if (maps.isNotEmpty) {
    _logService.info('Item encontrado no banco de dados', category: 'database');
    return Item.fromMap(maps.first);
  } else {
    _logService.warning('Item com ID $id não encontrado no banco de dados', category: 'database');
    return null;
  }
}
