# Implementação de Comandos de Voz no MagicBoxV2

## Visão Geral

Esta documentação descreve a implementação de comandos de voz no MagicBoxV2, permitindo que o usuário controle o aplicativo usando a palavra-chave "Zoio" seguida de comandos específicos, mesmo quando o aplicativo está em segundo plano.

## Bibliotecas Recomendadas

Para implementar o reconhecimento de voz contínuo com detecção de palavra-chave, utilizaremos uma combinação de bibliotecas:

1. **speech_to_text**: Para reconhecimento de voz básico
2. **flutter_background_service**: Para manter o serviço de reconhecimento ativo em segundo plano
3. **flutter_local_notifications**: Para notificar o usuário quando o serviço está ativo
4. **picovoice_flutter**: Para detecção de palavra-chave personalizada ("Zoio")

## Implementação

### 1. Serviço de Reconhecimento de Voz

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:picovoice_flutter/picovoice_flutter.dart';
import 'package:picovoice_flutter/picovoice_error.dart';
import 'package:picovoice_flutter/picovoice_manager.dart';

class VoiceCommandService {
  static const String VOICE_COMMANDS_ENABLED_KEY = 'voice_commands_enabled';
  
  final SpeechToText _speechToText = SpeechToText();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  PicovoiceManager? _picovoiceManager;
  bool _isListening = false;
  bool _voiceCommandsEnabled = false;
  
  // Singleton pattern
  static final VoiceCommandService _instance = VoiceCommandService._internal();
  
  factory VoiceCommandService() {
    return _instance;
  }
  
  VoiceCommandService._internal();
  
  Future<void> initialize() async {
    // Inicializar reconhecimento de voz
    bool available = await _speechToText.initialize(
      onStatus: (status) {
        debugPrint('Status do reconhecimento de voz: $status');
      },
      onError: (error) {
        debugPrint('Erro no reconhecimento de voz: $error');
      },
    );
    
    if (!available) {
      debugPrint('Reconhecimento de voz não disponível no dispositivo');
      return;
    }
    
    // Inicializar notificações
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(initSettings);
    
    // Carregar configuração
    final prefs = await SharedPreferences.getInstance();
    _voiceCommandsEnabled = prefs.getBool(VOICE_COMMANDS_ENABLED_KEY) ?? false;
    
    // Inicializar detecção de palavra-chave
    try {
      _picovoiceManager = await PicovoiceManager.create(
        "CHAVE_API_PICOVOICE", // Obtenha uma chave em picovoice.ai
        _wakeWordCallback,
        "assets/zoio_keyword.ppn", // Modelo treinado para a palavra "Zoio"
        _inferenceCallback,
        "assets/commands.rhn", // Modelo de comandos específicos
      );
    } on PicovoiceException catch (e) {
      debugPrint("Erro ao inicializar Picovoice: ${e.message}");
    }
    
    // Iniciar serviço em segundo plano se estiver habilitado
    if (_voiceCommandsEnabled) {
      await startListening();
    }
  }
  
  Future<void> setVoiceCommandsEnabled(bool enabled) async {
    _voiceCommandsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(VOICE_COMMANDS_ENABLED_KEY, enabled);
    
    if (enabled) {
      await startListening();
    } else {
      await stopListening();
    }
  }
  
