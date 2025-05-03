# MagicBoxV2: Plano de Testes

## Visão Geral

Este documento descreve o plano de testes para garantir que o MagicBoxV2 atenda aos requisitos de qualidade e funcionalidade antes do lançamento. O plano abrange testes unitários, de integração, de interface e de aceitação do usuário.

## Estratégia de Testes

### Abordagem

1. **Testes Unitários**: Validar componentes individuais isoladamente
2. **Testes de Integração**: Verificar a interação entre componentes
3. **Testes de Interface**: Avaliar a experiência do usuário e responsividade
4. **Testes de Aceitação**: Validar cenários completos de uso

### Ferramentas

- **Flutter Test**: Para testes unitários e de widget
- **Integration_test**: Para testes de integração em Flutter
- **Mockito**: Para mock de dependências
- **Flutter Driver**: Para testes de UI automatizados
- **Firebase Test Lab**: Para testes em múltiplos dispositivos

## Testes Unitários

### Serviços

#### LabelPrintingService

```dart
void main() {
  group('LabelPrintingService', () {
    late LabelPrintingService service;
    
    setUp(() {
      service = LabelPrintingService();
    });
    
    test('generateLabelsPdf deve criar PDF com dimensões corretas', () async {
      // Arrange
      final model = LabelModel(
        id: 'test',
        name: 'Test Model',
        heightMm: 25.4,
        widthMm: 66.7,
        labelsPerSheet: 30,
        columns: 3,
        rows: 10,
        topMarginMm: 12.7,
        bottomMarginMm: 12.7,
        leftMarginMm: 4.8,
        rightMarginMm: 4.8,
        spacingMm: 2.0,
        isCustom: false,
      );
      
      final boxes = [
        Box(id: 1, name: 'Test Box', category: 'Test'),
      ];
      
      final boxItems = {
        1: [Item(id: 1, name: 'Test Item', boxId: 1)],
      };
      
      // Act
      final pdfBytes = await service.generateLabelsPdf(
        boxes: boxes,
        boxItems: boxItems,
        model: model,
        format: LabelFormat.nameWithBarcodeAndId,
      );
      
      // Assert
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(0));
    });
    
    test('generateQrCodeSvg deve criar SVG válido', () {
      // Arrange
      final data = 'BOX-001';
      final size = 100.0;
      
      // Act
      final svg = service.generateQrCodeSvg(
        data, 
        size: size,
        errorCorrectionLevel: 1,
      );
      
      // Assert
      expect(svg, contains('<svg'));
      expect(svg, contains('</svg>'));
      expect(svg, contains(data));
    });
    
    test('calculateFontSize deve retornar tamanho proporcional', () {
      // Arrange
      final smallLabelHeight = 12.7 * (72.0 / 25.4); // 12.7mm em pontos
      final largeLabelHeight = 50.8 * (72.0 / 25.4); // 50.8mm em pontos
      final baseFontSize = 12.0;
      
      // Act
      final smallFontSize = service.calculateFontSize(smallLabelHeight, baseFontSize);
      final largeFontSize = service.calculateFontSize(largeLabelHeight, baseFontSize);
      
      // Assert
      expect(smallFontSize, lessThan(baseFontSize));
      expect(largeFontSize, greaterThan(baseFontSize));
      expect(smallFontSize, greaterThanOrEqualTo(6.0)); // Tamanho mínimo
    });
  });
}
```

#### ObjectRecognitionService

