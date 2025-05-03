// Arquivo corrigido: persistence_service.dart
// Correções principais:
// 1. Removido código morto que nunca seria executado após o return na função _getBackupDirectory

// Método _getBackupDirectory corrigido (removido código morto)
Future<Directory> _getBackupDirectory() async {
  late Directory backupDir;
  
  try {
    if (kIsWeb) {
      // Para web, usamos um diretório virtual em memória
      _logService.info('Ambiente web detectado, usando diretório virtual', category: 'backup');
      return Directory('memory://backups');
    }
    
    // Para dispositivos móveis, usar o diretório de documentos ou personalizado
    // Verificar se existe um diretório personalizado salvo nas preferências
    final prefs = await SharedPreferences.getInstance();
    final customPath = prefs.getString(_backupDirPrefKey);
    
    if (customPath != null && customPath.isNotEmpty) {
      // Usar o diretório personalizado
      backupDir = Directory(customPath);
      _logService.info('Usando diretório de backup personalizado: ${backupDir.path}', category: 'backup');
    } else {
      // Usar o diretório padrão para Android
      final defaultPath = await getDefaultBackupPath();
      backupDir = Directory(defaultPath);
      _logService.info('Usando diretório de backup padrão: ${backupDir.path}', category: 'backup');
    }
    
    // Criar diretório de backup se não existir
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
      _logService.info('Diretório de backup criado: ${backupDir.path}', category: 'backup');
    }
    
    return backupDir;
  } catch (e) {
    _logService.error('Erro ao criar diretório de backup: $e', category: 'backup');
    // Fallback para diretório temporário
    final tempDir = await getTemporaryDirectory();
    backupDir = Directory('${tempDir.path}/backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }
}
