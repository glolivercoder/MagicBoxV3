import 'package:flutter/material.dart';
import 'package:boxmagic/models/box.dart';
import 'package:boxmagic/models/item.dart';
import 'package:boxmagic/services/orm_service.dart';
import 'package:boxmagic/services/log_service.dart';
import 'package:qr_flutter/qr_flutter.dart';

class BoxDetailScreen extends StatefulWidget {
  final Box box;

  const BoxDetailScreen({super.key, required this.box});

  @override
  _BoxDetailScreenState createState() => _BoxDetailScreenState();
}

class _BoxDetailScreenState extends State<BoxDetailScreen> {
  final OrmService _ormService = OrmService();
  final LogService _logService = LogService();
  late Box _box;
  List<Item> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _box = widget.box;
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final items = await _ormService.getItemsByBox(_box.id!);
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar objetos: $e')),
        );
      }
    }
  }

  Future<void> _showEditBoxDialog() async {
    // Controladores para os campos de texto
    final nameController = TextEditingController(text: _box.name);
    final categoryController = TextEditingController(text: _box.category);
    final descriptionController = TextEditingController(text: _box.description ?? '');
    final locationController = TextEditingController(text: _box.location ?? '');

    final result = await showDialog<Box?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Caixa'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Caixa',
                  hintText: 'Ex: Ferramentas',
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
                  hintText: 'Ex: Ferramentas de uso geral',
                ),
                maxLines: 2,
              ),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Localização',
                  hintText: 'Ex: Garagem',
                ),
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
                  const SnackBar(content: Text('O nome da caixa é obrigatório')),
                );
                return;
              }
              
              final category = categoryController.text.trim();
              if (category.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('A categoria é obrigatória')),
                );
                return;
              }
              
              final description = descriptionController.text.trim();
              final location = locationController.text.trim();
              
              // Atualizar a caixa
              final now = DateTime.now().toIso8601String();
              final updatedBox = _box.copyWith(
                name: name,
                category: category,
                description: description.isNotEmpty ? description : null,
                location: location.isNotEmpty ? location : null,
                updatedAt: now,
              );
              
              Navigator.of(context).pop(updatedBox);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        // Salvar no banco de dados
        await _ormService.saveBox(result);
        
        // Atualizar a caixa na tela
        setState(() {
          _box = result;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Caixa atualizada com sucesso!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao atualizar caixa: $e')),
          );
        }
      }
    }
  }

  Future<void> _showNewItemDialog() async {
    // Verificar se o ID da caixa é válido
    if (_box.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: ID da caixa é nulo')),
      );
      return;
    }

    // Controladores para os campos de texto
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool?>(
      context: context,
      builder: (context) => AlertDialog(
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
              const SizedBox(height: 8),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  hintText: 'Ex: Ferramentas',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  hintText: 'Ex: Martelo de carpinteiro',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Text('Caixa: ${_box.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                  boxId: _box.id!,
                  createdAt: now,
                );
                
                // Salvar no banco de dados
                await _ormService.saveItem(item);
                
                Navigator.of(context).pop(true);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao criar item: $e')),
                );
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _loadItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item criado com sucesso!')),
        );
      }
    }
  }

  Future<void> _showObjectRecognition() async {
    // Verificar se o ID da caixa é válido
    if (_box.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: ID da caixa é nulo')),
      );
      return;
    }

    // Implementação temporária
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reconhecimento de objetos (em implementação)')),
    );

    // Aqui seria implementada a navegação para a tela de reconhecimento
    // Por enquanto, vamos apenas simular que algo foi adicionado
    await Future.delayed(const Duration(seconds: 2));
    await _loadItems();
  }

  Future<void> _deleteBox() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text(
          'Tem certeza que deseja excluir a caixa ${_box.name}?\n\n'
          'Todos os objetos dentro desta caixa também serão excluídos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Excluir a caixa (o ORM se encarrega de excluir os itens relacionados)
        await _ormService.deleteBox(_box.id!);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Caixa excluída com sucesso')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir caixa: $e')),
          );
        }
      }
    }
  }

  void _showQRCode() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Código QR da Caixa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: _box.id.toString(),
              version: QrVersions.auto,
              size: 200.0,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Text(
                '#${_box.id}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Text(
              _box.name,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_box.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteBox,
            tooltip: 'Excluir caixa',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Box details card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Categoria: ${_box.category}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ID: #${_box.id}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_box.description != null && _box.description!.isNotEmpty) ...[
                    const Text(
                      'Descrição:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(_box.description!),
                    const SizedBox(height: 8),
                  ],
                  if (_box.location != null && _box.location!.isNotEmpty) ...[
                    const Text(
                      'Localização:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(_box.location!),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    'Criada em: ${DateTime.parse(_box.createdAt).toLocal().toString().split('.')[0]}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Items list header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Objetos (${_items.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.qr_code),
                      tooltip: 'Mostrar código QR',
                      onPressed: _showQRCode,
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Editar caixa',
                      onPressed: _showEditBoxDialog,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Items list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.inventory_2,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Nenhum objeto nesta caixa',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _showObjectRecognition,
                                  icon: const Icon(Icons.camera_alt),
                                  label: const Text('Identificar com câmera'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton.icon(
                                  onPressed: _showNewItemDialog,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Adicionar manualmente'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadItems,
                        child: ListView.builder(
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  child: const Icon(Icons.inventory_2, color: Colors.white),
                                ),
                                title: Text(item.name),
                                subtitle: item.category != null && item.category!.isNotEmpty
                                    ? Text(item.category!)
                                    : null,
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  // Implementação temporária
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Detalhes do item: ${item.name} (em implementação)')),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _showObjectRecognition,
            tooltip: 'Identificar objeto com câmera',
            heroTag: 'box_detail_camera_fab',
            backgroundColor: Colors.green,
            child: const Icon(Icons.camera_enhance),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            onPressed: _showNewItemDialog,
            tooltip: 'Adicionar novo objeto',
            heroTag: 'box_detail_add_fab',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
