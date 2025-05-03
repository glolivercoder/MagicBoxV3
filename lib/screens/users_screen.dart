import 'package:flutter/material.dart';
import 'package:boxmagic/services/log_service.dart';
import 'package:url_launcher/url_launcher.dart';

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
      'whatsapp': '+5511999999999',
      'role': 'Administrador',
      'avatar': null,
      'isActive': true,
    },
    {
      'id': 2,
      'name': 'João Silva',
      'email': 'joao@exemplo.com',
      'whatsapp': '+5511988888888',
      'role': 'Editor',
      'avatar': null,
      'isActive': true,
    },
    {
      'id': 3,
      'name': 'Maria Oliveira',
      'email': 'maria@exemplo.com',
      'whatsapp': '+5511977777777',
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
    
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController whatsappController = TextEditingController();
    String selectedRole = 'Visualizador';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo Usuário'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  hintText: 'Ex: João Silva',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Ex: joao@exemplo.com',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: whatsappController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'WhatsApp',
                  hintText: 'Ex: +5511999999999',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Função',
                  border: OutlineInputBorder(),
                ),
                value: selectedRole,
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
                  selectedRole = value!;
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
            onPressed: () {
              // Validar campos
              if (nameController.text.isEmpty || emailController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nome e Email são obrigatórios'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              // Adicionar novo usuário
              setState(() {
                _mockUsers.add({
                  'id': _mockUsers.length + 1,
                  'name': nameController.text,
                  'email': emailController.text,
                  'whatsapp': whatsappController.text,
                  'role': selectedRole,
                  'avatar': null,
                  'isActive': true,
                });
              });
              
              _logService.info('Novo usuário criado: ${nameController.text}', category: 'user');
              Navigator.of(context).pop();
              
              // Mostrar mensagem de sucesso
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Usuário criado com sucesso!'),
                  backgroundColor: Colors.green,
                ),
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
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalhes do Usuário: ${user['name']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar e informações básicas
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      user['name'].substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
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
                        Text(
                          'ID: ${user['id']}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 8),
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
                            const SizedBox(width: 8),
                            Container(
                              margin: const EdgeInsets.only(top: 8),
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
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const Divider(height: 32),
              
              // Informações de contato
              const Text(
                'Informações de Contato',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              // Email
              InkWell(
                onTap: () => _launchEmail(user['email']),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.email, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Email',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              user['email'],
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // WhatsApp
              if (user['whatsapp'] != null && user['whatsapp'].isNotEmpty)
                InkWell(
                  onTap: () => _launchWhatsApp(user['whatsapp']),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.message, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'WhatsApp',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                user['whatsapp'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.green,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              const Divider(height: 32),
              
              // Estatísticas
              const Text(
                'Estatísticas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              // Aqui você pode adicionar estatísticas como:
              // - Número de caixas gerenciadas
              // - Data de último acesso
              // - Etc.
              
              Row(
                children: [
                  const Icon(Icons.inbox, color: Colors.grey),
                  const SizedBox(width: 8),
                  const Text('Caixas gerenciadas: '),
                  Text(
                    '${user['id'] * 3}', // Valor mockado para exemplo
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.grey),
                  const SizedBox(width: 8),
                  const Text('Último acesso: '),
                  Text(
                    '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}', // Valor mockado para exemplo
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () {
              // Implementar edição de usuário
              Navigator.pop(context);
              _logService.info('Edição de usuário solicitada', category: 'user');
              
              // Mostrar mensagem temporária
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Funcionalidade de edição em implementação'),
                ),
              );
            },
            child: const Text('Editar'),
          ),
        ],
      ),
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

  // Método para abrir o aplicativo de email
  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
        _logService.info('Abrindo aplicativo de email para: $email', category: 'user');
      } else {
        _logService.error('Não foi possível abrir o aplicativo de email', category: 'user');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível abrir o aplicativo de email'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      _logService.error('Erro ao abrir o aplicativo de email: $e', category: 'user');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao abrir o aplicativo de email: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Método para abrir o WhatsApp
  Future<void> _launchWhatsApp(String phoneNumber) async {
    // Remover caracteres não numéricos
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Criar URI para o WhatsApp
    final Uri whatsappUri = Uri.parse('https://wa.me/$cleanNumber');
    
    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
        _logService.info('Abrindo WhatsApp para: $phoneNumber', category: 'user');
      } else {
        _logService.error('Não foi possível abrir o WhatsApp', category: 'user');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível abrir o WhatsApp'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      _logService.error('Erro ao abrir o WhatsApp: $e', category: 'user');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao abrir o WhatsApp: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                          IconButton(
                            icon: const Icon(Icons.email),
                            onPressed: () => _launchEmail(user['email']),
                          ),
                          IconButton(
                            icon: const Icon(Icons.message),
                            onPressed: () => _launchWhatsApp(user['whatsapp']),
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
