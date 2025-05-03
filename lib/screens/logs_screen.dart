import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:boxmagic/services/log_service.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  _LogsScreenState createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final LogService _logService = LogService();
  List<LogEntry> _logs = [];
  LogLevel? _selectedLevel;
  String? _selectedCategory;
  List<String> _categories = [];
  bool _isExporting = false;
  bool _isAutoRefresh = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadLogs();
    
    // Adicionar um log para teste
    _logService.debug('Tela de logs aberta', category: 'ui');
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadLogs() {
    setState(() {
      _logs = _logService.getLogs();
      
      // Extrair categorias únicas
      final categories = <String>{};
      for (final log in _logs) {
        if (log.category != null) {
          categories.add(log.category!);
        }
      }
      _categories = categories.toList()..sort();
    });
  }

  void _filterLogs() {
    setState(() {
      if (_selectedLevel != null && _selectedCategory != null) {
        _logs = _logService.getLogs().where((log) => 
          log.level == _selectedLevel && log.category == _selectedCategory
        ).toList();
      } else if (_selectedLevel != null) {
        _logs = _logService.getLogsByLevel(_selectedLevel!);
      } else if (_selectedCategory != null) {
        _logs = _logService.getLogsByCategory(_selectedCategory!);
      } else {
        _logs = _logService.getLogs();
      }
    });
  }

  Future<void> _clearLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar Logs'),
        content: const Text('Tem certeza que deseja limpar todos os logs? Esta ação não pode ser desfeita.'),
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
      _loadLogs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logs limpos com sucesso')),
        );
      }
    }
  }

  Future<void> _exportLogs() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final path = await _logService.exportLogs();
      
      if (path == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não há logs para exportar')),
          );
        }
        return;
      }

      if (kIsWeb) {
        // No ambiente web, copiamos para a área de transferência
        await Clipboard.setData(ClipboardData(text: path));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logs copiados para a área de transferência')),
          );
        }
      } else {
        // Em dispositivos móveis, compartilhamos o arquivo
        await Share.shareXFiles(
          [XFile(path)],
          subject: 'BoxMagic Logs',
          text: 'Logs do aplicativo BoxMagic',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao exportar logs: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  void _toggleAutoRefresh() {
    setState(() {
      _isAutoRefresh = !_isAutoRefresh;
    });

    if (_isAutoRefresh) {
      // Configurar atualização automática a cada 5 segundos
      Future.delayed(const Duration(seconds: 5), () {
        if (_isAutoRefresh && mounted) {
          _loadLogs();
          _toggleAutoRefresh(); // Reiniciar o timer
        }
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Color _getLogColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug: return Colors.grey;
      case LogLevel.info: return Colors.blue;
      case LogLevel.warning: return Colors.orange;
      case LogLevel.error: return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getLogIcon(LogLevel level) {
    switch (level) {
      case LogLevel.debug: return Icons.bug_report;
      case LogLevel.info: return Icons.info;
      case LogLevel.warning: return Icons.warning;
      case LogLevel.error: return Icons.error;
      default: return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs do Sistema'),
        actions: [
          // Filtro de nível
          PopupMenuButton<LogLevel?>(
            tooltip: 'Filtrar por nível',
            icon: const Icon(Icons.filter_list),
            onSelected: (level) {
              setState(() {
                _selectedLevel = level == _selectedLevel ? null : level;
              });
              _filterLogs();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('Todos os níveis'),
              ),
              ...LogLevel.values.map((level) => PopupMenuItem(
                value: level,
                child: Row(
                  children: [
                    Icon(_getLogIcon(level), color: _getLogColor(level), size: 18),
                    const SizedBox(width: 8),
                    Text(level.toString().split('.').last),
                    if (_selectedLevel == level) ...[
                      const Spacer(),
                      const Icon(Icons.check, size: 18),
                    ],
                  ],
                ),
              )),
            ],
          ),
          
          // Filtro de categoria
          PopupMenuButton<String?>(
            tooltip: 'Filtrar por categoria',
            icon: const Icon(Icons.category),
            onSelected: (category) {
              setState(() {
                _selectedCategory = category == _selectedCategory ? null : category;
              });
              _filterLogs();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('Todas as categorias'),
              ),
              ..._categories.map((category) => PopupMenuItem(
                value: category,
                child: Row(
                  children: [
                    Text(category),
                    if (_selectedCategory == category) ...[
                      const Spacer(),
                      const Icon(Icons.check, size: 18),
                    ],
                  ],
                ),
              )),
            ],
          ),
          
          // Auto-refresh
          IconButton(
            icon: Icon(_isAutoRefresh ? Icons.autorenew : Icons.refresh),
            tooltip: _isAutoRefresh ? 'Desativar atualização automática' : 'Atualizar',
            onPressed: _isAutoRefresh ? _toggleAutoRefresh : _loadLogs,
          ),
          
          // Exportar logs
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Exportar logs',
            onPressed: _isExporting ? null : _exportLogs,
          ),
          
          // Limpar logs
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Limpar logs',
            onPressed: _clearLogs,
          ),
        ],
      ),
      body: _isExporting
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Barra de informações
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.grey[200],
                  child: Row(
                    children: [
                      Text('${_logs.length} logs'),
                      const Spacer(),
                      if (_selectedLevel != null)
                        Chip(
                          label: Text(_selectedLevel.toString().split('.').last),
                          onDeleted: () {
                            setState(() {
                              _selectedLevel = null;
                            });
                            _filterLogs();
                          },
                          backgroundColor: _getLogColor(_selectedLevel!).withOpacity(0.2),
                        ),
                      const SizedBox(width: 4),
                      if (_selectedCategory != null)
                        Chip(
                          label: Text(_selectedCategory!),
                          onDeleted: () {
                            setState(() {
                              _selectedCategory = null;
                            });
                            _filterLogs();
                          },
                        ),
                    ],
                  ),
                ),
                
                // Lista de logs
                Expanded(
                  child: _logs.isEmpty
                      ? const Center(child: Text('Nenhum log encontrado'))
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: _logs.length,
                          itemBuilder: (context, index) {
                            final log = _logs[index];
                            return ExpansionTile(
                              leading: Icon(
                                _getLogIcon(log.level),
                                color: _getLogColor(log.level),
                              ),
                              title: Text(
                                log.message,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: _getLogColor(log.level),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Row(
                                children: [
                                  Text(
                                    log.timestamp.substring(0, 19).replaceAll('T', ' '),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(width: 8),
                                  if (log.category != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        log.category!,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ),
                                ],
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Mensagem:',
                                        style: Theme.of(context).textTheme.titleSmall,
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: SelectableText(log.message),
                                      ),
                                      if (log.stackTrace != null) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          'Stack Trace:',
                                          style: Theme.of(context).textTheme.titleSmall,
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          width: double.infinity,
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: SelectableText(
                                              log.stackTrace!,
                                              style: const TextStyle(
                                                fontFamily: 'monospace',
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton.icon(
                                            icon: const Icon(Icons.copy),
                                            label: const Text('Copiar'),
                                            onPressed: () {
                                              final text = log.stackTrace != null
                                                  ? '${log.message}\n\n${log.stackTrace}'
                                                  : log.message;
                                              Clipboard.setData(ClipboardData(text: text));
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Copiado para a área de transferência')),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scrollToBottom,
        tooltip: 'Ir para o final',
        child: const Icon(Icons.arrow_downward),
      ),
    );
  }
}
