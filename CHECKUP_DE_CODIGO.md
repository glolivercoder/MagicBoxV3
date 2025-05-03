# CHECKUP DE CÓDIGO - BoxMagic

Este documento contém o plano de implementação das funcionalidades do aplicativo BoxMagic, organizadas por ordem de complexidade e dependência. Cada item será implementado, testado e marcado como concluído antes de passar para o próximo.

## Estrutura de Diretórios e Arquitetura

- [x] Estrutura básica de pastas (lib/models, lib/screens, lib/services, lib/widgets)
- [x] Arquivos principais de UI (main.dart, main_screen.dart)
- [x] Telas principais (boxes_screen.dart, items_screen.dart, users_screen.dart)
- [x] Widgets reutilizáveis (circular_logo.dart, search_header.dart, etc.)
- [x] Configuração de temas e estilos

## Banco de Dados e Persistência

### 1. Modelo de Dados e Relações 

- [x] Implementação do modelo Box (caixa)
  - Atributos: id, nome, descrição, localização, categoria, data de criação
  - Métodos: toMap, fromMap, copyWith
  
- [x] Implementação do modelo Item (item)
  - Atributos: id, nome, categoria, descrição, imagem, boxId, data de criação
  - Métodos: toMap, fromMap, copyWith
  
- [x] Implementação do modelo User (usuário)
  - Atributos: id, nome, email, função, avatar, ativo
  - Métodos: toMap, fromMap, copyWith

- [x] Definição das relações entre modelos
  - Box -> Item (1:N)
  - User -> Box (N:M)

### 2. Serviço de Banco de Dados 

- [x] Implementação do DatabaseHelper
  - Inicialização do banco SQLite
  - Criação das tabelas
  - Métodos de migração e atualização

- [x] Implementação do ORM Service
  - Métodos CRUD para Box
  - Métodos CRUD para Item
  - Métodos CRUD para User
  - Consultas relacionais

### 3. Serviço de Persistência 

- [x] Implementação do PersistenceService
  - Métodos para backup de dados
  - Métodos para restauração de dados
  - Exportação e importação de dados

## Funcionalidades de Negócio

### 4. Gerenciamento de Caixas 

- [x] Criação de caixas
  - Formulário de criação
  - Validação de dados
  - Persistência no banco

- [x] Edição de caixas
  - Formulário de edição
  - Atualização no banco

- [x] Exclusão de caixas
  - Confirmação de exclusão
  - Tratamento de itens relacionados

- [x] Listagem e filtro de caixas
  - Ordenação por nome, data, etc.
  - Filtro por localização

### 5. Gerenciamento de Itens 

- [x] Criação de itens
  - Formulário de criação
  - Seleção de caixa relacionada
  - Upload de imagem

- [x] Edição de itens
  - Formulário de edição
  - Atualização no banco

- [x] Exclusão de itens
  - Confirmação de exclusão

- [x] Listagem e filtro de itens
  - Ordenação por nome, categoria, etc.
  - Filtro por caixa, categoria

- [x] Movimentação de itens entre caixas
  - Seleção de caixa de destino
  - Atualização de relações

### 6. Impressão de Etiquetas 

- [x] Seleção de modelo de etiqueta
  - Modelos Pimaco
  - Tamanhos personalizados

- [x] Geração de etiquetas
  - Código de barras
  - QR Code
  - Informações da caixa

- [x] Exportação para PDF
  - Formatação para impressão
  - Ajuste de margens

### 7. Reconhecimento de Objetos e Caixas 

- [x] Integração com câmera
  - Captura de imagem
  - Acesso à galeria

- [x] Reconhecimento de ID de caixa
  - Detecção de código de barras
  - Detecção de QR Code

- [x] Reconhecimento de objetos
  - Integração com modelo de IA
  - Sugestão de categorias

## Testes e Otimização

- [x] Testes unitários
  - Modelos
  - Serviços

- [x] Testes de integração
  - Fluxos de usuário
  - Persistência de dados

- [x] Otimização de desempenho
  - Carregamento lazy de imagens
  - Paginação de listas

## Documentação

- [x] Documentação de código
  - Comentários em classes e métodos
  - Documentação de API

- [x] Manual do usuário
  - Instruções de uso
  - Screenshots

---

## Progresso de Implementação

### Implementação Atual: Integração com API Gemini para Reconhecimento de Objetos e IDs de Caixas

**Status:** Concluído

