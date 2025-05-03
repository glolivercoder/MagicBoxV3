# MagicBoxV2: Sistema de Gestão de Caixas e Etiquetas

## Visão Geral

MagicBoxV2 é uma aplicação Flutter multiplataforma para gestão de caixas, itens e impressão de etiquetas. Esta versão foi completamente reestruturada para oferecer uma experiência mais fluida, código mais limpo e funcionalidades aprimoradas.

## Principais Funcionalidades

### 1. Gestão de Caixas e Itens
- Cadastro de caixas com ID, nome, categoria e descrição
- Adição de múltiplos itens por caixa com detalhes completos
- Busca avançada por texto, categoria ou ID
- Visualização em lista ou grade com opções de ordenação

### 2. Reconhecimento de Objetos
- Captura de imagem via câmera ou galeria
- Reconhecimento automático usando IA Gemini
- Sugestão inteligente de categorias e descrições
- Salvamento automático das imagens capturadas

### 3. Sistema de Etiquetas Aprimorado
- Interface unificada para seleção de modelos Pimaco
- Preview em tempo real das etiquetas na mesma tela
- Adição de modelos personalizados com armazenamento
- Exportação em múltiplos formatos (PDF Vetorial, EPS)
- QR codes vetoriais de alta qualidade
- Opção de códigos de barras lineares para otimizar espaço

### 4. Narração de Conteúdo por Voz
- Botão de player no header da tela de detalhes da caixa
- Narração em português do Brasil dos itens contidos na caixa
- Modo automático que narra o conteúdo quando a caixa é reconhecida por ID ou QR code
- Configurações de velocidade, tom e seleção de vozes
- Funcionalidade acessível em todas as plataformas (Android, iOS, Web)

### 4.1 Narração Automática (TTS)

- **Funcionalidade**: 
  - Narração automática do conteúdo das caixas quando reconhecidas por ID ou QR code
  - Narração automática da descrição de objetos quando reconhecidos pela Gemini
- **Configuração**: Opções separadas nas configurações para ativar/desativar cada tipo de narração automática
- **Personalização**: Ajustes de velocidade, tom e seleção de voz
- **Acessibilidade**: Facilita o uso do aplicativo para pessoas com deficiência visual ou em situações onde o usuário não pode olhar para a tela

### 5. Temas e Interface
- Tema escuro neon azul e tema claro clean
- Design responsivo para web, desktop e mobile
- Navegação intuitiva com bottom navigation
- Componentes Material Design 3 otimizados

## Melhorias Técnicas

### Arquitetura
- Padrão BLoC para gerenciamento de estado
- Injeção de dependências com get_it
- Separação clara entre UI, lógica de negócios e dados
- Testes automatizados para componentes críticos

### Performance
- Carregamento lazy de imagens e dados
- Otimização de renderização para listas grandes
- Redução de rebuilds desnecessários
- Cache inteligente de dados frequentes

### Código
- Nomenclatura consistente (camelCase para variáveis, PascalCase para classes)
- Remoção de código redundante e não utilizado
- Comentários significativos apenas para lógica complexa
- Formatação automática com lint rules padronizadas

## Detalhes de Implementação

### Sistema de Etiquetas Aprimorado

O sistema de etiquetas foi completamente redesenhado para oferecer:

1. **Seleção Integrada de Modelos**:
   - Lista de modelos Pimaco diretamente na tela principal
   - Informações detalhadas de dimensões e quantidade por folha
   - Agrupamento por tipo (3 colunas, 2 colunas, etc.)

2. **Preview Aprimorado**:
   - Visualização em tempo real ao selecionar modelo
   - Etiquetas utilizadas com bordas vermelhas destacadas
   - Etiquetas não utilizadas com bordas cinza
   - Visualização das margens do papel (área de impressão)
   - Zoom para verificar detalhes

3. **Modelos Personalizados**:
   - Interface para criar e salvar novos modelos
   - Botão "+" para adicionar rapidamente
   - Persistência de modelos personalizados

