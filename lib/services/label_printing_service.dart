import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;
import '../models/box.dart';
import '../services/log_service.dart';

enum LabelFormat {
  nameWithBarcodeAndId,
  idWithBarcode,
  idWithBarcodeAndItems,
  nameWithLocation,
  nameWithLocationAndCategory,
}

enum LabelPaperType {
  carta25x67,       // Etiqueta padrão para cartas 25,4 x 66,7mm (30 por folha)
  ecommerce100x150, // Etiqueta de e-commerce 100x150mm
  pimaco6180,       // Pimaco 6180 - Padrão Correios (A4 com 10 etiquetas)
  pimaco6082,       // Pimaco 6082 - 2 colunas, 14 linhas (A4 com 28 etiquetas)
  pimaco6280,       // Pimaco 6280 - 3 colunas, 10 linhas (A4 com 30 etiquetas)
  pimaco6181,       // Pimaco 6181 - 2 colunas, 7 linhas (A4 com 14 etiquetas)
  pimaco6080,       // Pimaco 6080 - 3 colunas, 10 linhas (A4 com 30 etiquetas)
  a4Full,           // Página A4 inteira
  custom,           // Tamanho personalizado
}

enum PrinterModel {
  zebraZD220,      // Zebra ZD220
  argoxOS214Plus,  // Argox OS 214 Plus
  elginL42Pro,     // Elgin L42 Pro/L42DT
  generic,         // Impressora genérica
}

class LabelPrintingService {
  final LogService _logService = LogService();

  // Mapa de configurações de etiquetas
  final Map<LabelPaperType, Map<String, dynamic>> _labelConfigs = {
    LabelPaperType.carta25x67: {
      'width': 66.7 * PdfPageFormat.mm,
      'height': 25.4 * PdfPageFormat.mm,
      'columns': 3,
      'rows': 10,
      'marginLeft': 7.0 * PdfPageFormat.mm,
      'marginTop': 13.0 * PdfPageFormat.mm,
      'horizontalSpacing': 2.0 * PdfPageFormat.mm,
      'verticalSpacing': 0.0 * PdfPageFormat.mm,
      'paperSize': 'Carta (216 x 279 mm)',
      'paperType': 'Etiqueta adesiva para cartas e documentos',
      'totalLabels': 30,
      'orientation': 'Paisagem',
    },
    LabelPaperType.ecommerce100x150: {
      'width': 100 * PdfPageFormat.mm,
      'height': 150 * PdfPageFormat.mm,
      'columns': 1,
      'rows': 1,
      'marginLeft': 0.0,
      'marginTop': 0.0,
      'horizontalSpacing': 0.0,
      'verticalSpacing': 0.0,
      'paperSize': 'Personalizado (100 x 150 mm)',
      'paperType': 'Etiqueta adesiva para e-commerce',
      'totalLabels': 1,
      'orientation': 'Retrato',
    },
    LabelPaperType.pimaco6280: {
      'width': 66.7 * PdfPageFormat.mm,
      'height': 25.4 * PdfPageFormat.mm,
      'columns': 3,
      'rows': 10,
      'marginLeft': 7.0 * PdfPageFormat.mm,
      'marginTop': 13.0 * PdfPageFormat.mm,
      'horizontalSpacing': 2.0 * PdfPageFormat.mm,
      'verticalSpacing': 0.0 * PdfPageFormat.mm,
      'paperSize': 'A4 (210 x 297 mm)',
      'paperType': 'Pimaco 6280 - 30 etiquetas por folha',
      'totalLabels': 30,
      'orientation': 'Paisagem',
    },
    LabelPaperType.pimaco6181: {
      'width': 101.6 * PdfPageFormat.mm,
      'height': 33.9 * PdfPageFormat.mm,
      'columns': 2,
      'rows': 7,
      'marginLeft': 4.0 * PdfPageFormat.mm,
      'marginTop': 13.0 * PdfPageFormat.mm,
      'horizontalSpacing': 0.0 * PdfPageFormat.mm,
      'verticalSpacing': 0.0 * PdfPageFormat.mm,
      'paperSize': 'A4 (210 x 297 mm)',
      'paperType': 'Pimaco 6181 - 14 etiquetas por folha',
      'totalLabels': 14,
      'orientation': 'Paisagem',
    },
    LabelPaperType.pimaco6082: {
      'width': 44.0 * PdfPageFormat.mm,
      'height': 26.0 * PdfPageFormat.mm,
      'columns': 4,
      'rows': 10,
      'marginLeft': 8.0 * PdfPageFormat.mm,
      'marginTop': 13.0 * PdfPageFormat.mm,
      'horizontalSpacing': 2.0 * PdfPageFormat.mm,
      'verticalSpacing': 0.0 * PdfPageFormat.mm,
      'paperSize': 'A4 (210 x 297 mm)',
      'paperType': 'Pimaco 6082 - 40 etiquetas por folha',
      'totalLabels': 40,
      'orientation': 'Paisagem',
    },
    LabelPaperType.pimaco6180: {
      'width': 84.7 * PdfPageFormat.mm,
      'height': 101.6 * PdfPageFormat.mm,
      'columns': 2,
      'rows': 2,
      'marginLeft': 10.0 * PdfPageFormat.mm,
      'marginTop': 13.0 * PdfPageFormat.mm,
      'horizontalSpacing': 0.0 * PdfPageFormat.mm,
      'verticalSpacing': 0.0 * PdfPageFormat.mm,
      'paperSize': 'A4 (210 x 297 mm)',
      'paperType': 'Pimaco 6180 - 4 etiquetas por folha',
      'totalLabels': 4,
      'orientation': 'Retrato',
    },
    LabelPaperType.pimaco6080: {
      'width': 66.7 * PdfPageFormat.mm,
      'height': 25.4 * PdfPageFormat.mm,
      'columns': 3,
      'rows': 10,
      'marginLeft': 7.0 * PdfPageFormat.mm,
      'marginTop': 13.0 * PdfPageFormat.mm,
      'horizontalSpacing': 2.0 * PdfPageFormat.mm,
      'verticalSpacing': 0.0 * PdfPageFormat.mm,
      'paperSize': 'A4 (210 x 297 mm)',
      'paperType': 'Pimaco 6080 - 30 etiquetas por folha',
      'totalLabels': 30,
      'orientation': 'Paisagem',
    },
    LabelPaperType.a4Full: {
      'width': 210 * PdfPageFormat.mm,
      'height': 297 * PdfPageFormat.mm,
      'columns': 1,
      'rows': 1,
      'marginLeft': 0.0,
      'marginTop': 0.0,
      'horizontalSpacing': 0.0,
      'verticalSpacing': 0.0,
      'paperSize': 'A4 (210 x 297 mm)',
      'paperType': 'Página A4 inteira',
      'totalLabels': 1,
      'orientation': 'Retrato',
    },
    LabelPaperType.custom: {
      'width': 100 * PdfPageFormat.mm,
      'height': 50 * PdfPageFormat.mm,
      'columns': 1,
      'rows': 1,
      'marginLeft': 0.0,
      'marginTop': 0.0,
      'horizontalSpacing': 0.0,
      'verticalSpacing': 0.0,
      'paperSize': 'Personalizado',
      'paperType': 'Tamanho personalizado',
      'totalLabels': 1,
      'orientation': 'Personalizado',
    },
  };