  Future<void> startListening() async {
    if (_isListening) return;
    
    // Iniciar serviço em segundo plano
    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onBackgroundStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'voice_commands',
        initialNotificationTitle: 'Comandos de Voz Ativos',
        initialNotificationContent: 'MagicBox está ouvindo por comandos "Zoio"',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: _onBackgroundStart,
        onBackground: _onBackgroundStart,
      ),
    );
    
    await service.startService();
    
    // Iniciar detecção de palavra-chave
    if (_picovoiceManager != null) {
      try {
        await _picovoiceManager!.start();
      } on PicovoiceException catch (e) {
        debugPrint("Erro ao iniciar Picovoice: ${e.message}");
      }
    }
    
    _isListening = true;
  }
  
  Future<void> stopListening() async {
    if (!_isListening) return;
    
    // Parar serviço em segundo plano
    final service = FlutterBackgroundService();
    await service.stopService();
    
    // Parar detecção de palavra-chave
    if (_picovoiceManager != null) {
      try {
        await _picovoiceManager!.stop();
      } on PicovoiceException catch (e) {
        debugPrint("Erro ao parar Picovoice: ${e.message}");
      }
    }
    
    _isListening = false;
  }
  
  // Callback quando a palavra-chave "Zoio" é detectada
  void _wakeWordCallback() {
    debugPrint("Palavra-chave 'Zoio' detectada!");
    
    // Iniciar reconhecimento de comando específico
    _startCommandRecognition();
  }
  
  // Callback para processar o comando após a palavra-chave
  void _inferenceCallback(Map<String, dynamic> inference) {
    final intent = inference['intent'];
    final confidence = inference['confidence'];
    
    if (confidence > 0.7) {
      _processCommand(intent);
    }
  }
  
  // Iniciar reconhecimento de comando específico
  Future<void> _startCommandRecognition() async {
    await _speechToText.listen(
      onResult: (result) {
        if (result.finalResult) {
          final command = result.recognizedWords.toLowerCase();
          _processVoiceCommand(command);
        }
      },
      listenFor: Duration(seconds: 5),
      localeId: "pt_BR",
    );
  }
  
  // Processar comando de voz recebido
  void _processVoiceCommand(String command) {
    debugPrint("Comando recebido: $command");
    
    if (command.contains("abra a caixa") || command.contains("abrir caixa")) {
      _executeOpenBoxCommand(command);
    } else if (command.contains("o que é isso") || command.contains("o que é esse")) {
      _executeRecognizeObjectCommand();
    } else if (command.contains("leia para mim") || command.contains("ler para mim")) {
      _executeReadContentCommand();
    }
  }
  
  // Processar comando de inferência do Picovoice
  void _processCommand(String intent) {
    switch (intent) {
      case 'openBox':
        _executeOpenBoxCommand("");
        break;
      case 'recognizeObject':
        _executeRecognizeObjectCommand();
        break;
      case 'readContent':
        _executeReadContentCommand();
        break;
    }
  }
  
  // Executar comando para abrir uma caixa
  Future<void> _executeOpenBoxCommand(String command) async {
    // Extrair ID da caixa do comando, se presente
    String? boxId;
    
    final RegExp regExp = RegExp(r'caixa (\d+)');
    final match = regExp.firstMatch(command);
    
    if (match != null && match.groupCount >= 1) {
      boxId = match.group(1);
    }
    
    // Enviar evento para o aplicativo abrir a caixa
    final service = FlutterBackgroundService();
    service.sendData({
      'action': 'openBox',
      'boxId': boxId,
    });
  }
  
  // Executar comando para reconhecer objeto
  Future<void> _executeRecognizeObjectCommand() async {
    final service = FlutterBackgroundService();
    service.sendData({
      'action': 'recognizeObject',
    });
  }
  
  // Executar comando para ler conteúdo
  Future<void> _executeReadContentCommand() async {
    final service = FlutterBackgroundService();
    service.sendData({
      'action': 'readContent',
    });
  }
  
  // Função executada em segundo plano
  @pragma('vm:entry-point')
  static void _onBackgroundStart(ServiceInstance service) {
    WidgetsFlutterBinding.ensureInitialized();
    
    service.on('stopService').listen((event) {
      service.stopSelf();
    });
    
    // Receber eventos do serviço em segundo plano
    service.on('setData').listen((event) {
      if (event != null) {
        // Processar dados recebidos
      }
    });
  }
  
  // Liberar recursos
  Future<void> dispose() async {
    await stopListening();
    
    if (_picovoiceManager != null) {
      try {
        _picovoiceManager!.delete();
      } on PicovoiceException catch (e) {
        debugPrint("Erro ao deletar Picovoice: ${e.message}");
      }
    }
  }
}
```

### 2. Integração com o Aplicativo

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/voice_command_service.dart';

class VoiceCommandScreen extends StatefulWidget {
  @override
  _VoiceCommandScreenState createState() => _VoiceCommandScreenState();
}

class _VoiceCommandScreenState extends State<VoiceCommandScreen> {
  final VoiceCommandService _voiceService = VoiceCommandService();
  bool _voiceCommandsEnabled = false;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _voiceCommandsEnabled = prefs.getBool(VoiceCommandService.VOICE_COMMANDS_ENABLED_KEY) ?? false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comandos de Voz'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comandos de Voz "Zoio"',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SwitchListTile(
                      title: Text('Ativar Comandos de Voz'),
                      subtitle: Text('Permite controlar o app dizendo "Zoio" seguido do comando'),
                      value: _voiceCommandsEnabled,
                      onChanged: (value) async {
                        await _voiceService.setVoiceCommandsEnabled(value);
                        setState(() {
                          _voiceCommandsEnabled = value;
                        });
                      },
                      secondary: Icon(
                        _voiceCommandsEnabled ? Icons.mic : Icons.mic_off,
                        color: _voiceCommandsEnabled ? Theme.of(context).colorScheme.primary : null,
                      ),
                    ),
                    
                    Divider(),
                    
                    Text(
                      'Comandos Disponíveis:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
                    
                    _buildCommandItem(
                      context,
                      'Zoio, abra a caixa',
                      'Abre a tela de detalhes da caixa. Você pode especificar o número, como "Zoio, abra a caixa 42"',
                      Icons.inventory_2,
                    ),
                    
                    _buildCommandItem(
                      context,
                      'Zoio, o que é isso?',
                      'Ativa a câmera para reconhecimento de objetos',
                      Icons.camera_alt,
                    ),
                    
                    _buildCommandItem(
                      context,
                      'Zoio, leia para mim',
                      'Narra o conteúdo da caixa ou objeto atualmente em foco',
                      Icons.record_voice_over,
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informações',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Os comandos de voz funcionam mesmo com o aplicativo em segundo plano. '
                      'Uma notificação permanente será exibida enquanto o serviço estiver ativo.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Nota: O uso contínuo do reconhecimento de voz pode afetar a duração da bateria.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCommandItem(BuildContext context, String command, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  command,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### 3. Processamento de Comandos no Aplicativo Principal

```dart
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'services/voice_command_service.dart';

