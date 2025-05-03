import 'package:flutter/material.dart';

/// Modelo de usuário do sistema BoxMagic
/// 
/// Representa um usuário que pode acessar o sistema com diferentes níveis de permissão.
class User {
  final int? id;
  final String name;
  final String email;
  final String role; // 'Administrador', 'Editor', 'Visualizador'
  final String? avatar;
  final bool isActive;
  final String createdAt;
  final String? updatedAt;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatar,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  /// Converte o objeto User para um Map<String, dynamic>
  /// 
  /// Útil para persistência em banco de dados ou serialização para JSON
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'avatar': avatar,
      'isActive': isActive ? 1 : 0, // SQLite não tem tipo booleano, usa 1/0
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Cria um objeto User a partir de um Map<String, dynamic>
  /// 
  /// Útil para deserialização de JSON ou leitura do banco de dados
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      role: map['role'],
      avatar: map['avatar'],
      isActive: map['isActive'] == 1, // Converte 1/0 para true/false
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
    );
  }

  /// Retorna uma cópia do objeto User com os campos especificados alterados
  /// 
  /// Útil para atualização de dados sem modificar o objeto original
  User copyWith({
    int? id,
    String? name,
    String? email,
    String? role,
    String? avatar,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      avatar: avatar ?? this.avatar,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Retorna a cor associada ao papel (role) do usuário
  Color getRoleColor() {
    switch (role) {
      case 'Administrador':
        return Colors.red.shade700;
      case 'Editor':
        return Colors.blue.shade700;
      case 'Visualizador':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  /// Verifica se o usuário tem permissão para uma determinada ação
  bool hasPermission(String action) {
    // Administrador tem acesso a tudo
    if (role == 'Administrador') return true;
    
    // Editor pode editar conteúdo, mas não configurações do sistema
    if (role == 'Editor') {
      return ['read', 'create', 'update', 'delete_own'].contains(action);
    }
    
    // Visualizador só pode ler
    if (role == 'Visualizador') {
      return ['read'].contains(action);
    }
    
    return false;
  }

  /// Retorna a primeira letra do nome para uso em avatares
  String get initialLetter => name.isNotEmpty ? name[0].toUpperCase() : '?';
}
