import 'package:flutter/material.dart';
import 'package:boxmagic/models/item.dart';
import 'package:boxmagic/screens/object_recognition_screen.dart';
import 'package:boxmagic/models/box.dart';
import 'package:boxmagic/services/log_service.dart';
import 'package:boxmagic/services/orm_service.dart';
import 'package:boxmagic/services/database_helper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  // Métodos públicos para serem chamados pelo MainScreen
  void showObjectRecognition(BuildContext context) {
    // Encontrar o estado atual e chamar o método
    final state = _ItemsScreenState.instance;
    if (state != null) {
      state._showObjectRecognition(context);
    } else {
      // Fallback se o estado não estiver disponível
      LogService().info('Iniciando reconhecimento de objeto', category: 'recognition');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reconhecimento de objeto com IA (em implementação)')),
      );
    }
  }

  void generateReport(BuildContext context) {
    // Encontrar o estado atual e chamar o método
    final state = _ItemsScreenState.instance;
    if (state != null) {
      state._generateReport(context);
    } else {
      // Fallback se o estado não estiver disponível
      LogService().info('Gerando relatório de itens', category: 'report');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Relatório de itens (em implementação)')),
      );
    }
  }

  void showNewBoxDialog(BuildContext context) {
    // Encontrar o estado atual e chamar o método
    final state = _ItemsScreenState.instance;
    if (state != null) {
      state._showNewBoxFromItemsScreen(context);
    } else {
      // Fallback se o estado não estiver disponível
      LogService().info('Abrindo diálogo de nova caixa a partir da tela de itens', category: 'box');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Criar nova caixa (em implementação)')),
      );
    }
  }

  void showItemRecognition(BuildContext context) {
    // Encontrar o estado atual e chamar o método
    final state = _ItemsScreenState.instance;
    if (state != null) {
      state._showItemRecognition(context);
    } else {
      // Fallback se o estado não estiver disponível
      LogService().info('Iniciando reconhecimento de item', category: 'recognition');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reconhecimento de item com IA (em implementação)')),
      );
    }
  }

  void showNewItemDialog(BuildContext context, {Box? selectedBox}) {
    // Encontrar o estado atual e chamar o método
    final state = _ItemsScreenState.instance;
    if (state != null) {
      state._showNewItemDialog(context, selectedBox: selectedBox);
    } else {
      // Fallback se o estado não estiver disponível
      LogService().info('Abrindo diálogo de novo item', category: 'item');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Criar novo item (em implementação)')),
      );
    }
  }

  @override
  _ItemsScreenState createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  // Singleton para acessar o estado atual
  static _ItemsScreenState? instance;
  
  final LogService _logService = LogService();
  final OrmService _ormService = OrmService();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Item> _items = [];
  List<Box> _boxes = [];
  bool _isLoading = true;

  String _searchQuery = '';
  String _selectedCategory = 'Todos';
  List<String> _categories = ['Todos'];

  @override
  void initState() {
    super.initState();
    instance = this;
    _logService.info('Tela de itens aberta', category: 'navigation');
    _loadItems();
  }
  
  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Carregar itens do banco de dados
      final items = await _ormService.getAllItems();
      
      // Carregar caixas para usar no reconhecimento de objetos
      final boxes = await _databaseHelper.getAllBoxes();
      
      // Extrair categorias únicas dos itens
      final Set<String> categories = {'Todos'};
      for (final item in items) {
        if (item.category != null && item.category!.isNotEmpty) {
          categories.add(item.category!);
        }
      }
      
      setState(() {
        _items = items;
        _boxes = boxes;
        _categories = categories.toList();
        _isLoading = false;
      });
      
      _logService.info('Itens carregados: ${items.length}', category: 'data');
    } catch (e) {
      _logService.error('Erro ao carregar itens', error: e, category: 'data');
      
      setState(() {
        _items = [];
        _boxes = [];
        _categories = ['Todos'];
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar itens: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Métodos privados chamados pelos métodos públicos da classe ItemsScreen
  void _showObjectRecognition(BuildContext context) {
    _logService.info('Abrindo tela de reconhecimento de objetos', category: 'items');
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ObjectRecognitionScreen(boxes: _boxes),
      ),
    ).then((value) {
      if (value == true) {
        // Recarregar a lista de itens se um novo item foi adicionado
        _loadItems();
      }
    });
  }

  void _generateReport(BuildContext context) {
    _logService.info('Gerando relatório de itens', category: 'report');
    // Implementação temporária
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Relatório de itens (em implementação)')),
    );
  }

  void _showNewBoxFromItemsScreen(BuildContext context) {
    _logService.info('Abrindo diálogo de nova caixa a partir da tela de itens', category: 'box');
    // Implementação temporária
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Criar nova caixa (em implementação)')),
    );
  }

  void _showItemRecognition(BuildContext context) {
    _logService.info('Iniciando reconhecimento de item', category: 'recognition');
    // Implementação temporária
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reconhecimento de item com IA (em implementação)')),
    );
  }

  void _showNewItemDialog(BuildContext context, {Box? selectedBox}) {
    _logService.info('Abrindo diálogo de novo item', category: 'item');
    
    // Controladores para os campos de texto
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    final descriptionController = TextEditingController();
    
    // Serviço ORM para operações de banco de dados
    final ormService = OrmService();
    
    // Lista para armazenar as caixas disponíveis
    List<Box> boxes = [];
    int? selectedBoxId = selectedBox?.id;
    
    // Carregar as caixas disponíveis
    ormService.getAllBoxes().then((loadedBoxes) {
      boxes = loadedBoxes;
      if (mounted) {
        setState(() {});
      }
    }).catchError((error) {
      _logService.error('Erro ao carregar caixas: $error', category: 'item');
    });
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Novo Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do Item',
                    hintText: 'Ex: Martelo',
                  ),
                  autofocus: true,
                ),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    hintText: 'Ex: Ferramentas',
                  ),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    hintText: 'Ex: Martelo de carpinteiro',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int?>(
                  decoration: const InputDecoration(
                    labelText: 'Caixa',
                    hintText: 'Selecione uma caixa',
                  ),
                  value: selectedBoxId,
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Sem caixa'),
                    ),
                    ...boxes.map((box) => DropdownMenuItem<int?>(
                      value: box.id,
                      child: Text(box.name),
                    )).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedBoxId = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('O nome do item é obrigatório')),
                  );
                  return;
                }
                
                final category = categoryController.text.trim();
                final description = descriptionController.text.trim();
                
                try {
                  // Criar o item
                  final now = DateTime.now().toIso8601String();
                  final item = Item(
                    name: name,
                    category: category.isNotEmpty ? category : null,
                    description: description.isNotEmpty ? description : null,
                    boxId: selectedBoxId,
                    createdAt: now,
                  );
                  
                  // Salvar no banco de dados
                  await ormService.saveItem(item);
                  
                  // Fechar o diálogo
                  Navigator.of(context).pop();
                  
                  // Atualizar a lista de itens
                  if (mounted) {
                    setState(() {
                      // A lista será atualizada no método build
                    });
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Item criado com sucesso!')),
                    );
                  }
                } catch (e) {
                  _logService.error('Erro ao criar item: $e', category: 'item');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao criar item: $e')),
                  );
                }
              },
              child: const Text('Criar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showItemDetails(Item item) {
    _logService.info('Detalhes do item ${item.id} abertos', category: 'navigation');
    // Implementação temporária
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Detalhes do item: ${item.name} (em implementação)')),
    );
  }

  void _deleteItem(Item item) {
    _logService.info('Item ${item.id} excluído', category: 'item');
    
    // Confirmar exclusão
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir o item "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // Implementar exclusão
              setState(() {
                _items.removeWhere((i) => i.id == item.id);
              });
              
              Navigator.of(context).pop();
              
              // Mostrar mensagem de sucesso
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Item excluído com sucesso!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  List<Item> _getFilteredItems() {
    return _items.where((item) {
      final matchesSearch = item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (item.description != null && item.description!.toLowerCase().contains(_searchQuery.toLowerCase()));
      
      final matchesCategory = _selectedCategory == 'Todos' || 
          item.category == _selectedCategory;
      
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _getFilteredItems();
    
    return Scaffold(
      body: Column(
        children: [
          // Barra de pesquisa e filtros
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Pesquisar itens',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((category) {
                      final isSelected = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedCategory = category;
                              });
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de itens
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : filteredItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.category,
                              size: 100,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Nenhum item encontrado',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _searchQuery.isNotEmpty || _selectedCategory != 'Todos'
                                  ? 'Tente ajustar seus filtros de busca'
                                  : 'Adicione um novo item para começar',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 2,
                            child: InkWell(
                              onTap: () => _showItemDetails(item),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Imagem ou ícone do item
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.inventory_2,
                                        size: 30,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Detalhes do item
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item.description ?? '',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade100,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  item.category ?? '',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.blue.shade800,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(
                                                Icons.inbox,
                                                size: 16,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  item.boxName ?? '',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Botão de exclusão
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => _deleteItem(item),
                                      color: Colors.red,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => widget.showNewItemDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    if (instance == this) {
      instance = null;
    }
    super.dispose();
  }
}
