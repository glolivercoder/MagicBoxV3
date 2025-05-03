# Guia de Boas Práticas para Flutter

## Nomenclatura e Organização

1. **Convenções de Nomenclatura**
   - Classes: PascalCase (ex: `HomeScreen`, `UserRepository`)
   - Variáveis e funções: camelCase (ex: `userName`, `fetchUserData()`)
   - Constantes: SNAKE_CASE_CAPS (ex: `API_BASE_URL`, `DEFAULT_TIMEOUT`)
   - Arquivos: snake_case.dart (ex: `user_repository.dart`, `home_screen.dart`)

2. **Organização de Importações**
   - Agrupar imports por tipo (Dart, Flutter, pacotes externos, importações locais)
   - Usar imports relativos para arquivos dentro do mesmo pacote
   ```dart
   // Dart imports
   import 'dart:async';
   import 'dart:io';
   
   // Flutter imports
   import 'package:flutter/material.dart';
   import 'package:flutter/services.dart';
   
   // Package imports
   import 'package:provider/provider.dart';
   import 'package:http/http.dart' as http;
   
   // Local imports
   import '../models/user.dart';
   import '../utils/validators.dart';
   ```

## Arquitetura e Design

1. **Separação de Responsabilidades**
   - Cada classe deve ter uma única responsabilidade
   - Separar lógica de negócios da UI
   - Utilizar repositórios para acesso a dados

2. **Gerenciamento de Estado**
   - Escolher um único padrão de gerenciamento de estado para todo o projeto
   - Opções recomendadas: Provider, Bloc/Cubit, Riverpod
   - Evitar misturar diferentes soluções de gerenciamento de estado

3. **Widgets**
   - Preferir StatelessWidget quando possível
   - Dividir widgets complexos em componentes menores e reutilizáveis
   - Usar `const` para widgets que não mudam
   - Evitar árvores de widgets profundamente aninhadas

## Código Limpo

1. **Métodos**
   - Manter métodos curtos e com responsabilidade única
   - Limite de ~30 linhas por método como regra geral
   - Nomear métodos com verbos que descrevam a ação

2. **Comentários**
   - Documentar APIs públicas com comentários de documentação (///)
   - Evitar comentários óbvios
   - Comentar código complexo ou não intuitivo

3. **Tratamento de Erros**
   - Sempre tratar exceções
   - Criar tipos de erro específicos para a aplicação
   - Implementar um sistema consistente de feedback para o usuário

## Performance

1. **Listas**
   - Usar ListView.builder para listas longas
   - Implementar paginação para conjuntos de dados grandes
   - Utilizar chaves únicas para widgets em listas

2. **Imagens**
   - Otimizar tamanho de arquivos de imagem
   - Utilizar cache para imagens da rede
   - Considerar o uso de SVGs para ícones

3. **Assincronismo**
   - Utilizar async/await em vez de Futures encadeados
   - Cancelar operações assíncronas quando não forem mais necessárias
   - Mostrar feedback visual durante operações de longa duração

## Testes

1. **Cobertura de Testes**
   - Escrever testes unitários para lógica de negócios
   - Implementar testes de widget para componentes de UI
   - Criar testes de integração para fluxos críticos

2. **Testabilidade**
   - Injetar dependências em vez de instanciá-las diretamente
   - Usar interfaces para permitir mock objects nos testes
   - Separar lógica de UI para facilitar testes unitários