import 'package:flutter/material.dart';
import 'dart:convert';
import 'box.dart';

/// Modelo de item do sistema BoxMagic
/// 
/// Representa um objeto físico armazenado em uma caixa.
/// Cada item possui um identificador único, nome, categoria opcional,
/// descrição, imagem opcional, referência à caixa onde está armazenado,
/// e timestamps de criação e atualização.
class Item {
  final int? id;
  final String name;
  final String? category;
  final String? description;
  final String? image;
  final int? boxId;
  final String? boxName;
  final List<String> tags;
  final String createdAt;
  final String? updatedAt;
  final String? lastViewedAt;

  Item({
    this.id,
    required this.name,
    this.category,
    this.description,
    this.image,
    this.boxId,
    this.boxName,
    this.tags = const [],
    required this.createdAt,
    this.updatedAt,
    this.lastViewedAt,
  });

  /// Converte o objeto Item para um Map<String, dynamic>
  /// 
  /// Útil para persistência em banco de dados ou serialização para JSON
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'image': image,
      'boxId': boxId,
      'boxName': boxName,
      'tags': jsonEncode(tags), // Converte a lista de tags para JSON
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastViewedAt': lastViewedAt,
    };
  }

  /// Cria um objeto Item a partir de um Map<String, dynamic>
  /// 
  /// Útil para deserialização de JSON ou leitura do banco de dados
  factory Item.fromMap(Map<String, dynamic> map) {
    List<String> parseTags(dynamic tagsData) {
      if (tagsData == null) return [];
      if (tagsData is String) {
        try {
          final List<dynamic> decoded = jsonDecode(tagsData);
          return decoded.map((e) => e.toString()).toList();
        } catch (e) {
          return [];
        }
      }
      if (tagsData is List) {
        return tagsData.map((e) => e.toString()).toList();
      }
      return [];
    }

    return Item(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      description: map['description'],
      image: map['image'],
      boxId: map['boxId'],
      boxName: map['boxName'],
      tags: parseTags(map['tags']),
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
      lastViewedAt: map['lastViewedAt'],
    );
  }

  /// Retorna uma cópia do objeto Item com os campos especificados alterados
  /// 
  /// Útil para atualização de dados sem modificar o objeto original
  Item copyWith({
    int? id,
    String? name,
    String? category,
    String? description,
    String? image,
    int? boxId,
    String? boxName,
    List<String>? tags,
    String? createdAt,
    String? updatedAt,
    String? lastViewedAt,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      image: image ?? this.image,
      boxId: boxId ?? this.boxId,
      boxName: boxName ?? this.boxName,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastViewedAt: lastViewedAt ?? this.lastViewedAt,
    );
  }

  /// Converte o objeto Item para uma string JSON
  String toJson() => json.encode(toMap());

  /// Cria um objeto Item a partir de uma string JSON
  factory Item.fromJson(String source) => Item.fromMap(json.decode(source));

  /// Retorna uma representação textual do objeto Item
  @override
  String toString() {
    return 'Item(id: $id, name: $name, category: $category, boxId: $boxId)';
  }

  /// Verifica se dois itens são iguais comparando seus IDs
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Item && other.id == id;
  }

  /// Gera um código hash para o objeto Item
  @override
  int get hashCode => id.hashCode;

  /// Retorna uma cor baseada na categoria do item
  Color getCategoryColor() {
    if (category == null || category!.isEmpty) {
      return Colors.grey;
    }

    // Mapeamento de categorias para cores
    final Map<String, Color> categoryColors = {
      'Ferramentas': Colors.orange,
      'Documentos': Colors.blue,
      'Eletrônicos': Colors.purple,
      'Roupas': Colors.green,
      'Decoração': Colors.pink,
      'Livros': Colors.amber,
      'Brinquedos': Colors.red,
      'Cozinha': Colors.teal,
    };

    return categoryColors[category] ?? Colors.grey;
  }

  /// Adiciona uma tag ao item
  Item addTag(String tag) {
    if (tag.isEmpty || tags.contains(tag)) {
      return this;
    }
    final newTags = List<String>.from(tags)..add(tag);
    return copyWith(tags: newTags);
  }

  /// Remove uma tag do item
  Item removeTag(String tag) {
    if (!tags.contains(tag)) {
      return this;
    }
    final newTags = List<String>.from(tags)..remove(tag);
    return copyWith(tags: newTags);
  }

  /// Atualiza o timestamp de última visualização para o momento atual
  Item markAsViewed() {
    final now = DateTime.now().toIso8601String();
    return copyWith(lastViewedAt: now);
  }

  /// Verifica se o item foi visualizado recentemente (nos últimos 7 dias)
  bool get isRecentlyViewed {
    if (lastViewedAt == null) return false;
    
    final lastViewed = DateTime.parse(lastViewedAt!);
    final now = DateTime.now();
    final difference = now.difference(lastViewed);
    
    return difference.inDays < 7;
  }
}
