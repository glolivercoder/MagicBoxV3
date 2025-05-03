// Arquivo corrigido: search_header.dart
// Correções principais:
// 1. Corrigidos parâmetros incorretos na chamada do ItemDetailScreen

// Trecho corrigido do método _navigateToItemDetail
Future<void> _navigateToItemDetail(Item item) async {
  try {
    // Obter a caixa do item
    final box = await _ormService.getBoxWithItems(item.boxId);
    
    if (mounted) {
      // Navegar para a tela de detalhes do item
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ItemDetailScreen(
            item: item,
            boxName: box?.name ?? 'Caixa desconhecida',  // Corrigido: parâmetro boxName em vez de box
          ),
        ),
      );
      
      // Limpar a busca após navegar
      _clearSearch();
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao abrir detalhes do item: $e')),
      );
    }
    
    _logService.error(
      'Erro ao navegar para detalhes do item',
      error: e,
      category: 'navigation',
    );
  }
}