```dart
void main() {
  group('ObjectRecognitionService', () {
    late ObjectRecognitionService service;
    late MockGeminiApiClient mockClient;
    
    setUp(() {
      mockClient = MockGeminiApiClient();
      service = ObjectRecognitionService(apiClient: mockClient);
    });
    
    test('recognizeObject deve retornar resultado correto quando API responde', () async {
      // Arrange
      final testImage = Uint8List(100); // Mock de imagem
      final expectedResponse = RecognitionResult(
        name: 'Martelo',
        category: 'Ferramentas',
        description: 'Martelo de carpinteiro',
      );
      
      when(mockClient.analyzeImage(any, any))
        .thenAnswer((_) async => expectedResponse);
      
      // Act
      final result = await service.recognizeObject(testImage);
      
      // Assert
      expect(result, equals(expectedResponse));
      verify(mockClient.analyzeImage(any, any)).called(1);
    });
    
    test('saveImageToDevice deve salvar imagem e retornar caminho', () async {
      // Arrange
      final testImage = Uint8List(100); // Mock de imagem
      final expectedPath = '/storage/emulated/0/Pictures/BoxMagic/item_12345.jpg';
      
      when(mockClient.saveImage(any, any))
        .thenAnswer((_) async => expectedPath);
      
      // Act
      final path = await service.saveImageToDevice(testImage, 'item_12345');
      
      // Assert
      expect(path, equals(expectedPath));
      verify(mockClient.saveImage(any, any)).called(1);
    });
  });
}
```

### Repositórios

#### BoxRepository

```dart
void main() {
  group('BoxRepository', () {
    late BoxRepository repository;
    late MockDatabaseService mockDb;
    
    setUp(() {
      mockDb = MockDatabaseService();
      repository = BoxRepository(mockDb);
    });
    
    test('getAllBoxes deve retornar lista de caixas', () async {
      // Arrange
      final expectedBoxes = [
        Box(id: 1, name: 'Box 1', category: 'Category 1'),
        Box(id: 2, name: 'Box 2', category: 'Category 2'),
      ];
      
      when(mockDb.query('boxes'))
        .thenAnswer((_) async => [
          {'id': 1, 'name': 'Box 1', 'category': 'Category 1'},
          {'id': 2, 'name': 'Box 2', 'category': 'Category 2'},
        ]);
      
      // Act
      final boxes = await repository.getAllBoxes();
      
      // Assert
      expect(boxes.length, equals(2));
      expect(boxes[0].id, equals(1));
      expect(boxes[1].name, equals('Box 2'));
    });
    
    test('getBoxItems deve retornar itens da caixa', () async {
      // Arrange
      final boxId = 1;
      final expectedItems = [
        Item(id: 1, name: 'Item 1', boxId: boxId),
        Item(id: 2, name: 'Item 2', boxId: boxId),
      ];
      
      when(mockDb.query('items', where: 'boxId = ?', whereArgs: [boxId]))
        .thenAnswer((_) async => [
          {'id': 1, 'name': 'Item 1', 'boxId': boxId},
          {'id': 2, 'name': 'Item 2', 'boxId': boxId},
        ]);
      
      // Act
      final items = await repository.getBoxItems(boxId);
      
      // Assert
      expect(items.length, equals(2));
      expect(items[0].boxId, equals(boxId));
      expect(items[1].name, equals('Item 2'));
    });
  });
}
```

#### LabelRepository

```dart
void main() {
  group('LabelRepository', () {
    late LabelRepository repository;
    late MockPreferencesService mockPrefs;
    
    setUp(() {
      mockPrefs = MockPreferencesService();
      repository = LabelRepository(mockPrefs);
    });
    
    test('getAllModels deve retornar modelos predefinidos e personalizados', () async {
      // Arrange
      final customModels = [
        {'id': 'custom1', 'name': 'Custom 1', 'heightMm': 25.4, 'widthMm': 50.8, 'isCustom': true},
        {'id': 'custom2', 'name': 'Custom 2', 'heightMm': 38.1, 'widthMm': 76.2, 'isCustom': true},
      ];
      
      when(mockPrefs.getCustomLabelModels())
        .thenAnswer((_) async => customModels);
      
      // Act
      final models = await repository.getAllModels();
      
      // Assert
      // Verificar se contém modelos predefinidos + personalizados
      expect(models.length, greaterThan(customModels.length));
      expect(models.where((m) => m.isCustom).length, equals(customModels.length));
    });
    
    test('saveCustomModel deve persistir modelo personalizado', () async {
      // Arrange
      final model = LabelModel(
        id: 'custom1',
        name: 'Custom Model',
        heightMm: 25.4,
        widthMm: 50.8,
        labelsPerSheet: 10,
        columns: 2,
        rows: 5,
        isCustom: true,
      );
      
      // Act
      await repository.saveCustomModel(model);
      
      // Assert
      verify(mockPrefs.saveCustomLabelModel(any)).called(1);
    });
  });
}
```

