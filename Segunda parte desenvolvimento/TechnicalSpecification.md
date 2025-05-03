# MagicBoxV2: Especificação Técnica

## Arquitetura

### Padrão BLoC
MagicBoxV2 adotará o padrão BLoC (Business Logic Component) para separar a lógica de negócios da interface do usuário:

```
lib/
  ├── blocs/         # Componentes de lógica de negócios
  ├── data/          # Fontes de dados e repositórios
  ├── models/        # Modelos de dados
  ├── screens/       # Telas da aplicação
  ├── services/      # Serviços (impressão, reconhecimento, etc.)
  ├── utils/         # Utilitários e helpers
  ├── widgets/       # Componentes reutilizáveis
  └── main.dart      # Ponto de entrada da aplicação
```

### Injeção de Dependências
Utilizaremos o pacote `get_it` para injeção de dependências, facilitando testes e manutenção:

```dart
final getIt = GetIt.instance;

void setupDependencies() {
  // Serviços
  getIt.registerSingleton<DatabaseService>(DatabaseService());
  getIt.registerSingleton<PreferencesService>(PreferencesService());
  getIt.registerSingleton<LabelPrintingService>(LabelPrintingService());
  getIt.registerSingleton<ObjectRecognitionService>(ObjectRecognitionService());
  
  // Repositórios
  getIt.registerSingleton<BoxRepository>(BoxRepository(getIt<DatabaseService>()));
  getIt.registerSingleton<LabelRepository>(LabelRepository(getIt<PreferencesService>()));
  
  // BLoCs
  getIt.registerFactory<BoxBloc>(() => BoxBloc(getIt<BoxRepository>()));
  getIt.registerFactory<LabelBloc>(() => LabelBloc(
    getIt<LabelRepository>(), 
    getIt<LabelPrintingService>()
  ));
}
```

## Sistema de Etiquetas Aprimorado

### Modelo de Dados

```dart
// Modelo de etiqueta aprimorado
class LabelModel {
  final String id;
  final String name;
  final double heightMm;
  final double widthMm;
  final int labelsPerSheet;
  final int columns;
  final int rows;
  final double topMarginMm;
  final double bottomMarginMm;
  final double leftMarginMm;
  final double rightMarginMm;
  final double spacingMm;
  final bool isCustom;
  final DateTime? createdAt;
  
  // Métodos para conversão entre unidades
  double get heightPt => heightMm * (72.0 / 25.4);
  double get widthPt => widthMm * (72.0 / 25.4);
  
  // Métodos para serialização/desserialização
  Map<String, dynamic> toJson();
  factory LabelModel.fromJson(Map<String, dynamic> json);
}
```

### Repositório de Etiquetas

```dart
class LabelRepository {
  final PreferencesService _preferencesService;
  
  LabelRepository(this._preferencesService);
  
  // Obter todos os modelos (predefinidos + personalizados)
  Future<List<LabelModel>> getAllModels();
  
  // Salvar modelo personalizado
  Future<void> saveCustomModel(LabelModel model);
  
  // Excluir modelo personalizado
  Future<void> deleteCustomModel(String id);
  
  // Obter/salvar último modelo utilizado
  Future<LabelModel?> getLastUsedModel();
  Future<void> saveLastUsedModel(String modelId);
}
```

### BLoC de Etiquetas

```dart
class LabelBloc extends Bloc<LabelEvent, LabelState> {
  final LabelRepository _repository;
  final LabelPrintingService _printingService;
  
  LabelBloc(this._repository, this._printingService);
  
  // Estados possíveis
  // - LabelInitial
  // - LabelLoading
  // - LabelLoaded(models, selectedModel, previewData)
  // - LabelError(message)
  
  // Eventos possíveis
  // - LoadLabels
  // - SelectLabel(modelId)
  // - AddCustomLabel(model)
  // - DeleteCustomLabel(modelId)
  // - GeneratePreview(boxes)
  // - PrintLabels(boxes, format)
  // - ExportSvg(boxes)
}
```

## Implementação do Sistema de Etiquetas

### Tela de Etiquetas Unificada

A nova tela de etiquetas terá:

1. **Seleção de Caixas** - Lista de caixas com checkbox para seleção
2. **Painel de Configuração** - Seleção de modelo e formato na mesma tela
3. **Preview em Tempo Real** - Atualizado automaticamente ao mudar configurações
4. **Botões de Ação** - Imprimir, Exportar SVG, Adicionar Modelo

