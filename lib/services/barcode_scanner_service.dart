import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import '../services/log_service.dart';

class BarcodeScannerService {
  final LogService _logService = LogService();

  /// Escaneia um código de barras ou QR code
  /// Retorna o código escaneado ou null se o usuário cancelar
  Future<String?> scanBarcode(BuildContext context) async {
    _logService.info('Iniciando scanner de código de barras/QR code', category: 'scanner');
    
    // No ambiente web, mostrar um diálogo para entrada manual
    if (kIsWeb) {
      return _showWebScannerDialog(context);
    }
    
    // Em dispositivos móveis, usar o scanner nativo
    try {
      // Configurar cores e texto
      String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        '#FF6666', // Cor da linha de escaneamento
        'Cancelar', // Texto do botão cancelar
        true, // Mostrar flash
        ScanMode.DEFAULT // Modo de escaneamento (QR e código de barras)
      );
      
      // Se o usuário cancelou o escaneamento
      if (barcodeScanRes == '-1') {
        _logService.info('Escaneamento cancelado pelo usuário', category: 'scanner');
        return null;
      }
      
      _logService.info('Código escaneado: $barcodeScanRes', category: 'scanner');
      return barcodeScanRes;
    } catch (e) {
      _logService.error('Erro ao escanear código', error: e, category: 'scanner');
      
      // Em caso de erro, mostrar diálogo para entrada manual
      return _showWebScannerDialog(context);
    }
  }
  
  /// Mostra um diálogo para entrada manual do código em ambiente web
  Future<String?> _showWebScannerDialog(BuildContext context) async {
    _logService.info('Mostrando diálogo para entrada manual de código', category: 'scanner');
    
    final TextEditingController controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Entrada Manual de Código'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'O scanner de código de barras não está disponível no navegador. '
              'Por favor, digite o código manualmente:',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Código',
                hintText: 'Ex: 1234 ou BOX:1234',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    
    if (result != null && result.isNotEmpty) {
      _logService.info('Código inserido manualmente: $result', category: 'scanner');
      return result;
    }
    
    _logService.info('Entrada manual cancelada pelo usuário', category: 'scanner');
    return null;
  }
  
  /// Extrai o ID da caixa do código escaneado
  /// Retorna o ID da caixa ou null se não for possível extrair
  int? extractBoxId(String barcodeScanRes) {
    _logService.info('Extraindo ID da caixa do código: $barcodeScanRes', category: 'scanner');
    
    // Verificar se o código escaneado é um número
    int? boxId;
    try {
      boxId = int.parse(barcodeScanRes);
    } catch (e) {
      // Se não for um número, verificar se é um formato específico
      // Por exemplo, se o QR code contém "BOX:1234", extrair o número
      if (barcodeScanRes.contains('BOX:')) {
        final parts = barcodeScanRes.split(':');
        if (parts.length > 1) {
          try {
            boxId = int.parse(parts[1].trim());
          } catch (e) {
            boxId = null;
          }
        }
      }
    }
    
    _logService.info('ID da caixa extraído: $boxId', category: 'scanner');
    return boxId;
  }
}