  // Mapa de cores para PDF
  final Map<String, PdfColor> _labelColors = {
    'Branco': PdfColors.white,
    'Azul Claro': PdfColor(0.8, 0.9, 1.0),
    'Verde Claro': PdfColor(0.9, 1.0, 0.9),
    'Amarelo Claro': PdfColor(1.0, 1.0, 0.8),
    'Rosa Claro': PdfColor(1.0, 0.8, 0.9),
    'Cinza Claro': PdfColor(0.9, 0.9, 0.9),
  };

  // Calcular tamanho de fonte proporcional ao tamanho da etiqueta
  double _calculateFontSize(double labelHeight, double baseFontSize) {
    // Altura de referência para a qual os tamanhos de fonte foram definidos
    const double referenceHeight = 50.0 * PdfPageFormat.mm; // Altura de referência em pontos
    
    // Calcular o fator de escala
    double scaleFactor = labelHeight / referenceHeight;
    
    // Aplicar o fator de escala com limites mínimos e máximos
    double scaledFontSize = baseFontSize * scaleFactor;
    
    // Garantir que o tamanho da fonte não seja muito pequeno ou muito grande
    return scaledFontSize.clamp(6.0, baseFontSize * 1.5);
  }

  // Calcular tamanho do QR code proporcional ao tamanho da etiqueta
  double _calculateQrCodeSize(double labelHeight, double labelWidth) {
    // Usar o menor valor entre altura e largura para garantir que o QR code caiba
    double minDimension = labelHeight < labelWidth ? labelHeight : labelWidth;
    
    // Considerar o espaço disponível com margens
    double availableSpace = minDimension * 0.85; // Reservar 15% para margens
    
    // Limitar o tamanho máximo para garantir que caiba na etiqueta
    return availableSpace.clamp(10.0, 50.0 * PdfPageFormat.mm);
  }