```dart
class LabelsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<LabelBloc>()..add(LoadLabels()),
      child: Scaffold(
        appBar: AppBar(title: Text('Etiquetas')),
        body: BlocBuilder<LabelBloc, LabelState>(
          builder: (context, state) {
            if (state is LabelLoading) {
              return Center(child: CircularProgressIndicator());
            }
            
            if (state is LabelLoaded) {
              return Column(
                children: [
                  // Painel de configuração
                  LabelConfigPanel(
                    models: state.models,
                    selectedModel: state.selectedModel,
                    onModelSelected: (model) => context.read<LabelBloc>()
                      .add(SelectLabel(model.id)),
                    onAddCustomModel: () => _showAddModelDialog(context),
                  ),
                  
                  // Preview
                  Expanded(
                    child: LabelPreviewPanel(
                      previewData: state.previewData,
                      onGeneratePreview: () => context.read<LabelBloc>()
                        .add(GeneratePreview()),
                    ),
                  ),
                  
                  // Botões de ação
                  LabelActionButtons(
                    onPrint: () => _printLabels(context),
                    onExportSvg: () => _exportSvg(context),
                  ),
                ],
              );
            }
            
            return Center(child: Text('Erro ao carregar etiquetas'));
          },
        ),
      ),
    );
  }
}
```

### Componente de Seleção de Modelo

```dart
class LabelModelSelector extends StatelessWidget {
  final List<LabelModel> models;
  final LabelModel? selectedModel;
  final Function(LabelModel) onModelSelected;
  final VoidCallback onAddCustomModel;
  
  @override
  Widget build(BuildContext context) {
    // Agrupar modelos por número de colunas
    final groupedModels = _groupModelsByColumns(models);
    
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Modelo de Etiqueta', 
                  style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                  icon: Icon(Icons.add_circle),
                  tooltip: 'Adicionar modelo personalizado',
                  onPressed: onAddCustomModel,
                ),
              ],
            ),
          ),
          
          // Lista de modelos agrupados
          ...groupedModels.entries.map((entry) => ExpansionTile(
            title: Text('${entry.key} colunas'),
            children: entry.value.map((model) => RadioListTile<LabelModel>(
              title: Text(model.name),
              subtitle: Text('${model.widthMm.toStringAsFixed(1)} x '
                '${model.heightMm.toStringAsFixed(1)} mm - '
                '${model.labelsPerSheet} por folha'),
              value: model,
              groupValue: selectedModel,
              onChanged: (value) => onModelSelected(value!),
            )).toList(),
          )).toList(),
          
          // Seção de modelos personalizados
          if (models.any((m) => m.isCustom))
            ExpansionTile(
              title: Text('Modelos Personalizados'),
              children: models
                .where((m) => m.isCustom)
                .map((model) => RadioListTile<LabelModel>(
                  title: Text(model.name),
                  subtitle: Row(
                    children: [
                      Text('${model.widthMm.toStringAsFixed(1)} x '
                        '${model.heightMm.toStringAsFixed(1)} mm'),
                      Spacer(),
                      IconButton(
                        icon: Icon(Icons.delete_outline),
                        onPressed: () => _confirmDeleteModel(context, model),
                      ),
                    ],
                  ),
                  value: model,
                  groupValue: selectedModel,
                  onChanged: (value) => onModelSelected(value!),
                )).toList(),
            ),
        ],
      ),
    );
  }
}
```

### Preview em Tempo Real

```dart
class LabelPreviewPanel extends StatelessWidget {
  final LabelPreviewData previewData;
  final VoidCallback onRefresh;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Preview', 
                  style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                  icon: Icon(Icons.refresh),
                  tooltip: 'Atualizar preview',
                  onPressed: onRefresh,
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: previewData.pageWidth / previewData.pageHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Grade de etiquetas
                      ...List.generate(
                        previewData.totalLabels,
                        (index) {
                          final row = index ~/ previewData.columns;
                          final col = index % previewData.columns;
                          final isActive = index < previewData.activeLabels;
                          
                          return Positioned(
                            left: previewData.leftMargin + 
                              col * (previewData.labelWidth + previewData.horizontalSpacing),
                            top: previewData.topMargin + 
                              row * (previewData.labelHeight + previewData.verticalSpacing),
                            width: previewData.labelWidth,
                            height: previewData.labelHeight,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isActive ? Colors.red : Colors.grey,
                                  width: 1,
                                ),
                              ),
                              child: isActive
                                ? Center(child: Icon(Icons.check, color: Colors.red))
                                : null,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Etiquetas selecionadas: ${previewData.activeLabels} de ${previewData.totalLabels}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          
          // Botão para visualizar PDF completo
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              icon: Icon(Icons.preview),
              label: Text('Visualizar PDF Completo'),
              onPressed: () => _showFullPreview(context),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

## Serviço de Impressão de Etiquetas

O serviço de impressão será refatorado para:

1. Usar dimensões precisas em milímetros
2. Implementar QR codes reais em SVG
3. Suportar exportação para múltiplos formatos
4. Funcionar em todas as plataformas

```dart
class LabelPrintingService {
  // Gerar PDF para impressão
  Future<Uint8List> generateLabelsPdf({
    required List<Box> boxes,
    required Map<int, List<Item>> boxItems,
    required LabelModel model,
    required LabelFormat format,
    bool showBorders = false,
  });
  
