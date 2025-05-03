import 'package:flutter/material.dart';
import 'dart:convert';

/// Modelo de caixa do sistema BoxMagic
/// 
/// Representa uma caixa física que contém itens catalogados.
/// Cada caixa possui um identificador único, nome, descrição opcional,
/// localização física, código QR para identificação rápida, e timestamps
/// de criação e atualização.
class Box {
  final int? id;
  final String name;
  final String category;
  final String? description;
  final String? location;
  final String? qrCode;
  final String createdAt;
  final String? updatedAt;
  final int? itemCount; // Contador de itens na caixa (não persistido diretamente)

  Box({
    this.id,
    required this.name,
    required this.category,
    this.description,
    this.location,
    this.qrCode,
    required this.createdAt,
    this.updatedAt,
    this.itemCount,
  });

  /// Converte o objeto Box para um Map<String, dynamic>
  /// 
  /// Útil para persistência em banco de dados ou serialização para JSON
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'location': location,
      'qrCode': qrCode,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      // itemCount não é persistido diretamente, é calculado a partir dos itens relacionados
    };
  }

  /// Cria um objeto Box a partir de um Map<String, dynamic>
  /// 
  /// Útil para deserialização de JSON ou leitura do banco de dados
  factory Box.fromMap(Map<String, dynamic> map) {
    return Box(
      id: map['id'],
      name: map['name'],
      category: map['category'] ?? 'Geral', // Valor padrão se não existir
      description: map['description'],
      location: map['location'],
      qrCode: map['qrCode'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
      itemCount: map['itemCount'] ?? 0,
    );
  }

  /// Retorna uma cópia do objeto Box com os campos especificados alterados
  /// 
  /// Útil para atualização de dados sem modificar o objeto original
  Box copyWith({
    int? id,
    String? name,
    String? category,
    String? description,
    String? location,
    String? qrCode,
    String? createdAt,
    String? updatedAt,
    int? itemCount,
  }) {
    return Box(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      location: location ?? this.location,
      qrCode: qrCode ?? this.qrCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      itemCount: itemCount ?? this.itemCount,
    );
  }

  /// Converte o objeto Box para uma string JSON
  String toJson() => json.encode(toMap());

  /// Cria um objeto Box a partir de uma string JSON
  factory Box.fromJson(String source) => Box.fromMap(json.decode(source));

  /// Retorna uma representação textual do objeto Box
  @override
  String toString() {
    return 'Box(id: $id, name: $name, location: $location, itemCount: $itemCount)';
  }

  /// Verifica se duas caixas são iguais comparando seus IDs
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Box && other.id == id;
  }

  /// Gera um código hash para o objeto Box
  @override
  int get hashCode => id.hashCode;

  /// Retorna o texto a ser exibido na etiqueta da caixa
  String getLabelText() {
    final locationText = location != null && location!.isNotEmpty 
        ? '[$location]' 
        : '';
    return '$name $locationText';
  }

  /// Retorna uma cor de texto contrastante com a cor da caixa
  // Color getContrastingTextColor() {
  //   // Cálculo de luminância para determinar se o texto deve ser claro ou escuro
  //   final luminance = color.computeLuminance();
  //   return luminance > 0.5 ? Colors.black : Colors.white;
  // }
}