  // Criar QR code como imagem para o PDF
  Future<pw.Widget> _createQrCodeImage(String data, double size) async {
    return pw.BarcodeWidget(
      barcode: pw.Barcode.qrCode(),
      data: data,
      width: size,
      height: size,
      color: PdfColors.black,
      drawText: false,
    );
  }

  // Criar código de barras como imagem para o PDF
  pw.Widget _createBarcodeWidget(String data, double width, double height, double fontSize) {
    // Garantir que a largura seja positiva
    final barcodeWidth = max(width, 10.0);
    
    return pw.BarcodeWidget(
      barcode: pw.Barcode.code128(),
      data: data,
      width: barcodeWidth,
      height: height,
      textStyle: pw.TextStyle(fontSize: fontSize),
      drawText: true,
    );
  }

  // Gerar documento PDF com etiquetas
  Future<Uint8List> generateLabels({
    required List<Box> boxes,
    required LabelPaperType paperType,
    required LabelFormat format,
    required bool includeQrCode,
    required bool includeBarcode,
    required bool includeBoxName,
    required bool includeLocation,
    required bool includeCategory,
    String labelColor = 'Branco',
    Map<String, dynamic>? customLabelConfig,
  }) async {
    try {
      _logService.info('Gerando etiquetas para ${boxes.length} caixas', category: 'label');
      
      // Verificar se há caixas para gerar etiquetas
      if (boxes.isEmpty) {
        throw Exception('Nenhuma caixa selecionada para gerar etiquetas');
      }
      
      // Obter configuração da etiqueta
      Map<String, dynamic> labelConfig = customLabelConfig ?? _labelConfigs[paperType]!;
      
      // Verificar se a configuração da etiqueta é válida
      if (labelConfig['width'] <= 0 || labelConfig['height'] <= 0) {
        throw Exception('Dimensões de etiqueta inválidas: largura=${labelConfig['width']}, altura=${labelConfig['height']}');
      }
      
      // Determinar orientação da página
      final bool isPortraitPage = labelConfig['orientation'] == 'Retrato';
      final PdfPageFormat pageFormat = isPortraitPage 
          ? PdfPageFormat.a4
          : PdfPageFormat.a4.landscape;
      
      // Criar documento PDF com configurações específicas
      final pdf = pw.Document(
        title: 'Etiquetas BoxMagic',
        author: 'BoxMagic',
        creator: 'BoxMagic App',
        subject: 'Etiquetas para caixas',
        keywords: 'etiqueta, caixa, boxmagic',
        producer: 'BoxMagic PDF Generator',
      );
      
      // Obter cor da etiqueta
      final backgroundColor = _labelColors[labelColor] ?? PdfColors.white;
      
      // Calcular número de etiquetas por página
      final int labelsPerPage = (labelConfig['columns'] as int) * (labelConfig['rows'] as int);
      
      // Calcular número de páginas necessárias
      final int totalPages = (boxes.length / labelsPerPage).ceil();
      
      // Calcular tamanhos de fonte baseados no tamanho da etiqueta
      final double labelArea = labelConfig['width'] * labelConfig['height'];
      final double titleFontSize = min(14.0, max(8.0, sqrt(labelArea) / 25));
      final double subtitleFontSize = min(10.0, max(6.0, sqrt(labelArea) / 30));
      final double idFontSize = min(12.0, max(7.0, sqrt(labelArea) / 28));
      
      // Determinar orientação da etiqueta
      final bool isPortraitLabel = labelConfig['height'] > labelConfig['width'];
      
      // Calcular tamanho do QR code baseado na orientação da etiqueta
      final double qrCodeSize = isPortraitLabel 
          ? min(labelConfig['width'] * 0.8, labelConfig['height'] * 0.3) 
          : min(labelConfig['width'] * 0.3, labelConfig['height'] * 0.8);
      
      // Pré-gerar QR codes para todas as caixas se necessário
      Map<int, pw.Widget> qrCodeWidgets = {};
      if (includeQrCode) {
        for (var box in boxes) {
          if (box.id != null) {
            try {
              final String qrData = 'BOX:${box.id}';
              final qrWidget = await _createQrCodeImage(qrData, qrCodeSize);
              qrCodeWidgets[box.id!] = qrWidget;
            } catch (e) {
              _logService.error('Erro ao gerar QR code para caixa ${box.id}', error: e, category: 'label');
              // Continuar com as outras caixas mesmo se uma falhar
            }
          }
        }
      }
      
      // Gerar páginas
      for (int pageIndex = 0; pageIndex < totalPages; pageIndex++) {
        // Criar página com formato correto
        pdf.addPage(
          pw.Page(
            pageFormat: pageFormat,
            build: (pw.Context context) {
              // Criar grid de etiquetas
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: List.generate(labelConfig['rows'] as int, (rowIndex) {
                  return pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: List.generate(labelConfig['columns'] as int, (colIndex) {
                      // Calcular índice da etiqueta
                      final int labelIndex = pageIndex * labelsPerPage + rowIndex * (labelConfig['columns'] as int) + colIndex;
                      
                      // Verificar se ainda há caixas para mostrar
                      if (labelIndex < boxes.length) {
                        // Obter caixa atual
                        final Box box = boxes[labelIndex];
                        
                        // Criar etiqueta
                        return pw.Padding(
                          padding: pw.EdgeInsets.only(
                            left: colIndex == 0 ? labelConfig['marginLeft'] : labelConfig['horizontalSpacing'],
                            top: rowIndex == 0 ? labelConfig['marginTop'] : labelConfig['verticalSpacing'],
                            right: colIndex == labelConfig['columns'] - 1 ? labelConfig['marginLeft'] : 0,
                            bottom: rowIndex == labelConfig['rows'] - 1 ? labelConfig['marginTop'] : 0,
                          ),
                          child: pw.Container(
                            width: labelConfig['width'],
                            height: labelConfig['height'],
                            decoration: pw.BoxDecoration(
                              color: backgroundColor,
                              border: pw.Border.all(color: PdfColors.grey300),
                            ),
                            padding: const pw.EdgeInsets.all(4),
                            child: _buildLabelContentSync(
                              box: box,
                              format: format,
                              includeQrCode: includeQrCode,
                              includeBarcode: includeBarcode,
                              includeBoxName: includeBoxName,
                              includeLocation: includeLocation,
                              includeCategory: includeCategory,
                              qrCodeWidget: includeQrCode && box.id != null ? qrCodeWidgets[box.id!] : null,
                              titleFontSize: titleFontSize,
                              subtitleFontSize: subtitleFontSize,
                              idFontSize: idFontSize,
                              labelWidth: labelConfig['width'],
                              labelHeight: labelConfig['height'],
                            ),
                          ),
                        );
                      } else {
                        // Espaço vazio para etiquetas sem caixa
                        return pw.Container(
                          width: labelConfig['width'],
                          height: labelConfig['height'],
                        );
                      }
                    }),
                  );
                }),
              );
            },
          ),
        );
      }
      
