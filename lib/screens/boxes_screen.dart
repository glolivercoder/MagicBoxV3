import 'package:flutter/material.dart';
import '../models/box.dart';
import '../screens/box_detail_screen.dart';
import '../screens/box_id_recognition_screen.dart';
import '../services/log_service.dart';
import '../services/orm_service.dart';
import '../services/barcode_scanner_service.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import '../screens/items_screen.dart';
import '../screens/barcode_generator_screen.dart';
import 'dart:math';

class BoxesScreen extends StatefulWidget {
  const BoxesScreen({super.key});

  // Métodos públicos para serem chamados pelo MainScreen
  void showBarcodeScanner(BuildContext context) {
    // Encontrar o estado atual e chamar o método
    final state = _BoxesScreenState.instance;
    if (state != null) {
      state._showBarcodeScanner(context);
    } else {
      // Fallback se o estado não estiver disponível
      LogService().info('Iniciando scanner de código de barras', category: 'scanner');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scanner de código de barras (em implementação)')),
      );
    }
  }

  void showBoxIdRecognition(BuildContext context) {
    // Encontrar o estado atual e chamar o método
    final state = _BoxesScreenState.instance;
    if (state != null) {
      state._showBoxIdRecognition(context);
    } else {
      // Fallback se o estado não estiver disponível
      LogService().info('Iniciando reconhecimento de ID de caixa', category: 'recognition');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reconhecimento de ID com IA (em implementação)')),
      );
    }
  }

  void showPrintLabelsDialog(BuildContext context) {
    // Encontrar o estado atual e chamar o método
    final state = _BoxesScreenState.instance;
    if (state != null) {
      state._showPrintLabelsDialog(context);
    } else {
      // Fallback se o estado não estiver disponível
      LogService().info('Abrindo diálogo de impressão de etiquetas', category: 'print');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impressão de etiquetas (em implementação)')),
      );
    }
  }

  void showNewBoxDialog(BuildContext context) {
    // Encontrar o estado atual e chamar o método
    final state = _BoxesScreenState.instance;
    if (state != null) {
      state._showNewBoxDialog(context);
    } else {
      // Fallback se o estado não estiver disponível
      LogService().info('Abrindo diálogo de nova caixa', category: 'box');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Criar nova caixa (em implementação)')),
      );
    }
  }

  @override
  _BoxesScreenState createState() => _BoxesScreenState();
}

class _BoxesScreenState extends State<BoxesScreen> {
  // Singleton para acessar o estado atual
  static _BoxesScreenState? instance;
  
  final LogService _logService = LogService();
  final OrmService _ormService = OrmService();
  final BarcodeScannerService _barcodeScannerService = BarcodeScannerService();
  
  List<Box> _boxes = [];
  bool _isLoading = true;
  String _searchQuery = '';
  
  // Lista de categorias predefinidas
  final List<String> _predefinedCategories = [
    'Ferramentas',
    'Itens Diversos',
    'Eletronicos',
    'Acessorios Musicais',
  ];
  
  String _selectedCategory = 'Itens Diversos'; // Categoria padrão
  
