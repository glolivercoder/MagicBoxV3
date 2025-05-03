# Implementação de Texto para Voz no MagicBoxV2

## Biblioteca Recomendada

Para a funcionalidade de texto para voz (TTS) em português do Brasil, a biblioteca recomendada é a **flutter_tts**, que oferece suporte completo para múltiplas plataformas, incluindo Android, iOS e Web.

```yaml
dependencies:
  flutter_tts: ^4.2.2
```

## Funcionalidades Principais

1. **Suporte a Português do Brasil**
   - Utiliza vozes nativas do sistema Android
   - Suporte completo ao idioma pt-BR
   - Configurações de velocidade, tom e volume

2. **Integração com Interface**
   - Botão de player no header da tela de detalhes da caixa
   - Indicador visual durante a narração
   - Opções para pausar e parar a narração

3. **Personalização**
   - Seleção de vozes disponíveis
   - Ajuste de velocidade de fala
   - Configuração de tom de voz

## Implementação Técnica

### 1. Serviço de Texto para Voz com Modo Automático

```dart
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TextToSpeechService {
  static const String AUTO_TTS_KEY = 'auto_tts_enabled';
  static const String AUTO_TTS_OBJECT_KEY = 'auto_tts_object_enabled';
  
  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlaying = false;
  bool _autoTtsEnabled = false;
  bool _autoTtsObjectEnabled = false;
  
  Future<void> initialize() async {
    // Carregar configurações de TTS automático
    final prefs = await SharedPreferences.getInstance();
    _autoTtsEnabled = prefs.getBool(AUTO_TTS_KEY) ?? false;
    _autoTtsObjectEnabled = prefs.getBool(AUTO_TTS_OBJECT_KEY) ?? false;
    
    // Configurar idioma para português do Brasil
    await _flutterTts.setLanguage("pt-BR");
    
    // Configurar taxa de fala (0.5 a 2.0, padrão 1.0)
    await _flutterTts.setSpeechRate(0.9);
    
    // Configurar volume (0.0 a 1.0)
    await _flutterTts.setVolume(1.0);
    
    // Configurar tom (0.5 a 2.0)
    await _flutterTts.setPitch(1.0);
    
    // Configurar callbacks
    _flutterTts.setStartHandler(() {
      _isPlaying = true;
    });
    
    _flutterTts.setCompletionHandler(() {
      _isPlaying = false;
    });
    
    _flutterTts.setErrorHandler((error) {
      _isPlaying = false;
    });
  }
  
  // Verificar vozes disponíveis em português
  Future<List<String>> getPortugueseVoices() async {
    final voices = await _flutterTts.getVoices;
    final portugueseVoices = voices
        .where((voice) => 
            voice.toString().contains('pt-BR') || 
            voice.toString().contains('pt_BR'))
        .map((voice) => voice.toString())
        .toList();
    
    return portugueseVoices;
  }
  
  // Definir voz específica
  Future<void> setVoice(String voice) async {
    await _flutterTts.setVoice({"name": voice});
  }
  
  // Falar texto
  Future<void> speak(String text) async {
    if (_isPlaying) {
      await stop();
    }
    
    await _flutterTts.speak(text);
  }
  
  // Pausar narração
  Future<void> pause() async {
    if (_isPlaying) {
      await _flutterTts.pause();
      _isPlaying = false;
    }
  }
  
  // Parar narração
  Future<void> stop() async {
    await _flutterTts.stop();
    _isPlaying = false;
  }
  
  // Verificar se está reproduzindo
  bool get isPlaying => _isPlaying;
  
  // Verificar se o modo automático para caixas está ativado
  bool get isAutoTtsEnabled => _autoTtsEnabled;
  
  // Verificar se o modo automático para objetos reconhecidos está ativado
  bool get isAutoTtsObjectEnabled => _autoTtsObjectEnabled;
  
  // Ativar/desativar modo automático para caixas
  Future<void> setAutoTtsEnabled(bool enabled) async {
    _autoTtsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AUTO_TTS_KEY, enabled);
  }
  
  // Ativar/desativar modo automático para objetos reconhecidos
  Future<void> setAutoTtsObjectEnabled(bool enabled) async {
    _autoTtsObjectEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AUTO_TTS_OBJECT_KEY, enabled);
  }
  
  // Liberar recursos
  Future<void> dispose() async {
    await _flutterTts.stop();
  }
  
  // Narrar lista de itens de uma caixa
  Future<void> speakBoxItems(String boxName, List<String> itemNames) async {
    final introduction = "Caixa $boxName contém os seguintes itens:";
    final itemsList = itemNames.join(", ");
    final fullText = "$introduction $itemsList";
    
    await speak(fullText);
  }
  
  // Narrar automaticamente o conteúdo da caixa se o modo automático estiver ativado
  Future<bool> autoSpeakBoxItems(String boxName, List<String> itemNames) async {
    if (_autoTtsEnabled) {
      await speakBoxItems(boxName, itemNames);
      return true;
    }
    return false;
  }
  
  // Narrar automaticamente a descrição de um objeto reconhecido pela Gemini
  Future<bool> autoSpeakObjectDescription(String objectName, String description) async {
    if (_autoTtsObjectEnabled) {
      final text = "Objeto reconhecido: $objectName. $description";
      await speak(text);
      return true;
    }
    return false;
  }
}
```