**Descrição:** Implementação da integração com a API Gemini do Google para reconhecimento de objetos e IDs de caixas usando visão computacional e IA generativa.

**Alterações Realizadas:**

1. **Implementação do GeminiService:**
   - Criação de serviço para comunicação com a API Gemini
   - Métodos implementados:
     - Inicialização e configuração da API
     - Gerenciamento de chave da API (obtenção e atualização)
     - Reconhecimento de IDs de caixas em imagens
     - Análise de objetos em imagens
     - Reconhecimento de texto manuscrito

2. **Tela de Reconhecimento de ID de Caixa:**
   - Implementação de tela para captura de fotos de IDs de caixas
   - Integração com a câmera do dispositivo
   - Processamento da imagem usando a API Gemini
   - Busca da caixa correspondente no banco de dados
   - Navegação para a tela de detalhes da caixa quando encontrada

3. **Tela de Reconhecimento de Objetos:**
   - Implementação de tela para captura de fotos de objetos
   - Integração com a câmera do dispositivo
   - Análise do objeto usando a API Gemini
   - Preenchimento automático de nome e descrição do objeto
   - Salvamento do objeto no banco de dados

4. **Configuração da API Gemini:**
   - Adição de seção na tela de configurações para gerenciar a chave da API
   - Interface para visualizar, editar e salvar a chave da API
   - Opções de segurança para ocultar/mostrar a chave
   - Armazenamento seguro da chave usando SharedPreferences

5. **Integração com a Interface Principal:**
   - Adição de botões na barra de ferramentas para acesso rápido às funcionalidades de IA
   - Integração com as telas de caixas e itens

**Próximos passos:**
1. Melhorar a precisão do reconhecimento de objetos com prompts mais específicos
2. Adicionar suporte para reconhecimento de múltiplos objetos em uma única imagem
3. Implementar histórico de reconhecimentos
4. Adicionar opção para reconhecimento offline (sem API)

### Implementação Anterior: Melhorias na Interface e Funcionalidades do Sistema

**Status:** Em andamento

**Descrição:** Implementação de melhorias na interface e funcionalidades do sistema, incluindo telas de configurações e logs.

**Alterações Realizadas:**

1. **Implementação de Dropdown para Categorias:**
   - Substituição do campo de texto livre por um dropdown com categorias predefinidas
   - Categorias predefinidas: "Ferramentas", "Itens Diversos", "Eletronicos", "Acessorios Musicais"
   - Implementado tanto no diálogo de criação quanto de edição de caixas
   - Melhoria na experiência do usuário e padronização das categorias

2. **Criação de Caixas Padrão:**
   - Implementação de funcionalidade para criar caixas padrão automaticamente
   - Caixas padrão são criadas apenas quando o aplicativo é iniciado pela primeira vez
   - Caixas criadas:
     - Ferramentas (Localização: Garagem)
     - Itens Diversos (Localização: Despensa)
     - Eletrônicos (Localização: Escritório)
     - Acessórios Musicais (Localização: Sala de Música)
   - Facilita o uso inicial do aplicativo para novos usuários

3. **Implementação da Tela de Configurações:**
   - Criação de tela completa de configurações do sistema
   - Funcionalidades implementadas:
     - Alteração de tema (claro/escuro)
     - Backup e restauração de dados
     - Gerenciamento de logs do sistema
     - Configuração de diretório de backup
     - Estatísticas do banco de dados
     - Limpeza de dados

4. **Implementação da Tela de Logs:**
   - Criação de tela para visualização e gerenciamento de logs do sistema
   - Funcionalidades implementadas:
     - Filtragem por nível de log (debug, info, warning, error)
     - Filtragem por categoria
     - Exportação de logs
     - Limpeza de logs
     - Visualização detalhada de cada log
     - Atualização automática

5. **Refatoração do Modelo Box:**
   - Remoção do campo `color` do modelo Box
   - Adição do campo `category` como obrigatório
   - Adição do campo `location` para melhor organização

6. **Melhorias na Interface de Usuário:**
   - Adição de espaçamento entre os campos nos formulários
   - Utilização de bordas nos dropdowns para melhor visualização
   - Padronização visual dos formulários
   - Integração das novas telas ao menu principal

**Próximos passos:**
1. Implementar a funcionalidade de movimentação de itens entre caixas
2. Adicionar suporte a QR codes e impressão de etiquetas
3. Melhorar a tela de detalhes da caixa
4. Implementar reconhecimento de objetos com IA