  // Controladores para os campos de texto
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    instance = this;
    _logService.info('Tela de caixas aberta', category: 'navigation');
    _loadBoxes();
    _createDefaultBoxesIfNeeded();
  }
  
  @override
  void dispose() {
    if (instance == this) {
      instance = null;
    }
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  // Carregar caixas do banco de dados
  Future<void> _loadBoxes() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final boxes = await _ormService.getAllBoxes();
      setState(() {
        _boxes = boxes;
        _isLoading = false;
      });
    } catch (e) {
      _logService.error('Erro ao carregar caixas: $e', category: 'boxes');
      setState(() {
        _isLoading = false;
      });
      
      // Mostrar mensagem de erro
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar caixas: $e')),
        );
      }
    }
  }
  
  // Pesquisar caixas
  Future<void> _searchBoxes(String query) async {
    setState(() {
      _isLoading = true;
      _searchQuery = query;
    });
    
    try {
      final boxes = await _ormService.searchBoxes(query);
      setState(() {
        _boxes = boxes;
        _isLoading = false;
      });
    } catch (e) {
      _logService.error('Erro ao pesquisar caixas: $e', category: 'boxes');
      setState(() {
        _isLoading = false;
      });
      
      // Mostrar mensagem de erro
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao pesquisar caixas: $e')),
        );
      }
    }
  }

  // Métodos privados chamados pelos métodos públicos da classe BoxesScreen
  void _showBarcodeScanner(BuildContext context) async {
    _logService.info('Iniciando scanner de código de barras/QR code', category: 'scanner');
    
    try {
      // Usar o serviço de scanner de código de barras
      final barcodeScanRes = await _barcodeScannerService.scanBarcode(context);
      
      // Se o usuário cancelou o escaneamento ou não retornou nenhum código
      if (barcodeScanRes == null || barcodeScanRes.isEmpty) {
        _logService.info('Escaneamento cancelado pelo usuário', category: 'scanner');
        return;
      }
      
      _logService.info('Código escaneado: $barcodeScanRes', category: 'scanner');
      
      // Extrair o ID da caixa do código escaneado
      final boxId = _barcodeScannerService.extractBoxId(barcodeScanRes);
      
      if (boxId != null && mounted) {
        // Buscar a caixa pelo ID
        final box = await _ormService.getBox(boxId);
        
        if (box != null && mounted) {
          // Navegar para a tela de detalhes da caixa
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BoxDetailScreen(box: box),
            ),
          );
        } else if (mounted) {
          // Caixa não encontrada
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Caixa com ID $boxId não encontrada'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else if (mounted) {
        // Código não reconhecido como ID de caixa
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Código não reconhecido como ID de caixa: $barcodeScanRes'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      _logService.error('Erro ao escanear código', error: e, category: 'scanner');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao escanear código: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showBoxIdRecognition(BuildContext context) {
    _logService.info('Iniciando reconhecimento de ID de caixa', category: 'recognition');
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BoxIdRecognitionScreen(),
      ),
    );
  }

  void _showPrintLabelsDialog(BuildContext context) {
    _logService.info('Abrindo gerador de etiquetas', category: 'print');
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeGeneratorScreen(
          boxes: _boxes,
        ),
      ),
    );
  }

  void _showNewBoxDialog(BuildContext context) {
    _logService.info('Abrindo diálogo de nova caixa', category: 'box');
    
    // Limpar os controladores
    _nameController.clear();
    _descriptionController.clear();
    _locationController.clear();
    _categoryController.clear();
    
    // Definir categoria padrão
    _selectedCategory = 'Itens Diversos';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Caixa'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Caixa',
                  hintText: 'Ex: Ferramentas',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  border: OutlineInputBorder(),
                ),
                items: _predefinedCategories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCategory = newValue;
                      _categoryController.text = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  hintText: 'Ex: Ferramentas de uso geral',
                ),
                maxLines: 2,
              ),
              TextField(
                controller: _locationController,
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
              final name = _nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('O nome da caixa é obrigatório')),
                );
                return;
              }
              
              final category = _selectedCategory;
              
              final description = _descriptionController.text.trim();
              final location = _locationController.text.trim();
              
              // Fechar o diálogo
              Navigator.of(context).pop();
              
              // Mostrar indicador de carregamento
              setState(() {
                _isLoading = true;
              });
              
              try {
                // Criar a caixa
                final now = DateTime.now().toIso8601String();
                final box = Box(
                  name: name,
                  category: category,
                  description: description.isNotEmpty ? description : null,
                  location: location.isNotEmpty ? location : null,
                  createdAt: now,
                );
                
                // Salvar no banco de dados
                await _ormService.saveBox(box);
                
                // Recarregar a lista de caixas
                await _loadBoxes();
                
                // Mostrar mensagem de sucesso
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Caixa criada com sucesso!')),
                  );
                }
              } catch (e) {
                _logService.error('Erro ao criar caixa: $e', category: 'boxes');
                setState(() {
                  _isLoading = false;
                });
                
                // Mostrar mensagem de erro
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao criar caixa: $e')),
                  );
                }
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }
  
  // Criar uma nova caixa
  Future<void> _createBox(BuildContext context) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O nome da caixa é obrigatório')),
      );
      return;
    }
    
    final category = _selectedCategory;
    
    final description = _descriptionController.text.trim();
    final location = _locationController.text.trim();
    
    // Fechar o diálogo
    Navigator.of(context).pop();
    
    // Mostrar indicador de carregamento
    setState(() {
      _isLoading = true;
    });
    
    await _createBoxAsync(name, category, description, location);
  }
  
  Future<void> _createBoxAsync(String name, String category, String description, String location) async {
    try {
      // Criar a caixa
      final now = DateTime.now().toIso8601String();
      final box = Box(
        name: name,
        category: category,
        description: description.isNotEmpty ? description : null,
        location: location.isNotEmpty ? location : null,
        createdAt: now,
      );
      
      // Salvar no banco de dados
      await _ormService.saveBox(box);
      
      // Recarregar a lista de caixas
      await _loadBoxes();
      
      // Mostrar mensagem de sucesso
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Caixa criada com sucesso!')),
        );
      }
    } catch (e) {
      _logService.error('Erro ao criar caixa: $e', category: 'boxes');
      setState(() {
        _isLoading = false;
      });
      
      // Mostrar mensagem de erro
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar caixa: $e')),
        );
      }
    }
  }
  
  // Mostrar diálogo de edição de caixa
  void _showEditBoxDialog(Box box) {
    _logService.info('Abrindo diálogo de edição de caixa: ${box.name}', category: 'box');
    
    // Preencher os controladores com os dados da caixa
    _nameController.text = box.name;
    _categoryController.text = box.category;
    _descriptionController.text = box.description ?? '';
    _locationController.text = box.location ?? '';
    
    // Definir a categoria selecionada
    _selectedCategory = box.category;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Caixa'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Caixa',
                  hintText: 'Ex: Ferramentas',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  border: OutlineInputBorder(),
                ),
                items: _predefinedCategories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCategory = newValue;
                      _categoryController.text = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  hintText: 'Ex: Ferramentas de uso geral',
                ),
                maxLines: 2,
              ),
              TextField(
                controller: _locationController,
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
            onPressed: () {
              // Usar a categoria selecionada através do copyWith
              final updatedBox = box.copyWith(
                category: _selectedCategory,
              );
              _updateBox(context, updatedBox);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
  
  // Atualizar uma caixa existente
  Future<void> _updateBox(BuildContext context, Box box) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O nome da caixa é obrigatório')),
      );
      return;
    }
    
    final category = _selectedCategory;
    
    final description = _descriptionController.text.trim();
    final location = _locationController.text.trim();
    
    // Fechar o diálogo
    Navigator.of(context).pop();
    
    // Mostrar indicador de carregamento
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Atualizar a caixa
      final now = DateTime.now().toIso8601String();
      final updatedBox = box.copyWith(
        name: name,
        category: category,
        description: description.isNotEmpty ? description : null,
        location: location.isNotEmpty ? location : null,
        updatedAt: now,
      );
      
      // Salvar no banco de dados
      await _ormService.saveBox(updatedBox);
      
      // Recarregar a lista de caixas
      await _loadBoxes();
      
      // Mostrar mensagem de sucesso
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Caixa atualizada com sucesso!')),
        );
      }
    } catch (e) {
      _logService.error('Erro ao atualizar caixa: $e', category: 'boxes');
      setState(() {
        _isLoading = false;
      });
      
      // Mostrar mensagem de erro
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar caixa: $e')),
        );
      }
    }
  }

  void _showBoxDetails(Box box) {
    _logService.info('Abrindo detalhes da caixa ${box.name}', category: 'box');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BoxDetailScreen(box: box),
      ),
    ).then((_) {
      // Recarregar a lista de caixas quando voltar da tela de detalhes
      _loadBoxes();
    });
  }

  void _deleteBox(Box box) {
    _logService.info('Caixa ${box.id} excluída', category: 'box');
    
    // Confirmar exclusão
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir a caixa "${box.name}"?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Fechar o diálogo
              Navigator.of(context).pop();
              
              // Mostrar indicador de carregamento
              setState(() {
                _isLoading = true;
              });
              
              try {
                // Excluir a caixa
                if (box.id != null) {
                  final success = await _ormService.deleteBox(box.id!);
                  
                  if (success) {
                    // Recarregar a lista de caixas
                    await _loadBoxes();
                    
                    // Mostrar mensagem de sucesso
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Caixa excluída com sucesso!')),
                      );
                    }
                  } else {
                    throw Exception('Não foi possível excluir a caixa');
                  }
                } else {
                  throw Exception('ID da caixa é nulo');
                }
              } catch (e) {
                _logService.error('Erro ao excluir caixa: $e', category: 'boxes');
                setState(() {
                  _isLoading = false;
                });
                
                // Mostrar mensagem de erro
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao excluir caixa: $e')),
                  );
                }
              }
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

  // Criar caixas padrão se não existirem
  Future<void> _createDefaultBoxesIfNeeded() async {
    try {
      final boxes = await _ormService.getAllBoxes();
      
      // Verificar se já existem caixas
      if (boxes.isEmpty) {
        _logService.info('Criando caixas padrão', category: 'boxes');
        
        // Lista de caixas padrão para criar
        final defaultBoxes = [
          {
            'name': 'Ferramentas',
            'category': 'Ferramentas',
            'description': 'Caixa para armazenar ferramentas',
            'location': 'Garagem'
          },
          {
            'name': 'Itens Diversos',
            'category': 'Itens Diversos',
            'description': 'Caixa para itens variados',
            'location': 'Despensa'
          },
          {
            'name': 'Eletrônicos',
            'category': 'Eletronicos',
            'description': 'Caixa para dispositivos eletrônicos',
            'location': 'Escritório'
          },
          {
            'name': 'Acessórios Musicais',
            'category': 'Acessorios Musicais',
            'description': 'Caixa para acessórios de instrumentos musicais',
            'location': 'Sala de Música'
          },
        ];
        
        // Criar cada caixa padrão
        final now = DateTime.now().toIso8601String();
        for (final boxData in defaultBoxes) {
          final box = Box(
            name: boxData['name']!,
            category: boxData['category']!,
            description: boxData['description'],
            location: boxData['location'],
            createdAt: now,
          );
          
          await _ormService.saveBox(box);
          _logService.info('Caixa padrão criada: ${box.name}', category: 'boxes');
        }
        
        // Recarregar a lista de caixas
        await _loadBoxes();
      }
    } catch (e) {
      _logService.error('Erro ao criar caixas padrão: $e', category: 'boxes');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Barra de pesquisa
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Pesquisar caixas',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _searchBoxes(value);
              },
            ),
          ),
          
          // Lista de caixas
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _boxes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.inbox,
                              size: 100,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Nenhuma caixa encontrada para "$_searchQuery"'
                                  : 'Nenhuma caixa encontrada',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Adicione uma nova caixa para começar',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () => _showNewBoxDialog(context),
                              icon: const Icon(Icons.add),
                              label: const Text('Adicionar Caixa'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadBoxes,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _boxes.length,
                          itemBuilder: (context, index) {
                            final box = _boxes[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              elevation: 2,
                              child: InkWell(
                                onTap: () => _showBoxDetails(box),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              box.name,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            onPressed: () => _showEditBoxDialog(box),
                                            color: Colors.blue,
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () => _deleteBox(box),
                                            color: Colors.red,
                                          ),
                                        ],
                                      ),
                                      if (box.description != null && box.description!.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          box.description!,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          if (box.location != null && box.location!.isNotEmpty) ...[
                                            const Icon(
                                              Icons.location_on,
                                              size: 16,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              box.location!,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const Spacer(),
                                          ] else
                                            const Spacer(),
                                          const Icon(
                                            Icons.category,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            box.category,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const Spacer(),
                                          const Icon(
                                            Icons.category,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${box.itemCount} ${box.itemCount == 1 ? 'item' : 'itens'}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: _boxes.isEmpty && !_isLoading
          ? null
          : FloatingActionButton(
              onPressed: () => _showNewBoxDialog(context),
              child: const Icon(Icons.add),
            ),
    );
  }
}