4. **Opções de Códigos de Barras**:
   - **QR Codes Vetoriais**:
     - Alta capacidade de armazenamento
     - Ideal para informações detalhadas
     - Leitura por smartphones
   
   - **Códigos de Barras Lineares**:
     - Code 128 para IDs alfanuméricos
     - Code 39 para maior compatibilidade
     - EAN-13 para integração com sistemas comerciais
     - Otimização de espaço nas etiquetas pequenas
     - Leitura por scanners convencionais

5. **Exportação Vetorial de Alta Qualidade**:
   - **PDF Vetorial Editável**:
     - Códigos como paths vetoriais puros
     - Mesma qualidade visual do PDF impresso
     - Totalmente editável no Inkscape
     - Compatível com todas as plataformas
   
   - **EPS (Alternativa)**:
     - Formato vetorial nativo para design gráfico
     - Excelente qualidade para impressão profissional
     - Suporte completo no Inkscape

### QR Codes e Códigos de Barras Vetoriais

Implementação de códigos como verdadeiros elementos vetoriais:

1. **Geração como Paths SVG**:
   - Cada módulo ou barra como elemento vetorial puro
   - Padrões de localização (finder patterns) otimizados para QR codes
   - Escalabilidade infinita sem perda de qualidade

2. **Integração com PDF Editável**:
   - PDF configurado para fácil edição no Inkscape
   - Metadados otimizados para software de design
   - Estrutura de camadas para facilitar edição

3. **Vantagens sobre SVG tradicional**:
   - Qualidade superior e consistente
   - Melhor legibilidade por scanners
   - Aparência idêntica à versão impressa
   
4. **Otimização de Espaço com Códigos Lineares**:
   - Redução de até 70% no espaço vertical utilizado
   - Maior área para informações textuais
   - Ideal para etiquetas de tamanho reduzido

### Reconhecimento de Objetos

O sistema de reconhecimento foi aprimorado para:

1. **Integração Gemini Otimizada**:
   - Processamento mais rápido e preciso
   - Menor consumo de tokens da API
   - Respostas mais estruturadas

2. **Armazenamento Permanente de Imagens**:
   - Todas as fotos capturadas são armazenadas permanentemente no aplicativo
   - Organização por data, categoria e caixa associada
   - Vinculação automática ao item cadastrado
   - Acesso rápido ao histórico de imagens por objeto
   - Backup e sincronização das imagens entre dispositivos

3. **Narração Automática de Conteúdo**:
   - Ativação automática ao reconhecer caixas por ID ou QR code
   - Descrição falada dos itens contidos na caixa
   - Configuração de ativação/desativação nas preferências
   - Ideal para conferência de inventário sem uso das mãos

4. **Gerenciamento de Mídia Integrado**:
   - Visualização de todas as imagens associadas a uma caixa
   - Opções para editar, recortar e melhorar imagens
   - Exportação de imagens em alta resolução
   - Compartilhamento direto por WhatsApp, email ou outras plataformas

5. **Interface Simplificada**:
   - Fluxo de captura mais intuitivo
   - Feedback visual durante processamento
   - Sugestões inteligentes com opção de edição
   - Prévia da imagem antes do salvamento

## Temas

### Tema Escuro Neon Azul
- Fundo escuro (#121212)
- Acentos em azul neon (#00B4FF)
- Elementos de destaque em roxo neon (#9D00FF)
- Tipografia clara com alto contraste

### Tema Claro Clean
- Fundo branco (#FFFFFF)
- Acentos em azul (#1976D2)
- Elementos secundários em cinza azulado (#607D8B)
- Tipografia escura com ótima legibilidade

## Roadmap Futuro

1. **Sincronização em Nuvem**:
   - Backup automático de dados
   - Sincronização entre dispositivos
   - Compartilhamento de caixas e etiquetas

2. **Exportação Avançada**:
   - Formatos adicionais (CSV, JSON)
   - Integração com sistemas externos
   - Opções de personalização expandidas

3. **Reconhecimento Aprimorado**:
   - Modelos de IA locais para uso offline
   - Reconhecimento de múltiplos objetos
   - Treinamento personalizado para categorias específicas

4. **Interface Expandida**:
   - Mais opções de visualização
   - Dashboard com estatísticas
   - Modo de apresentação para inventários