class MagicBoxApp extends StatefulWidget {
  @override
  _MagicBoxAppState createState() => _MagicBoxAppState();
}

class _MagicBoxAppState extends State<MagicBoxApp> {
  final VoiceCommandService _voiceService = VoiceCommandService();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  
  @override
  void initState() {
    super.initState();
    _initializeVoiceCommands();
  }
  
  Future<void> _initializeVoiceCommands() async {
    await _voiceService.initialize();
    
    // Configurar listener para comandos de voz em segundo plano
    FlutterBackgroundService().on('data').listen((data) {
      if (data != null && data is Map<String, dynamic>) {
        _processBackgroundCommand(data);
      }
    });
  }
  
  void _processBackgroundCommand(Map<String, dynamic> data) {
    final action = data['action'];
    
    switch (action) {
      case 'openBox':
        final boxId = data['boxId'];
        _navigateToBoxDetails(boxId);
        break;
      case 'recognizeObject':
        _navigateToObjectRecognition();
        break;
      case 'readContent':
        _readCurrentContent();
        break;
    }
  }
  
  void _navigateToBoxDetails(String? boxId) {
    // Navegar para a tela de detalhes da caixa
    if (boxId != null) {
      // Buscar caixa por ID e navegar
      _navigatorKey.currentState?.pushNamed('/box-details', arguments: {'boxId': boxId});
    } else {
      // Abrir tela de pesquisa de caixas
      _navigatorKey.currentState?.pushNamed('/box-search');
    }
  }
  
  void _navigateToObjectRecognition() {
    // Navegar para a tela de reconhecimento de objetos
    _navigatorKey.currentState?.pushNamed('/object-recognition');
  }
  