### 2. Integração na Tela de Detalhes da Caixa

```dart
class BoxDetailScreen extends StatefulWidget {
  final Box box;
  
  const BoxDetailScreen({Key? key, required this.box}) : super(key: key);
  
  @override
  _BoxDetailScreenState createState() => _BoxDetailScreenState();
}

class _BoxDetailScreenState extends State<BoxDetailScreen> {
  final TextToSpeechService _ttsService = TextToSpeechService();
  bool _isPlaying = false;
  List<Item> _items = [];
  
  @override
  void initState() {
    super.initState();
    _initializeTts();
    _loadItems();
  }
  
  Future<void> _initializeTts() async {
    await _ttsService.initialize();
  }
  
  Future<void> _loadItems() async {
    // Carregar itens da caixa
    final items = await getIt<BoxRepository>().getBoxItems(widget.box.id!);
    setState(() {
      _items = items;
    });
  }
  
  Future<void> _speakBoxContents() async {
    setState(() {
      _isPlaying = true;
    });
    
    final itemNames = _items.map((item) => item.name).toList();
    await _ttsService.speakBoxItems(widget.box.name, itemNames);
    
    setState(() {
      _isPlaying = false;
    });
  }
  
  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.box.name),
        actions: [
          // Botão de player no header
          IconButton(
            icon: Icon(_isPlaying ? Icons.stop_circle : Icons.play_circle),
            tooltip: _isPlaying ? 'Parar narração' : 'Narrar conteúdo da caixa',
            onPressed: () {
              if (_isPlaying) {
                _ttsService.stop();
                setState(() {
                  _isPlaying = false;
                });
              } else {
                _speakBoxContents();
              }
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Detalhes da caixa
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ID: ${widget.box.formattedId}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Categoria: ${widget.box.category}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (widget.box.description != null && widget.box.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Descrição: ${widget.box.description}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Lista de itens
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Itens',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                // Mini botão de player para itens
                IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.volume_up : Icons.volume_up_outlined,
                    color: _isPlaying ? Theme.of(context).colorScheme.primary : null,
                  ),
                  tooltip: 'Narrar itens',
                  onPressed: _speakBoxContents,
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Text(
                      'Nenhum item cadastrado',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  )
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return ListTile(
                        title: Text(item.name),
                        subtitle: item.description != null
                            ? Text(item.description!)
                            : null,
                        leading: const Icon(Icons.inventory),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            // Editar item
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Adicionar novo item
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

### 3. Configurações de TTS com Modo Automático

Adicionar uma seção nas configurações do aplicativo para personalizar a experiência de texto para voz, incluindo a opção de ativar/desativar o modo automático:

```dart
class TextToSpeechSettingsSection extends StatefulWidget {
  @override
  _TextToSpeechSettingsState createState() => _TextToSpeechSettingsState();
}

class _TextToSpeechSettingsState extends State<TextToSpeechSettingsSection> {
  final TextToSpeechService _ttsService = TextToSpeechService();
  List<String> _availableVoices = [];
  String? _selectedVoice;
  double _speechRate = 0.9;
  double _pitch = 1.0;
  bool _autoTtsEnabled = false;
  bool _autoTtsObjectEnabled = false;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    await _ttsService.initialize();
    final voices = await _ttsService.getPortugueseVoices();
    