## Testes de Interface

### Tela de Etiquetas

```dart
void main() {
  testWidgets('LabelsScreen exibe modelos e permite seleção', (WidgetTester tester) async {
    // Arrange
    final mockLabelBloc = MockLabelBloc();
    final models = [
      LabelModel(id: 'model1', name: 'Model 1', heightMm: 25.4, widthMm: 50.8, labelsPerSheet: 10),
      LabelModel(id: 'model2', name: 'Model 2', heightMm: 38.1, widthMm: 76.2, labelsPerSheet: 6),
    ];
    
    when(mockLabelBloc.state).thenReturn(LabelLoaded(
      models: models,
      selectedModel: models[0],
      previewData: LabelPreviewData(
        pageWidth: 210,
        pageHeight: 297,
        labelWidth: 50,
        labelHeight: 25,
        columns: 2,
        rows: 5,
        totalLabels: 10,
        activeLabels: 3,
      ),
    ));
    
    // Act
    await tester.pumpWidget(MaterialApp(
      home: BlocProvider<LabelBloc>.value(
        value: mockLabelBloc,
        child: LabelsScreen(),
      ),
    ));
    
    // Assert
    expect(find.text('Model 1'), findsOneWidget);
    expect(find.text('Model 2'), findsOneWidget);
    expect(find.text('Etiquetas selecionadas: 3 de 10'), findsOneWidget);
    
    // Interação
    await tester.tap(find.text('Model 2'));
    await tester.pump();
    
    verify(mockLabelBloc.add(SelectLabel('model2'))).called(1);
  });
  
  testWidgets('LabelsScreen exibe preview e permite visualização completa', (WidgetTester tester) async {
    // Arrange
    final mockLabelBloc = MockLabelBloc();
    
    when(mockLabelBloc.state).thenReturn(LabelLoaded(
      models: [],
      selectedModel: null,
      previewData: LabelPreviewData(
        pageWidth: 210,
        pageHeight: 297,
        labelWidth: 50,
        labelHeight: 25,
        columns: 2,
        rows: 5,
        totalLabels: 10,
        activeLabels: 3,
      ),
    ));
    
    // Act
    await tester.pumpWidget(MaterialApp(
      home: BlocProvider<LabelBloc>.value(
        value: mockLabelBloc,
        child: LabelsScreen(),
      ),
    ));
    
    // Assert
    expect(find.text('Preview'), findsOneWidget);
    expect(find.text('Visualizar PDF Completo'), findsOneWidget);
    
    // Interação
    await tester.tap(find.text('Visualizar PDF Completo'));
    await tester.pumpAndSettle();
    
    // Verificar se navegou para tela de preview
    expect(find.byType(PdfPreviewScreen), findsOneWidget);
  });
}
```

### Componente de Seleção de Modelo