      // Gerar PDF
      return pdf.save();
    } catch (e) {
      _logService.error('Erro ao gerar etiquetas', error: e, category: 'label');
      rethrow;
    }
  }

  // Construir conteúdo da etiqueta (versão síncrona)
  pw.Widget _buildLabelContentSync({
    required Box box,
    required LabelFormat format,
    required bool includeQrCode,
    required bool includeBarcode,
    required bool includeBoxName,
    required bool includeLocation,
    required bool includeCategory,
    pw.Widget? qrCodeWidget,
    required double titleFontSize,
    required double subtitleFontSize,
    required double idFontSize,
    required double labelWidth,
    required double labelHeight,
  }) {
    // Determinar orientação da etiqueta
    final bool isPortrait = labelHeight > labelWidth;
    
    // Calcular tamanho do QR code baseado na orientação
    final double qrCodeSize = isPortrait 
        ? min(labelWidth * 0.8, labelHeight * 0.3) 
        : min(labelWidth * 0.3, labelHeight * 0.8);
    
    // Calcular tamanho do código de barras baseado na orientação
    final double barcodeWidth = isPortrait 
        ? labelWidth * 0.9 
        : labelWidth * 0.6;
    final double barcodeHeight = isPortrait 
        ? 20.0 
        : 30.0;
    
    // Criar código de barras se necessário
    pw.Widget? barcodeWidget;
    if (includeBarcode && box.id != null) {
      barcodeWidget = _createBarcodeWidget(box.id.toString(), barcodeWidth, barcodeHeight, idFontSize);
    }
    
    // Construir layout da etiqueta de acordo com o formato e orientação
    if (isPortrait) {
      // Layout para etiquetas em modo retrato (altura > largura)
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        mainAxisAlignment: pw.MainAxisAlignment.start,
        children: [
          if (includeBoxName && box.name.isNotEmpty)
            pw.Container(
              width: labelWidth,
              child: pw.Text(
                box.name,
                style: pw.TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
                maxLines: 2,
                overflow: pw.TextOverflow.clip,
              ),
            ),
          
          pw.SizedBox(height: 4),
          
          if (includeLocation && box.location?.isNotEmpty == true)
            pw.Container(
              width: labelWidth,
              child: pw.Text(
                'Local: ${box.location}',
                style: pw.TextStyle(
                  fontSize: subtitleFontSize,
                  fontStyle: pw.FontStyle.italic,
                ),
                textAlign: pw.TextAlign.center,
                maxLines: 1,
                overflow: pw.TextOverflow.clip,
              ),
            ),
            
          if (includeCategory && box.category.isNotEmpty)
            pw.Container(
              width: labelWidth,
              child: pw.Text(
                'Categoria: ${box.category}',
                style: pw.TextStyle(
                  fontSize: subtitleFontSize,
                  fontStyle: pw.FontStyle.italic,
                ),
                textAlign: pw.TextAlign.center,
                maxLines: 1,
                overflow: pw.TextOverflow.clip,
              ),
            ),
          
          pw.Spacer(),
          
          if (includeQrCode && qrCodeWidget != null)
            pw.Container(
              width: qrCodeSize,
              height: qrCodeSize,
              child: qrCodeWidget,
            ),
          
          pw.SizedBox(height: 4),
          
          if (includeBarcode && barcodeWidget != null)
            pw.Container(
              width: barcodeWidth,
              child: barcodeWidget,
            ),
          
          if (!includeBarcode && box.id != null)
            pw.Text(
              'ID: ${box.id}',
              style: pw.TextStyle(
                fontSize: idFontSize,
                fontWeight: pw.FontWeight.bold,
              ),
              textAlign: pw.TextAlign.center,
            ),
        ],
      );
    } else {
      // Layout para etiquetas em modo paisagem (largura > altura)
      return pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (includeQrCode && qrCodeWidget != null)
            pw.Container(
              width: qrCodeSize,
              height: qrCodeSize,
              child: qrCodeWidget,
            ),
          
          pw.SizedBox(width: 8),
          
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                if (includeBoxName && box.name.isNotEmpty)
                  pw.Text(
                    box.name,
                    style: pw.TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: pw.TextOverflow.clip,
                  ),
                
                pw.SizedBox(height: 2),
                
                if (includeLocation && box.location?.isNotEmpty == true)
                  pw.Text(
                    'Local: ${box.location}',
                    style: pw.TextStyle(
                      fontSize: subtitleFontSize,
                      fontStyle: pw.FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: pw.TextOverflow.clip,
                  ),
                  
                if (includeCategory && box.category.isNotEmpty)
                  pw.Text(
                    'Categoria: ${box.category}',
                    style: pw.TextStyle(
                      fontSize: subtitleFontSize,
                      fontStyle: pw.FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: pw.TextOverflow.clip,
                  ),
                
                pw.Spacer(),
                
                if (includeBarcode && barcodeWidget != null)
                  barcodeWidget,
                
                if (!includeBarcode && box.id != null)
                  pw.Text(
                    'ID: ${box.id}',
                    style: pw.TextStyle(
                      fontSize: idFontSize,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    }
  }

  // Imprimir etiquetas
  Future<void> printLabels({
    required List<Box> boxes,
    required LabelPaperType paperType,
    required LabelFormat format,
    required bool includeQrCode,
    required bool includeBarcode,
    required bool includeBoxName,
    required bool includeLocation,
    required bool includeCategory,
    required String labelColor,
    required PrinterModel printerModel,
  }) async {
    try {
      _logService.info('Abrindo diálogo de impressão de etiquetas', category: 'label');
      
      // Obter configuração da etiqueta
      final labelConfig = _labelConfigs[paperType]!;
      
      // Gerar etiquetas
      final pdfData = await generateLabels(
        boxes: boxes,
        paperType: paperType,
        format: format,
        includeQrCode: includeQrCode,
        includeBarcode: includeBarcode,
        includeBoxName: includeBoxName,
        includeLocation: includeLocation,
        includeCategory: includeCategory,
        labelColor: labelColor,
      );
      
      // Determinar orientação da página
      final bool isPortraitPage = labelConfig['orientation'] == 'Retrato';
      
      // Configurar formato de página com base no tipo de papel
      PdfPageFormat pageFormat;
      
      // Verificar se é etiqueta para carta
      if (paperType == LabelPaperType.carta25x67) {
        // Formato Carta (Letter) - 215.9 x 279.4 mm
        pageFormat = isPortraitPage
            ? PdfPageFormat(215.9 * PdfPageFormat.mm, 279.4 * PdfPageFormat.mm, marginTop: 0, marginBottom: 0, marginLeft: 0, marginRight: 0)
            : PdfPageFormat(279.4 * PdfPageFormat.mm, 215.9 * PdfPageFormat.mm, marginTop: 0, marginBottom: 0, marginLeft: 0, marginRight: 0);
      } else if (paperType == LabelPaperType.ecommerce100x150) {
        // Formato personalizado para etiqueta de e-commerce
        pageFormat = PdfPageFormat(100 * PdfPageFormat.mm, 150 * PdfPageFormat.mm, marginTop: 0, marginBottom: 0, marginLeft: 0, marginRight: 0);
      } else {
        // Formato A4 padrão
        pageFormat = isPortraitPage
            ? PdfPageFormat.a4.copyWith(marginTop: 0, marginBottom: 0, marginLeft: 0, marginRight: 0)
            : PdfPageFormat.a4.landscape.copyWith(marginTop: 0, marginBottom: 0, marginLeft: 0, marginRight: 0);
      }
      
      // Configurações específicas para cada modelo de impressora
      switch (printerModel) {
        case PrinterModel.zebraZD220:
          // Configurações específicas para Zebra ZD220
          pageFormat = pageFormat.copyWith(
            marginTop: 0,
            marginBottom: 0,
            marginLeft: 0,
            marginRight: 0,
          );
          break;
        case PrinterModel.argoxOS214Plus:
          // Configurações específicas para Argox OS 214 Plus
          pageFormat = pageFormat.copyWith(
            marginTop: 0,
            marginBottom: 0,
            marginLeft: 0,
            marginRight: 0,
          );
          break;
        case PrinterModel.elginL42Pro:
          // Configurações específicas para Elgin L42 Pro/L42DT
          pageFormat = pageFormat.copyWith(
            marginTop: 0,
            marginBottom: 0,
            marginLeft: 0,
            marginRight: 0,
          );
          break;
        case PrinterModel.generic:
          break;
      }
      
      // Abrir diálogo de impressão
      await Printing.layoutPdf(
        onLayout: (_) async => pdfData,
        name: 'Etiquetas_${DateTime.now().millisecondsSinceEpoch}',
        format: pageFormat,
        dynamicLayout: true,
        usePrinterSettings: true,
      );
    } catch (e) {
      _logService.error('Erro ao imprimir etiquetas', error: e, category: 'label');
      rethrow;
    }
  }
  
  // Compartilhar PDF de etiquetas
  Future<void> sharePdf({
    required List<Box> boxes,
    required LabelPaperType paperType,
    required LabelFormat format,
    required bool includeQrCode,
    required bool includeBarcode,
    required bool includeBoxName,
    required bool includeLocation,
    required bool includeCategory,
    required String labelColor,
    required PrinterModel printerModel,
  }) async {
    try {
      _logService.info('Compartilhando PDF de etiquetas', category: 'label');
      
      // Obter configuração da etiqueta
      final labelConfig = _labelConfigs[paperType]!;
      
      // Gerar etiquetas
      final pdfData = await generateLabels(
        boxes: boxes,
        paperType: paperType,
        format: format,
        includeQrCode: includeQrCode,
        includeBarcode: includeBarcode,
        includeBoxName: includeBoxName,
        includeLocation: includeLocation,
        includeCategory: includeCategory,
        labelColor: labelColor,
      );
      
      // Nome do arquivo com informações sobre o tipo de etiqueta
      final String paperTypeInfo = labelConfig['paperType'].toString().split(' - ').first;
      final String fileName = 'Etiquetas_${paperTypeInfo}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      
      // Compartilhar PDF
      await Printing.sharePdf(
        bytes: pdfData,
        filename: fileName,
      );
    } catch (e) {
      _logService.error('Erro ao compartilhar PDF de etiquetas', error: e, category: 'label');
      rethrow;
    }
  }
}