    setState(() {
      _availableVoices = voices;
      if (voices.isNotEmpty) {
        _selectedVoice = voices.first;
      }
      _autoTtsEnabled = _ttsService.isAutoTtsEnabled;
      _autoTtsObjectEnabled = _ttsService.isAutoTtsObjectEnabled;
    });
  }
  
  Future<void> _testVoice() async {
    await _ttsService.speak("Teste de voz em português do Brasil para o aplicativo MagicBox.");
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configurações de Voz',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Ativar/desativar narração automática para caixas
            SwitchListTile(
              title: Text('Narração Automática de Caixas', 
                style: Theme.of(context).textTheme.titleMedium),
              subtitle: Text('Narrar automaticamente o conteúdo da caixa quando reconhecida por ID ou QR code'),
              value: _autoTtsEnabled,
              onChanged: (value) async {
                await _ttsService.setAutoTtsEnabled(value);
                setState(() {
                  _autoTtsEnabled = value;
                });
              },
              secondary: Icon(
                _autoTtsEnabled ? Icons.volume_up : Icons.volume_off,
                color: _autoTtsEnabled ? Theme.of(context).colorScheme.primary : null,
              ),
            ),
            
            // Ativar/desativar narração automática para objetos reconhecidos
            SwitchListTile(
              title: Text('Narração Automática de Objetos', 
                style: Theme.of(context).textTheme.titleMedium),
              subtitle: Text('Narrar automaticamente a descrição de objetos quando reconhecidos pela Gemini'),
              value: _autoTtsObjectEnabled,
              onChanged: (value) async {
                await _ttsService.setAutoTtsObjectEnabled(value);
                setState(() {
                  _autoTtsObjectEnabled = value;
                });
              },
              secondary: Icon(
                _autoTtsObjectEnabled ? Icons.camera_alt : Icons.camera_alt_outlined,
                color: _autoTtsObjectEnabled ? Theme.of(context).colorScheme.primary : null,
              ),
            ),
            
            const Divider(),
            const SizedBox(height: 8),
            
            // Seleção de voz
            Text('Voz', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              value: _selectedVoice,
              items: _availableVoices.map((voice) {
                return DropdownMenuItem<String>(
                  value: voice,
                  child: Text(voice.split(':').first),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedVoice = value;
                  });
                  _ttsService.setVoice(value);
                }
              },
            ),
            
            const SizedBox(height: 16),
            
            // Velocidade de fala
            Text('Velocidade de Fala', style: Theme.of(context).textTheme.titleMedium),
            Slider(
              value: _speechRate,
              min: 0.5,
              max: 1.5,
              divisions: 10,
              label: _speechRate.toStringAsFixed(1),
              onChanged: (value) {
                setState(() {
                  _speechRate = value;
                });
                _ttsService._flutterTts.setSpeechRate(value);
              },
            ),
            
            const SizedBox(height: 16),
            
            // Tom de voz
            Text('Tom de Voz', style: Theme.of(context).textTheme.titleMedium),
            Slider(
              value: _pitch,
              min: 0.5,
              max: 1.5,
              divisions: 10,
              label: _pitch.toStringAsFixed(1),
              onChanged: (value) {
                setState(() {
                  _pitch = value;
                });
                _ttsService._flutterTts.setPitch(value);
              },
            ),
            
            const SizedBox(height: 16),
            
            // Botão de teste
            ElevatedButton.icon(
              icon: const Icon(Icons.play_circle),
              label: const Text('Testar Voz'),
              onPressed: _testVoice,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Exemplos de Uso

### Narração Automática ao Reconhecer Objetos pela Gemini

```dart
class ObjectRecognitionService {
  final TextToSpeechService _ttsService = TextToSpeechService();
  final GeminiService _geminiService = GeminiService();
  
  Future<RecognitionResult> recognizeObject(File imageFile) async {
    try {
      // Enviar imagem para o serviço Gemini
      final response = await _geminiService.analyzeImage(imageFile);
      
      // Processar resposta
      final objectName = response.objectName;
      final description = response.description;
      
      // Tentar narrar automaticamente a descrição do objeto
      // (só narra se o modo automático para objetos estiver ativado)
      await _ttsService.autoSpeakObjectDescription(objectName, description);
      
      return RecognitionResult(
        success: true,
        objectName: objectName,
        description: description,
        suggestedCategory: response.suggestedCategory,
      );
    } catch (e) {
      return RecognitionResult(
        success: false,
        errorMessage: 'Falha ao reconhecer objeto: ${e.toString()}',
      );
    }
  }
}

class RecognitionResult {
  final bool success;
  final String? objectName;
  final String? description;
  final String? suggestedCategory;
  final String? errorMessage;
  
  RecognitionResult({
    required this.success,
    this.objectName,
    this.description,
    this.suggestedCategory,
    this.errorMessage,
  });
}
```

## Vantagens da Implementação

1. **Acessibilidade Aprimorada**
   - Permite que usuários com deficiência visual acessem o conteúdo das caixas e descrições de objetos
   - Facilita a verificação rápida do conteúdo sem necessidade de leitura

2. **Praticidade**
   - Verificação de conteúdo com as mãos ocupadas (útil em depósitos)
   - Confirmação auditiva do conteúdo durante organização

3. **Personalização**
   - Ajuste de velocidade para preferências individuais
   - Seleção de vozes diferentes para melhor compreensão

## Compatibilidade

A implementação é totalmente compatível com:

- Android 5.0+ (API 21+)
- iOS 9.0+
- Web (com limitações de vozes disponíveis)

## Considerações de Implementação

1. **Permissões**
   - Não requer permissões especiais no Android ou iOS

2. **Tamanho do APK**
   - Impacto mínimo no tamanho do APK (~100KB)

3. **Performance**
   - Utiliza as vozes nativas do sistema, sem necessidade de baixar pacotes adicionais
   - Baixo consumo de memória e processamento