```dart
void main() {
  testWidgets('LabelModelSelector agrupa modelos corretamente', (WidgetTester tester) async {
    // Arrange
    final models = [
      LabelModel(id: 'model1', name: 'Model 1', columns: 2, heightMm: 25.4, widthMm: 50.8, labelsPerSheet: 10),
      LabelModel(id: 'model2', name: 'Model 2', columns: 3, heightMm: 38.1, widthMm: 76.2, labelsPerSheet: 6),
      LabelModel(id: 'model3', name: 'Model 3', columns: 2, heightMm: 25.4, widthMm: 50.8, labelsPerSheet: 10),
      LabelModel(id: 'custom1', name: 'Custom 1', columns: 1, heightMm: 25.4, widthMm: 50.8, labelsPerSheet: 10, isCustom: true),
    ];
    
    // Act
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LabelModelSelector(
          models: models,
          selectedModel: models[0],
          onModelSelected: (_) {},
          onAddCustomModel: () {},
        ),
      ),
    ));
    
    // Assert
    expect(find.text('2 colunas'), findsOneWidget);
    expect(find.text('3 colunas'), findsOneWidget);
    expect(find.text('Modelos Personalizados'), findsOneWidget);
    
    // Expandir grupo de 2 colunas
    await tester.tap(find.text('2 colunas'));
    await tester.pump();
    
    expect(find.text('Model 1'), findsOneWidget);
    expect(find.text('Model 3'), findsOneWidget);
  });
  
  testWidgets('LabelModelSelector permite excluir modelo personalizado', (WidgetTester tester) async {
    // Arrange
    final models = [
      LabelModel(id: 'custom1', name: 'Custom 1', columns: 1, heightMm: 25.4, widthMm: 50.8, labelsPerSheet: 10, isCustom: true),
    ];
    bool deleteConfirmationShown = false;
    
    // Act
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LabelModelSelector(
          models: models,
          selectedModel: null,
          onModelSelected: (_) {},
          onAddCustomModel: () {},
          onDeleteCustomModel: (_) {
            deleteConfirmationShown = true;
          },
        ),
      ),
    ));
    
    // Expandir grupo de modelos personalizados
    await tester.tap(find.text('Modelos Personalizados'));
    await tester.pump();
    
    // Clicar no botão de exclusão
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pump();
    
    // Assert
    expect(deleteConfirmationShown, isTrue);
  });
}
```

## Testes de Integração

### Fluxo de Impressão de Etiquetas

```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('Fluxo completo de impressão de etiquetas', (WidgetTester tester) async {
    // Iniciar aplicativo
    app.main();
    await tester.pumpAndSettle();
    
    // Navegar para tela de caixas
    await tester.tap(find.byIcon(Icons.inventory));
    await tester.pumpAndSettle();
    
    // Selecionar algumas caixas
    await tester.tap(find.text('Caixa 001').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Caixa 002').first);
    await tester.pumpAndSettle();
    
    // Navegar para tela de etiquetas
    await tester.tap(find.byIcon(Icons.label));
    await tester.pumpAndSettle();
    
    // Verificar se as caixas selecionadas aparecem
    expect(find.text('Caixa 001'), findsOneWidget);
    expect(find.text('Caixa 002'), findsOneWidget);
    
    // Selecionar modelo Pimaco
    await tester.tap(find.text('2 colunas (A4)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pimaco 6180 - 10 por folha (10,16 x 5,08 cm)'));
    await tester.pumpAndSettle();
    
    // Verificar se o preview foi atualizado
    expect(find.text('Etiquetas selecionadas: 2 de 10'), findsOneWidget);
    
    // Visualizar PDF completo
    await tester.tap(find.text('Visualizar PDF Completo'));
    await tester.pumpAndSettle();
    
    // Verificar se a tela de preview do PDF foi aberta
    expect(find.text('Preview - Pimaco 6180'), findsOneWidget);
    
    // Voltar para tela de etiquetas
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    
    // Exportar SVG
    await tester.tap(find.text('Exportar SVG'));
    await tester.pumpAndSettle();
    
    // Verificar se o diálogo de exportação foi mostrado
    expect(find.text('Exportar Etiquetas SVG'), findsOneWidget);
  });
}
```

### Fluxo de Reconhecimento de Objetos

```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('Fluxo completo de reconhecimento de objetos', (WidgetTester tester) async {
    // Iniciar aplicativo
    app.main();
    await tester.pumpAndSettle();
    
    // Navegar para tela de reconhecimento
    await tester.tap(find.byIcon(Icons.camera_alt));
    await tester.pumpAndSettle();
    
    // Verificar opções de captura
    expect(find.text('Capturar'), findsOneWidget);
    expect(find.text('Galeria'), findsOneWidget);
    
    // Selecionar galeria (não podemos testar câmera em testes automatizados)
    await tester.tap(find.text('Galeria'));
    await tester.pumpAndSettle();
    
    // Simular seleção de imagem
    // Nota: Isso requer mock do ImagePicker, que não é trivial em testes de integração
    
    // Verificar tela de processamento
    expect(find.text('Processando...'), findsOneWidget);
    await tester.pumpAndSettle(Duration(seconds: 5)); // Aguardar processamento
    
    // Verificar resultados do reconhecimento
    expect(find.text('Objeto Reconhecido'), findsOneWidget);
    
    // Confirmar e salvar
    await tester.tap(find.text('Confirmar e Salvar'));
    await tester.pumpAndSettle();
    
    // Verificar se voltou para tela principal
    expect(find.byIcon(Icons.inventory), findsOneWidget);
  });
}
```

