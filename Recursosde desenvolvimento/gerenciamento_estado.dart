// Exemplo de implementação usando Provider como gerenciador de estado

// 1. Modelo de dados
class UserModel {
  final String id;
  final String name;
  final String email;
  final String profileImageUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.profileImageUrl,
  });

  // Método para criar a partir de JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      profileImageUrl: json['profile_image_url'] as String? ?? '',
    );
  }

  // Método para converter para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profile_image_url': profileImageUrl,
    };
  }
}

// 2. Repositório de usuário
abstract class UserRepository {
  Future<UserModel?> getCurrentUser();
  Future<void> updateUserProfile(UserModel user);
  Future<void> logout();
}

// 3. Implementação do repositório
class UserRepositoryImpl implements UserRepository {
  final ApiService _apiService;
  final LocalStorage _localStorage;

  UserRepositoryImpl(this._apiService, this._localStorage);

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      // Tenta obter do cache local primeiro
      final cachedUserJson = await _localStorage.getValue('current_user');
      if (cachedUserJson != null) {
        return UserModel.fromJson(jsonDecode(cachedUserJson));
      }
      
      // Se não existir no cache, busca da API
      final response = await _apiService.get('/user/profile');
      if (response.statusCode == 200) {
        final user = UserModel.fromJson(response.data);
        // Salva no cache local
        await _localStorage.setValue('current_user', jsonEncode(user.toJson()));
        return user;
      }
      return null;
    } catch (e) {
      // Tratamento de erro
      print('Erro ao obter usuário: $e');
      return null;
    }
  }

  @override
  Future<void> updateUserProfile(UserModel user) async {
    try {
      final response = await _apiService.put(
        '/user/profile',
        data: user.toJson(),
      );
      
      if (response.statusCode == 200) {
        // Atualiza cache local
        await _localStorage.setValue('current_user', jsonEncode(user.toJson()));
      } else {
        throw Exception('Falha ao atualizar perfil');
      }
    } catch (e) {
      throw Exception('Erro na atualização do perfil: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _apiService.post('/auth/logout');
      await _localStorage.removeValue('current_user');
      await _localStorage.removeValue('auth_token');
    } catch (e) {
      print('Erro durante logout: $e');
      // Ainda assim, limpa dados locais
      await _localStorage.removeValue('current_user');
      await _localStorage.removeValue('auth_token');
    }
  }
}

// 4. Provider para gerenciamento de estado
class UserProvider extends ChangeNotifier {
  final UserRepository _userRepository;
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;
  
  UserProvider(this._userRepository);
  
  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  
  // Métodos
  Future<void> loadCurrentUser() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _currentUser = await _userRepository.getCurrentUser();
    } catch (e) {
      _error = 'Falha ao carregar dados do usuário';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> updateProfile({
    required String name,
    required String email,
    String? profileImageUrl,
  }) async {
    if (_currentUser == null) return false;
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final updatedUser = UserModel(
        id: _currentUser!.id,
        name: name,
        email: email,
        profileImageUrl: profileImageUrl ?? _currentUser!.profileImageUrl,
      );
      
      await _userRepository.updateUserProfile(updatedUser);
      _currentUser = updatedUser;
      return true;
    } catch (e) {
      _error = 'Falha ao atualizar perfil';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _userRepository.logout();
      _currentUser = null;
    } catch (e) {
      _error = 'Erro ao fazer logout';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

// 5. Configuração no main.dart
void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>(
          create: (_) => ApiService(),
        ),
        Provider<LocalStorage>(
          create: (_) => LocalStorage(),
        ),
        ProxyProvider2<ApiService, LocalStorage, UserRepository>(
          update: (_, apiService, localStorage, __) => 
              UserRepositoryImpl(apiService, localStorage),
        ),
        ChangeNotifierProxyProvider<UserRepository, UserProvider>(
          create: (context) => UserProvider(
            Provider.of<UserRepository>(context, listen: false),
          ),
          update: (_, repository, previousProvider) => 
              previousProvider ?? UserProvider(repository),
        ),
        // Outros providers da aplicação...
      ],
      child: MyApp(),
    ),
  );
}

// 6. Uso em um widget
class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Observar as mudanças no UserProvider
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        if (userProvider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (userProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Erro: ${userProvider.error}'),
                ElevatedButton(
                  onPressed: () {
                    userProvider.clearError();
                    userProvider.loadCurrentUser();
                  },
                  child: Text('Tentar novamente'),
                ),
              ],
            ),
          );
        }
        
        final user = userProvider.currentUser;
        if (user == null) {
          return Center(
            child: Text('Usuário não encontrado. Faça login novamente.'),
          );
        }
        
        return Scaffold(
          appBar: AppBar(title: Text('Perfil')),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: user.profileImageUrl.isNotEmpty
                      ? NetworkImage(user.profileImageUrl)
                      : null,
                  child: user.profileImageUrl.isEmpty
                      ? Text(user.name[0].toUpperCase())
                      : null,
                ),
                SizedBox(height: 16),
                Text(
                  user.name,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  user.email,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/edit-profile');
                  },
                  child: Text('Editar Perfil'),
                ),
                SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () async {
                    await userProvider.logout();
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                  child: Text('Sair'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}