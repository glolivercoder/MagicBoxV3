import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:boxmagic/services/database_helper.dart';
import 'package:boxmagic/services/persistence_service.dart';
import 'package:boxmagic/services/preferences_service.dart';
import 'package:boxmagic/services/log_service.dart';
import 'package:boxmagic/services/gemini_service.dart';
import 'package:boxmagic/screens/logs_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'package:path_provider/path_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final PersistenceService _persistenceService = PersistenceService();
  final PreferencesService _preferencesService = PreferencesService();
  final LogService _logService = LogService();
  final GeminiService _geminiService = GeminiService();

  bool _isDarkMode = false;
  bool _isLoading = false;
  String _lastBackupDate = 'Nunca';
  String _backupDirectoryPath = 'Carregando...';
  int _logCount = 0;
  bool _isLoggingEnabled = true;

  // Variáveis para a API Gemini
  String _geminiApiKey = '';
  final TextEditingController _apiKeyController = TextEditingController();
  bool _isApiKeyVisible = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkLastBackup();
    _loadLoggingState();
    _countLogs();
    _loadBackupDirectoryPath();
    _loadGeminiApiKey();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadBackupDirectoryPath() async {
    try {
      final path = await _persistenceService.getBackupDirectoryPath();
      setState(() {
        _backupDirectoryPath = path;
      });
    } catch (e) {
      setState(() {
        _backupDirectoryPath = 'Erro ao carregar caminho';
      });
    }
  }

  Future<void> _selectBackupDirectory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String? selectedDirectory;

      if (kIsWeb) {
        // Implementação para web
        _logService.info('Selecionando diretório de backup (web)', category: 'settings');
        
        // No ambiente web, não podemos selecionar um diretório, então apenas mostramos uma mensagem
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Seleção de diretório não disponível na versão web'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // Implementação para plataformas nativas
        _logService.info('Selecionando diretório de backup (nativo)', category: 'settings');
        
        final result = await FilePicker.platform.getDirectoryPath();
        
        if (result != null) {
          selectedDirectory = result;
          await _persistenceService.setBackupDirectoryPath(selectedDirectory);
          
          setState(() {
            _backupDirectoryPath = selectedDirectory!;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Diretório de backup atualizado'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      _logService.error('Erro ao selecionar diretório de backup', error: e, category: 'settings');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao selecionar diretório: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadLoggingState() async {
    final isEnabled = await _logService.isLoggingEnabled();
    setState(() {
      _isLoggingEnabled = isEnabled;
    });
  }

  Future<void> _countLogs() async {
    final count = await _logService.getLogCount();
    setState(() {
      _logCount = count;
    });
  }

  Future<void> _loadSettings() async {
    final isDark = await _preferencesService.isDarkMode();
    setState(() {
      _isDarkMode = isDark;
    });
  }

  Future<void> _checkLastBackup() async {
    try {
      final lastBackup = await _persistenceService.getLastBackupDate();
      setState(() {
        _lastBackupDate = lastBackup;
      });
    } catch (e) {
      _logService.error('Erro ao verificar último backup', error: e, category: 'settings');
    }
  }

  Future<void> _toggleTheme() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final newMode = !_isDarkMode;
      await _preferencesService.setDarkMode(newMode);
      
      setState(() {
        _isDarkMode = newMode;
      });
      
      // Atualizar o tema do aplicativo
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tema ${_isDarkMode ? 'escuro' : 'claro'} ativado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _logService.error('Erro ao alternar tema', error: e, category: 'settings');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleLogging(bool value) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _logService.setLoggingEnabled(value);
      
      setState(() {
        _isLoggingEnabled = value;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registro de logs ${value ? 'ativado' : 'desativado'}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _logService.error('Erro ao alternar registro de logs', error: e, category: 'settings');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao alternar logs: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createBackup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (kIsWeb) {
        // Implementação para web
        _logService.info('Criando backup (web)', category: 'backup');
        
        // Obter os dados do banco de dados
        final boxes = await _databaseHelper.getAllBoxes();
        final items = await _databaseHelper.getAllItems();
        final users = await _databaseHelper.getAllUsers();
        
        // Exportar os dados
        final jsonData = await _persistenceService.exportAllData(
          boxes: boxes,
          items: items,
          users: users,
        );
        
        final bytes = utf8.encode(jsonData);
        final blob = html.Blob([bytes]);
        
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'boxmagic_backup_${DateTime.now().toIso8601String()}.json')
          ..click();
        
        html.Url.revokeObjectUrl(url);
        
        await _persistenceService.saveLastBackupDate();
        await _checkLastBackup();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Backup criado com sucesso'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Implementação para plataformas nativas
        _logService.info('Criando backup (nativo)', category: 'backup');
        
        final backupPath = _backupDirectoryPath;
        
        if (backupPath == 'Carregando...' || backupPath == 'Erro ao carregar caminho') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Selecione um diretório de backup válido'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
        
        final directory = Directory(backupPath);
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        
        // Obter os dados do banco de dados
        final boxes = await _databaseHelper.getAllBoxes();
        final items = await _databaseHelper.getAllItems();
        final users = await _databaseHelper.getAllUsers();
        
        // Exportar os dados
        final jsonData = await _persistenceService.exportAllData(
          boxes: boxes,
          items: items,
          users: users,
        );
        
        final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
        final fileName = 'boxmagic_backup_$timestamp.json';
        final filePath = '${directory.path}${Platform.pathSeparator}$fileName';
        
        final file = File(filePath);
        await file.writeAsString(jsonData);
        
        await _persistenceService.saveLastBackupDate();
        await _checkLastBackup();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Backup criado em: $filePath'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      _logService.error('Erro ao criar backup', error: e, category: 'backup');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar backup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _restoreBackup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (kIsWeb) {
        // Implementação para web
        _logService.info('Restaurando backup (web)', category: 'backup');
        
        // Mostrar diálogo de confirmação
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Restaurar Backup'),
            content: const Text(
              'Esta operação substituirá todos os dados atuais. Deseja continuar?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Restaurar'),
              ),
            ],
          ),
        );
        
        if (confirmed != true) {
          return;
        }
        
        // Implementação web para selecionar arquivo
        final input = html.FileUploadInputElement()..accept = '.json';
        input.click();
        
        await input.onChange.first;
        
        if (input.files?.isEmpty ?? true) {
          return;
        }
        
        final file = input.files!.first;
        final reader = html.FileReader();
        reader.readAsText(file);
        
        await reader.onLoad.first;
        
        final jsonData = reader.result as String;
        
        // Importar os dados
        await _persistenceService.importAllData(jsonData);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Backup restaurado com sucesso'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Implementação para plataformas nativas
        _logService.info('Restaurando backup (nativo)', category: 'backup');
        
        // Mostrar diálogo de confirmação
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Restaurar Backup'),
            content: const Text(
              'Esta operação substituirá todos os dados atuais. Deseja continuar?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Restaurar'),
              ),
            ],
          ),
        );
        
        if (confirmed != true) {
          return;
        }
        
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['json'],
        );
        
        if (result == null || result.files.isEmpty) {
          return;
        }
        
        final path = result.files.single.path;
        
        if (path == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Caminho do arquivo inválido'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        
        final file = File(path);
        final jsonData = await file.readAsString();
        
        // Importar os dados
        await _persistenceService.importAllData(jsonData);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Backup restaurado com sucesso'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      _logService.error('Erro ao restaurar backup', error: e, category: 'backup');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao restaurar backup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearAllData() async {
    // Mostrar diálogo de confirmação
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar Todos os Dados'),
        content: const Text(
          'Esta operação apagará permanentemente todos os dados do aplicativo. '
          'Esta ação não pode ser desfeita. Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Limpar Dados'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) {
      return;
    }
    
    // Pedir confirmação adicional
    final confirmedAgain = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmação Final'),
        content: const Text(
          'Tem certeza absoluta? Todos os dados serão perdidos permanentemente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sim, Limpar Tudo'),
          ),
        ],
      ),
    );
    
    if (confirmedAgain != true) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      _logService.info('Limpando todos os dados', category: 'settings');
      
      // Limpar todos os dados
      await _databaseHelper.clearDatabase();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Todos os dados foram limpos'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _logService.error('Erro ao limpar dados', error: e, category: 'settings');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao limpar dados: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createMagicboxLog() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Criar logs de teste para garantir que o arquivo tenha conteúdo
      _logService.info('Arquivo de log criado manualmente pelo usuário', category: 'export');
      _logService.info('Este arquivo pode ser enviado para análise', category: 'export');
      _logService.info('Contém informações sobre o funcionamento do aplicativo', category: 'export');

      // Forçar a criação do arquivo
      final entry = LogEntry(
        level: LogLevel.info,
        message: 'Arquivo MAGICBOX.log criado para análise externa',
        timestamp: DateTime.now().toIso8601String(),
        category: 'export',
      );

      // Tentar obter o diretório de downloads
      Directory? directory;
      try {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          // Se não existir, tentar o diretório de documentos
          directory = await getExternalStorageDirectory();
        }
      } catch (e) {
        // Em caso de erro, usar o diretório de documentos
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Não foi possível obter o diretório para salvar o log');
      }

      final file = File('${directory.path}/MAGICBOX.log');

      // Formatar a entrada de log
      final logLine = '${entry.timestamp} [INFO] [export] Arquivo MAGICBOX.log criado para análise externa\n';

      // Criar o arquivo com as informações do sistema
      final buffer = StringBuffer();
      buffer.writeln('=== BoxMagic Log File ===');
      buffer.writeln('Data de criação: ${DateTime.now().toString()}');
      buffer.writeln('Versão do aplicativo: 1.0.0');
      buffer.writeln('Plataforma: ${kIsWeb ? 'Web' : Platform.operatingSystem}');
      buffer.writeln('==============================\n');

      // Adicionar alguns logs recentes
      final recentLogs = _logService.getLogs().reversed.take(50).toList().reversed;
      for (final log in recentLogs) {
        final categoryStr = log.category != null ? '[${log.category}]' : '';
        final levelStr = log.level.toString().split('.').last.toUpperCase();
        buffer.writeln('${log.timestamp} [$levelStr] $categoryStr ${log.message}');
        if (log.stackTrace != null) {
          buffer.writeln(log.stackTrace);
        }
      }

      // Adicionar o log de criação do arquivo
      buffer.writeln(logLine);

      // Escrever no arquivo
      await file.writeAsString(buffer.toString());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Arquivo criado em: ${file.path}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar arquivo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadGeminiApiKey() async {
    try {
      final apiKey = await _geminiService.getApiKey();
      setState(() {
        _geminiApiKey = apiKey;
        _apiKeyController.text = apiKey;
      });
    } catch (e) {
      _logService.error('Erro ao carregar chave da API Gemini', error: e, category: 'settings');
    }
  }

  Future<void> _saveGeminiApiKey() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiKey = _apiKeyController.text.trim();
      final success = await _geminiService.updateApiKey(apiKey);

      if (success) {
        setState(() {
          _geminiApiKey = apiKey;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chave da API Gemini atualizada com sucesso'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao atualizar chave da API Gemini'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      _logService.error('Erro ao salvar chave da API Gemini', error: e, category: 'settings');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar chave da API Gemini: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // Tema
                const _SectionHeader(title: 'Aparência'),
                SwitchListTile(
                  title: const Text('Tema Escuro'),
                  subtitle: Text(_isDarkMode ? 'Ativado' : 'Desativado'),
                  value: _isDarkMode,
                  onChanged: (value) => _toggleTheme(),
                  secondary: Icon(
                    _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  ),
                ),

                // Backup e Restauração
                const _SectionHeader(title: 'Backup e Restauração'),
                ListTile(
                  title: const Text('Diretório de Backup'),
                  subtitle: Text(_backupDirectoryPath),
                  leading: const Icon(Icons.folder),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: _selectBackupDirectory,
                  ),
                ),
                ListTile(
                  title: const Text('Último Backup'),
                  subtitle: Text(_lastBackupDate),
                  leading: const Icon(Icons.access_time),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.backup),
                          label: const Text('Criar Backup'),
                          onPressed: _createBackup,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.restore),
                          label: const Text('Restaurar'),
                          onPressed: _restoreBackup,
                        ),
                      ),
                    ],
                  ),
                ),

                // Logs
                const _SectionHeader(title: 'Logs do Sistema'),
                SwitchListTile(
                  title: const Text('Registro de Logs'),
                  subtitle: Text(_isLoggingEnabled ? 'Ativado' : 'Desativado'),
                  value: _isLoggingEnabled,
                  onChanged: _toggleLogging,
                  secondary: const Icon(Icons.bug_report),
                ),
                ListTile(
                  title: Text('Logs Registrados: $_logCount'),
                  subtitle: const Text('Visualize ou limpe os logs do sistema'),
                  leading: const Icon(Icons.list),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Limpar Logs'),
                              content: const Text('Deseja limpar todos os logs?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Limpar'),
                                ),
                              ],
                            ),
                          );
                          
                          if (confirmed == true) {
                            await _logService.clearLogs();
                            await _countLogs();
                            
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Logs limpos com sucesso'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.visibility),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LogsScreen(),
                            ),
                          ).then((_) => _countLogs());
                        },
                      ),
                    ],
                  ),
                ),
                
                // Botão para criar arquivo de log específico
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.file_download),
                    label: const Text('Criar arquivo MAGICBOX.log'),
                    onPressed: _createMagicboxLog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                    ),
                  ),
                ),

                // Gerenciamento de Dados
                const _SectionHeader(title: 'Gerenciamento de Dados'),
                ListTile(
                  title: const Text('Limpar Todos os Dados'),
                  subtitle: const Text('Apaga permanentemente todos os dados do aplicativo'),
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  onTap: _clearAllData,
                ),

                // Estatísticas
                const _SectionHeader(title: 'Estatísticas'),
                FutureBuilder<Map<String, dynamic>>(
                  future: _databaseHelper.getDatabaseStats(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (snapshot.hasError) {
                      return ListTile(
                        title: const Text('Erro ao carregar estatísticas'),
                        subtitle: Text('${snapshot.error}'),
                        leading: const Icon(Icons.error),
                      );
                    }
                    
                    final stats = snapshot.data ?? {};
                    final boxCount = stats['boxCount'] ?? 0;
                    final itemCount = stats['itemCount'] ?? 0;
                    
                    return Column(
                      children: [
                        ListTile(
                          title: Text('Total de Caixas: $boxCount'),
                          leading: const Icon(Icons.inbox),
                        ),
                        ListTile(
                          title: Text('Total de Itens: $itemCount'),
                          leading: const Icon(Icons.category),
                        ),
                      ],
                    );
                  },
                ),

                // Seção de API Gemini
                const _SectionHeader(title: 'API Gemini'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Configure a chave da API Gemini para reconhecimento de imagens e análise de objetos.',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _apiKeyController,
                              decoration: const InputDecoration(
                                labelText: 'Chave da API Gemini',
                                hintText: 'Insira sua chave da API Gemini',
                                border: OutlineInputBorder(),
                              ),
                              obscureText: !_isApiKeyVisible,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(_isApiKeyVisible ? Icons.visibility_off : Icons.visibility),
                            tooltip: _isApiKeyVisible ? 'Ocultar chave' : 'Mostrar chave',
                            onPressed: () {
                              setState(() {
                                _isApiKeyVisible = !_isApiKeyVisible;
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.save),
                            tooltip: 'Salvar chave',
                            onPressed: _saveGeminiApiKey,
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_red_eye_outlined),
                            tooltip: 'Exibir chave salva',
                            onPressed: () async {
                              final key = _apiKeyController.text.trim();
                              await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Chave Gemini salva'),
                                  content: Text(key.isEmpty ? 'Nenhuma chave salva.' : key),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Fechar'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'A chave padrão é compartilhada e pode ter limitações. Para melhor desempenho, use sua própria chave.',
                        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),

                // Sobre o aplicativo
                const _SectionHeader(title: 'Sobre'),
                const ListTile(
                  title: Text('BoxMagic'),
                  subtitle: Text('Versão 1.0.0'),
                  leading: Icon(Icons.info_outline),
                ),
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }
}