  void _readCurrentContent() {
    // Ler conteúdo da tela atual (depende do contexto)
    // Isso requer uma implementação mais complexa para identificar
    // qual conteúdo está sendo exibido atualmente
    
    // Exemplo simplificado:
    final currentRoute = ModalRoute.of(_navigatorKey.currentContext!)?.settings.name;
    
    if (currentRoute == '/box-details') {
      // Ler detalhes da caixa atual
      final boxDetailsState = _navigatorKey.currentContext!.findAncestorStateOfType<BoxDetailsScreenState>();
      boxDetailsState?.readBoxContent();
    } else if (currentRoute == '/object-recognition-result') {
      // Ler resultado do reconhecimento
      final recognitionState = _navigatorKey.currentContext!.findAncestorStateOfType<ObjectRecognitionResultState>();
      recognitionState?.readRecognitionResult();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'MagicBox V2',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.dark(
          primary: Color(0xFF00B4FF),
          secondary: Color(0xFF9D00FF),
        ),
      ),
      themeMode: ThemeMode.system,
      // Rotas e home screen
      // ...
    );
  }
  
  @override
  void dispose() {
    _voiceService.dispose();
    super.dispose();
  }
}
```

## Configuração do pubspec.yaml

```yaml
dependencies:
  flutter:
    sdk: flutter
  speech_to_text: ^6.1.1
  flutter_background_service: ^2.5.1
  flutter_local_notifications: ^13.0.0
  picovoice_flutter: ^2.2.1
  shared_preferences: ^2.1.0
```

## Permissões Necessárias

### Android (AndroidManifest.xml)

```xml
<manifest ...>
  <uses-permission android:name="android.permission.RECORD_AUDIO" />
  <uses-permission android:name="android.permission.INTERNET" />
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
  <uses-permission android:name="android.permission.WAKE_LOCK" />
  
  <application ...>
    <service
      android:name="com.dexterous.flutterlocalnotifications.ForegroundService"
      android:exported="false"
      android:stopWithTask="false" />
  </application>
</manifest>
```

### iOS (Info.plist)

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Este aplicativo precisa de acesso ao microfone para reconhecer comandos de voz</string>
<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
  <string>processing</string>
</array>
```

## Considerações de Implementação

1. **Palavra-chave Personalizada**
   - A biblioteca Picovoice permite criar palavras-chave personalizadas como "Zoio"
   - É necessário treinar o modelo para reconhecer essa palavra específica
   - Alternativa: usar palavras-chave pré-treinadas como "Hey Flutter" ou "OK Google"

2. **Consumo de Bateria**
   - O reconhecimento contínuo consome bateria significativamente
   - Implementar opção para desligar automaticamente após período de inatividade
   - Considerar ativar apenas quando o aplicativo está em uso ativo

3. **Precisão de Reconhecimento**
   - Treinar o modelo com sotaques brasileiros para melhor reconhecimento
   - Implementar feedback sonoro quando a palavra-chave é reconhecida
   - Oferecer alternativas para comandos mal interpretados

4. **Privacidade**
   - Todo o processamento da palavra-chave é feito localmente no dispositivo
   - Apenas após detectar "Zoio", o áudio é enviado para processamento
   - Informar claramente ao usuário quando o microfone está ativo

## Vantagens da Implementação

1. **Acessibilidade Aprimorada**
   - Permite uso hands-free do aplicativo
   - Ideal para pessoas com mobilidade reduzida
   - Complementa o sistema de TTS para uma experiência completa

2. **Eficiência Operacional**
   - Acesso rápido a funções sem navegar por menus
   - Útil em ambientes de depósito/estoque onde as mãos estão ocupadas
   - Reduz tempo de operação para tarefas comuns

3. **Experiência de Usuário Moderna**
   - Interface por voz complementa a interface gráfica
   - Personalização com a palavra "Zoio" cria identidade única
   - Funcionalidade diferenciada em relação a aplicativos concorrentes

## Limitações e Soluções

1. **Ruído Ambiente**
   - Implementar filtros de ruído e ajuste de sensibilidade
   - Opção para aumentar o limiar de confiança em ambientes barulhentos

2. **Compatibilidade com Plataformas**
   - Funcionalidade em segundo plano limitada no iOS
   - Implementar fallback para funcionar apenas em primeiro plano no iOS

3. **Consumo de Recursos**
   - Otimizar para reduzir uso de CPU/memória
   - Opção para desativar automaticamente após período sem uso