## Testes de Aceitação

### Cenários de Teste

1. **Impressão de Etiquetas**
   - Selecionar múltiplas caixas
   - Escolher modelo Pimaco
   - Visualizar preview
   - Gerar PDF
   - Imprimir ou exportar

2. **Criação de Modelo Personalizado**
   - Acessar tela de etiquetas
   - Adicionar novo modelo
   - Configurar dimensões
   - Salvar e selecionar
   - Verificar persistência após reiniciar app

3. **Reconhecimento de Objetos**
   - Capturar imagem
   - Verificar reconhecimento
   - Editar resultados
   - Salvar em uma caixa
   - Verificar imagem salva

4. **Alternância de Temas**
   - Alternar entre tema claro e escuro
   - Verificar persistência da preferência
   - Verificar elementos visuais em ambos os temas

### Critérios de Aceitação

1. **Funcionalidade**
   - Todas as funcionalidades principais funcionam conforme esperado
   - Não há erros críticos ou crashes
   - Dados são persistidos corretamente

2. **Performance**
   - Tempo de carregamento inicial < 3 segundos
   - Resposta a interações < 200ms
   - Geração de PDF < 5 segundos para 50 etiquetas

3. **Usabilidade**
   - Usuários conseguem completar tarefas sem ajuda
   - Interface intuitiva e responsiva
   - Feedback claro para todas as ações

4. **Compatibilidade**
   - Funciona em Android 8.0+
   - Funciona em iOS 12.0+
   - Funciona em navegadores modernos (Chrome, Firefox, Safari)

## Matriz de Testes

| Funcionalidade | Unitário | Integração | Interface | Aceitação |
|----------------|----------|------------|-----------|-----------|
| Gestão de Caixas | ✓ | ✓ | ✓ | ✓ |
| Gestão de Itens | ✓ | ✓ | ✓ | ✓ |
| Impressão de Etiquetas | ✓ | ✓ | ✓ | ✓ |
| Exportação SVG | ✓ | ✓ | ✓ | ✓ |
| Reconhecimento de Objetos | ✓ | ✓ | ✓ | ✓ |
| Modelos Personalizados | ✓ | ✓ | ✓ | ✓ |
| Temas | ✓ | - | ✓ | ✓ |
| Responsividade | - | - | ✓ | ✓ |

## Relatório de Testes

Após a execução dos testes, será gerado um relatório contendo:

1. **Resumo Executivo**
   - Taxa de aprovação/falha
   - Cobertura de código
   - Problemas críticos encontrados

2. **Detalhes por Categoria**
   - Resultados de testes unitários
   - Resultados de testes de integração
   - Resultados de testes de interface
   - Resultados de testes de aceitação

3. **Problemas Encontrados**
   - Descrição do problema
   - Severidade (Crítica, Alta, Média, Baixa)
   - Passos para reproduzir
   - Capturas de tela/logs

4. **Recomendações**
   - Correções necessárias
   - Melhorias sugeridas
   - Próximos passos

## Automação de Testes

Os testes serão automatizados usando:

1. **CI/CD Pipeline**
   - Execução automática de testes unitários e de widget em cada commit
   - Execução de testes de integração em PRs para branches principais
   - Geração de relatórios de cobertura

2. **Testes Noturnos**
   - Execução completa da suíte de testes
   - Testes em múltiplos dispositivos via Firebase Test Lab
   - Notificação da equipe em caso de falhas

3. **Testes de Regressão**
   - Execução antes de cada release
   - Verificação de funcionalidades críticas
   - Comparação com resultados anteriores
