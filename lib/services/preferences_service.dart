import 'package:shared_preferences/shared_preferences.dart';
import 'package:boxmagic/services/log_service.dart';

/// Serviço para gerenciar preferências do usuário
/// Seguindo as regras de código limpo e modular definidas no projeto
class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  final LogService _logService = LogService();
  
  // Chaves para as preferências
  static const String _themeKey = 'theme';
  static const String _languageKey = 'language';
  static const String _lastBackupDateKey = 'last_backup_date';
  static const String _backupDirKey = 'backup_directory';
  
  factory PreferencesService() {
    return _instance;
  }
  
  PreferencesService._internal();
  
  /// Salva o tema escolhido pelo usuário
  Future<bool> saveTheme(String theme) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.setString(_themeKey, theme);
      
      _logService.info('Tema salvo: $theme', category: 'preferences');
      return result;
    } catch (e, stackTrace) {
      _logService.error(
        'Erro ao salvar tema',
        error: e,
        stackTrace: stackTrace,
        category: 'preferences',
      );
      return false;
    }
  }
  
  /// Obtém o tema escolhido pelo usuário
  Future<String> getTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final theme = prefs.getString(_themeKey) ?? 'light';
      
      _logService.debug('Tema obtido: $theme', category: 'preferences');
      return theme;
    } catch (e, stackTrace) {
      _logService.error(
        'Erro ao obter tema',
        error: e,
        stackTrace: stackTrace,
        category: 'preferences',
      );
      return 'light'; // Valor padrão em caso de erro
    }
  }
  
  /// Salva o idioma escolhido pelo usuário
  Future<bool> saveLanguage(String language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.setString(_languageKey, language);
      
      _logService.info('Idioma salvo: $language', category: 'preferences');
      return result;
    } catch (e, stackTrace) {
      _logService.error(
        'Erro ao salvar idioma',
        error: e,
        stackTrace: stackTrace,
        category: 'preferences',
      );
      return false;
    }
  }
  
  /// Obtém o idioma escolhido pelo usuário
  Future<String> getLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final language = prefs.getString(_languageKey) ?? 'pt_BR';
      
      _logService.debug('Idioma obtido: $language', category: 'preferences');
      return language;
    } catch (e, stackTrace) {
      _logService.error(
        'Erro ao obter idioma',
        error: e,
        stackTrace: stackTrace,
        category: 'preferences',
      );
      return 'pt_BR'; // Valor padrão em caso de erro
    }
  }
  
  /// Salva a data do último backup
  Future<bool> saveLastBackupDate(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.setString(_lastBackupDateKey, date.toIso8601String());
      
      _logService.info('Data do último backup salva: ${date.toIso8601String()}', category: 'preferences');
      return result;
    } catch (e, stackTrace) {
      _logService.error(
        'Erro ao salvar data do último backup',
        error: e,
        stackTrace: stackTrace,
        category: 'preferences',
      );
      return false;
    }
  }
  
  /// Obtém a data do último backup
  Future<DateTime?> getLastBackupDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateStr = prefs.getString(_lastBackupDateKey);
      
      if (dateStr != null) {
        final date = DateTime.parse(dateStr);
        _logService.debug('Data do último backup obtida: $dateStr', category: 'preferences');
        return date;
      }
      
      _logService.debug('Nenhuma data de backup encontrada', category: 'preferences');
      return null;
    } catch (e, stackTrace) {
      _logService.error(
        'Erro ao obter data do último backup',
        error: e,
        stackTrace: stackTrace,
        category: 'preferences',
      );
      return null;
    }
  }
  
  /// Salva o diretório de backup personalizado
  Future<bool> saveBackupDirectory(String directory) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.setString(_backupDirKey, directory);
      
      _logService.info('Diretório de backup salvo: $directory', category: 'preferences');
      return result;
    } catch (e, stackTrace) {
      _logService.error(
        'Erro ao salvar diretório de backup',
        error: e,
        stackTrace: stackTrace,
        category: 'preferences',
      );
      return false;
    }
  }
  
  /// Obtém o diretório de backup personalizado
  Future<String?> getBackupDirectory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final directory = prefs.getString(_backupDirKey);
      
      if (directory != null) {
        _logService.debug('Diretório de backup obtido: $directory', category: 'preferences');
      } else {
        _logService.debug('Nenhum diretório de backup personalizado encontrado', category: 'preferences');
      }
      
      return directory;
    } catch (e, stackTrace) {
      _logService.error(
        'Erro ao obter diretório de backup',
        error: e,
        stackTrace: stackTrace,
        category: 'preferences',
      );
      return null;
    }
  }
  
  /// Verifica se o tema escuro está ativo
  Future<bool> isDarkMode() async {
    try {
      final theme = await getTheme();
      return theme == 'dark';
    } catch (e, stackTrace) {
      _logService.error(
        'Erro ao verificar tema escuro',
        error: e,
        stackTrace: stackTrace,
        category: 'preferences',
      );
      return false; // Valor padrão em caso de erro
    }
  }

  /// Define o modo escuro
  Future<bool> setDarkMode(bool isDark) async {
    try {
      final theme = isDark ? 'dark' : 'light';
      return await saveTheme(theme);
    } catch (e, stackTrace) {
      _logService.error(
        'Erro ao definir modo escuro',
        error: e,
        stackTrace: stackTrace,
        category: 'preferences',
      );
      return false;
    }
  }
  
  /// Limpa todas as preferências
  Future<bool> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.clear();
      
      _logService.info('Todas as preferências foram limpas', category: 'preferences');
      return result;
    } catch (e, stackTrace) {
      _logService.error(
        'Erro ao limpar preferências',
        error: e,
        stackTrace: stackTrace,
        category: 'preferences',
      );
      return false;
    }
  }
}