  // Gerar SVG para uma etiqueta específica
  Future<String> generateLabelSvg({
    required Box box,
    required List<Item> items,
    required LabelModel model,
    required LabelFormat format,
  });
  
  // Exportar múltiplas etiquetas como SVG
  Future<void> exportLabelsAsSvg({
    required List<Box> boxes,
    required Map<int, List<Item>> boxItems,
    required LabelModel model,
    required LabelFormat format,
    required String? outputDir,
  });
  
  // Gerar QR code em SVG
  String generateQrCodeSvg(String data, {
    required double size,
    required int errorCorrectionLevel,
  });
}
```

## Temas

### Tema Escuro Neon Azul

```dart
ThemeData darkNeonTheme() {
  return ThemeData.dark(useMaterial3: true).copyWith(
    colorScheme: ColorScheme.dark(
      primary: Color(0xFF00B4FF),      // Azul neon
      secondary: Color(0xFF9D00FF),    // Roxo neon
      surface: Color(0xFF121212),      // Fundo escuro
      background: Color(0xFF121212),   // Fundo escuro
      error: Color(0xFFFF5252),        // Vermelho erro
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF1A1A1A),
      foregroundColor: Color(0xFF00B4FF),
      elevation: 0,
    ),
    cardTheme: CardTheme(
      color: Color(0xFF1E1E1E),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF00B4FF),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      titleMedium: TextStyle(
        color: Color(0xFF00B4FF),
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: Colors.white,
      ),
      bodyMedium: TextStyle(
        color: Colors.white70,
      ),
    ),
    iconTheme: IconThemeData(
      color: Color(0xFF00B4FF),
    ),
    dividerTheme: DividerThemeData(
      color: Color(0xFF333333),
    ),
  );
}
```

### Tema Claro Clean

```dart
ThemeData lightCleanTheme() {
  return ThemeData.light(useMaterial3: true).copyWith(
    colorScheme: ColorScheme.light(
      primary: Color(0xFF1976D2),      // Azul
      secondary: Color(0xFF607D8B),    // Cinza azulado
      surface: Colors.white,
      background: Color(0xFFF5F5F5),   // Cinza muito claro
      error: Color(0xFFD32F2F),        // Vermelho erro
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF1976D2),
      elevation: 0,
      shadowColor: Colors.transparent,
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(
        color: Color(0xFF212121),
        fontWeight: FontWeight.bold,
      ),
      titleMedium: TextStyle(
        color: Color(0xFF1976D2),
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: Color(0xFF212121),
      ),
      bodyMedium: TextStyle(
        color: Color(0xFF757575),
      ),
    ),
    iconTheme: IconThemeData(
      color: Color(0xFF1976D2),
    ),
    dividerTheme: DividerThemeData(
      color: Color(0xFFE0E0E0),
    ),
  );
}
```

## Testes Automatizados

```dart
// Teste de unidade para o serviço de impressão
void main() {
  group('LabelPrintingService', () {
    late LabelPrintingService service;
    
    setUp(() {
      service = LabelPrintingService();
    });
    
    test('generateLabelsPdf should create PDF with correct dimensions', () async {
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
      
      // Verificar dimensões do PDF usando pdf package
      // (implementação depende da biblioteca específica)
    });
    
    test('generateQrCodeSvg should create valid SVG', () {
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
  });
}
```

## Plano de Implementação

1. **Fase 1: Refatoração da Arquitetura**
   - Implementar estrutura BLoC
   - Configurar injeção de dependências
   - Migrar modelos de dados

2. **Fase 2: Implementação do Sistema de Etiquetas**
   - Desenvolver serviço de impressão aprimorado
   - Criar componentes de UI para seleção de modelos
   - Implementar preview em tempo real

3. **Fase 3: Temas e UI/UX**
   - Implementar tema escuro neon azul
   - Implementar tema claro clean
   - Otimizar responsividade

4. **Fase 4: Testes e Otimização**
   - Escrever testes automatizados
   - Otimizar performance
   - Corrigir bugs e problemas de UI

5. **Fase 5: Empacotamento e Distribuição**
   - Gerar APK para Android
   - Configurar build para web
   - Preparar para distribuição
