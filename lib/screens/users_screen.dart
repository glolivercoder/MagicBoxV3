import 'package:flutter/material.dart';
import 'package:boxmagic/services/log_service.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  _UsersScreenState createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final LogService _logService = LogService();
  final List<Map<String, dynamic>> _mockUsers = [
    {
      'id': 1,
      'name': 'Administrador',
      'email': 'admin@boxmagic.com',
      'role': 'Administrador',
      'avatar': null,
      'isActive': true,
    },
    {
      'id': 2,
      'name': 'João Silva',
      'email': 'joao@exemplo.com',
      'role': 'Editor',
      'avatar': null,
      'isActive': true,
    },
    {
      'id': 3,
      'name': 'Maria Oliveira',
      'email': 'maria@exemplo.com',
      'role': 'Visualizador',
      'avatar': null,
      'isActive': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _logService.info('Tela de usuários aberta', category: 'navigation');
  }

  void _showNewUserDialog() {
    _logService.info('Abrindo diálogo de novo usuário', category: 'user');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo Usuário'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Nome',
                hintText: 'Ex: João Silva',
              ),
              onChanged: (value) {
                // Implementar
              },
            ),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Ex: joao@exemplo.com',
              ),
              onChanged: (value) {
                // Implementar
              },
            ),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Função',
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Administrador',
                  child: Text('Administrador'),
                ),
                DropdownMenuItem(
                  value: 'Editor',
                  child: Text('Editor'),
                ),
                DropdownMenuItem(
                  value: 'Visualizador',
                  child: Text('Visualizador'),
                ),
              ],
              onChanged: (value) {
                // Implementar
              },
            ),
          ],
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
              // Implementar criação de usuário
              _logService.info('Novo usuário criado', category: 'user');
              Navigator.of(context).pop();
              
              // Mostrar mensagem de sucesso
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Usuário criado com sucesso!')),
              );
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  void _showUserDetails(Map<String, dynamic> user) {
    _logService.info('Detalhes do usuário ${user['id']} abertos', category: 'navigation');
    // Implementação temporária
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Detalhes do usuário: ${user['name']} (em implementação)')),
    );
  }

  void _toggleUserStatus(Map<String, dynamic> user) {
    setState(() {
      user['isActive'] = !user['isActive'];
    });
    
    _logService.info(
      'Status do usuário ${user['id']} alterado para ${user['isActive'] ? 'ativo' : 'inativo'}',
      category: 'user',
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Usuário ${user['isActive'] ? 'ativado' : 'desativado'} com sucesso!')),
    );
  }

  void _deleteUser(Map<String, dynamic> user) {
    _logService.info('Usuário ${user['id']} excluído', category: 'user');
    
    // Confirmar exclusão
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir o usuário "${user['name']}"?'),
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
                _mockUsers.removeWhere((u) => u['id'] == user['id']);
              });
              
              Navigator.of(context).pop();
              
              // Mostrar mensagem de sucesso
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Usuário excluído com sucesso!')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _mockUsers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person_off,
                    size: 100,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Nenhum usuário encontrado',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Adicione um novo usuário para começar',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _showNewUserDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar Usuário'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _mockUsers.length,
              itemBuilder: (context, index) {
                final user = _mockUsers[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  child: InkWell(
                    onTap: () => _showUserDetails(user),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Avatar do usuário
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.grey.shade200,
                            child: user['avatar'] != null
                                ? Image.asset(
                                    user['avatar'],
                                    fit: BoxFit.cover,
                                  )
                                : Text(
                                    user['name'].substring(0, 1).toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 16),
                          // Detalhes do usuário
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user['name'],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user['email'],
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
                                        user['role'],
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue.shade800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: user['isActive']
                                            ? Colors.green.shade100
                                            : Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        user['isActive'] ? 'Ativo' : 'Inativo',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: user['isActive']
                                              ? Colors.green.shade800
                                              : Colors.red.shade800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Botões de ação
                          IconButton(
                            icon: Icon(
                              user['isActive'] ? Icons.toggle_on : Icons.toggle_off,
                              color: user['isActive'] ? Colors.green : Colors.grey,
                              size: 28,
                            ),
                            onPressed: () => _toggleUserStatus(user),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteUser(user),
                            color: Colors.red,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewUserDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
