import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/box.dart';
import '../services/log_service.dart';
import '../services/orm_service.dart';
import '../services/label_printing_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class BarcodeGeneratorScreen extends StatefulWidget {
  final Box? box;
  final List<Box>? boxes;

  const BarcodeGeneratorScreen({
    Key? key,
    this.box,
    this.boxes,
  }) : super(key: key);

  @override
  _BarcodeGeneratorScreenState createState() => _BarcodeGeneratorScreenState();
}

class _BarcodeGeneratorScreenState extends State<BarcodeGeneratorScreen> {
  final LogService _logService = LogService();
  final OrmService _ormService = OrmService();
  final LabelPrintingService _labelPrintingService = LabelPrintingService();
  
  List<Box> _selectedBoxes = [];
  bool _isLoading = false;
  bool _includeQrCode = true;
  bool _includeBarcode = true;
  bool _includeBoxName = true;
  bool _includeLocation = true;
  bool _includeCategory = false;
  String _selectedPrinterModel = 'Impressora genérica';
  String _selectedLabelSize = 'Carta 25,4 x 66,7mm (30 por folha)';
  String _selectedPimacoModel = 'Pimaco 6280';
  
  // Mapa de tamanhos de etiqueta
  final Map<String, LabelPaperType> _labelSizeTypes = {
    'Carta 25,4 x 66,7mm (30 por folha)': LabelPaperType.carta25x67,
    'E-commerce 100x150mm': LabelPaperType.ecommerce100x150,
    'Pimaco 6280': LabelPaperType.pimaco6280,
    'Pimaco 6181': LabelPaperType.pimaco6181,
    'Pimaco 6082': LabelPaperType.pimaco6082,
    'Pimaco 6080': LabelPaperType.pimaco6080,
    'Pimaco 6180': LabelPaperType.pimaco6180,
    'Página A4 inteira': LabelPaperType.a4Full,
    'Personalizado': LabelPaperType.custom,
  };

  // Mapa de modelos de impressora
  final Map<String, PrinterModel> _printerModels = {
    'Zebra ZD220': PrinterModel.zebraZD220,
    'Argox OS 214 Plus': PrinterModel.argoxOS214Plus,
    'Elgin L42 Pro/L42DT': PrinterModel.elginL42Pro,
    'Impressora genérica': PrinterModel.generic,
  };
  
  @override
  void initState() {
    super.initState();
    _initializeBoxes();
  }

  Future<void> _initializeBoxes() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      if (widget.box != null) {
        // Se uma caixa específica foi passada, usar apenas ela
        _selectedBoxes = [widget.box!];
      } else if (widget.boxes != null && widget.boxes!.isNotEmpty) {
        // Se uma lista de caixas foi passada, usar todas
        _selectedBoxes = List.from(widget.boxes!);
      } else {
        // Caso contrário, carregar todas as caixas do banco de dados
        final boxes = await _ormService.getAllBoxes();
        setState(() {
          _selectedBoxes = boxes;
        });
      }
    } catch (e) {
      _logService.error('Erro ao carregar caixas', error: e, category: 'barcode_generator');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Compartilhar PDF de etiquetas
  Future<void> _shareLabels() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Verificar se há caixas selecionadas
      if (_selectedBoxes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nenhuma caixa selecionada para gerar etiquetas'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      _logService.info('Compartilhando PDF de etiquetas', category: 'barcode_generator');
      
      // Obter tipo de etiqueta selecionado
      final labelType = _labelSizeTypes[_selectedLabelSize]!;
      
      // Obter modelo de impressora selecionado
      final printerModel = _printerModels[_selectedPrinterModel]!;
      
      // Compartilhar PDF
      await _labelPrintingService.sharePdf(
        boxes: _selectedBoxes,
        paperType: labelType,
        includeQrCode: _includeQrCode,
        includeBarcode: _includeBarcode,
        includeBoxName: _includeBoxName,
        includeLocation: _includeLocation,
        includeCategory: _includeCategory,
        printerModel: printerModel,
      );
    } catch (e) {
      _logService.error('Erro ao compartilhar PDF de etiquetas', error: e, category: 'barcode_generator');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao compartilhar PDF: ${e.toString()}'),
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
  
  // Imprimir etiquetas
  Future<void> _printLabels() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Verificar se há caixas selecionadas
      if (_selectedBoxes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nenhuma caixa selecionada para gerar etiquetas'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      _logService.info('Abrindo diálogo de impressão de etiquetas', category: 'barcode_generator');
      
      // Obter tipo de etiqueta selecionado
      final labelType = _labelSizeTypes[_selectedLabelSize]!;
      
      // Obter modelo de impressora selecionado
      final printerModel = _printerModels[_selectedPrinterModel]!;
      
      // Imprimir etiquetas
      await _labelPrintingService.printLabels(
        boxes: _selectedBoxes,
        paperType: labelType,
        includeQrCode: _includeQrCode,
        includeBarcode: _includeBarcode,
        includeBoxName: _includeBoxName,
        includeLocation: _includeLocation,
        includeCategory: _includeCategory,
        printerModel: printerModel,
      );
    } catch (e) {
      _logService.error('Erro ao imprimir etiquetas', error: e, category: 'barcode_generator');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao imprimir etiquetas: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
        title: const Text('Gerador de Etiquetas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt),
            tooltip: 'Salvar PDF',
            onPressed: _isLoading ? null : _shareLabels,
          ),
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Imprimir',
            onPressed: _isLoading ? null : _printLabels,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Gerando etiquetas...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabeçalho
                  const Text(
                    'Gere etiquetas com códigos de barras e QR codes para suas caixas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Configurações de etiqueta
                  const Text(
                    'Configurações de Etiqueta',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Formato de etiqueta
                  const Text(
                    'Formato da etiqueta:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Formato da Etiqueta',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedLabelSize,
                    items: _labelSizeTypes.keys.map((size) {
                      return DropdownMenuItem<String>(
                        value: size,
                        child: Text(size),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedLabelSize = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  // Informações detalhadas sobre a etiqueta selecionada
                  Builder(
                    builder: (context) {
                      final labelType = _labelSizeTypes[_selectedLabelSize]!;
                      final labelConfig = _labelPrintingService.getLabelConfig(labelType);
                      
                      if (labelConfig != null) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Informações da Etiqueta',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tipo de papel: ${labelConfig['paperSize']}',
                                style: const TextStyle(fontSize: 13),
                              ),
                              Text(
                                'Modelo: ${labelConfig['paperType']}',
                                style: const TextStyle(fontSize: 13),
                              ),
                              Text(
                                'Dimensões: ${labelConfig['width'] / PdfPageFormat.mm}mm x ${labelConfig['height'] / PdfPageFormat.mm}mm',
                                style: const TextStyle(fontSize: 13),
                              ),
                              Text(
                                'Orientação: ${labelConfig['orientation']}',
                                style: const TextStyle(fontSize: 13),
                              ),
                              Text(
                                'Etiquetas por folha: ${labelConfig['totalLabels']}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  if (_selectedLabelSize == 'Carta 25,4 x 66,7mm (30 por folha)')
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Importante: Configure o formato Carta (21,6 x 27,9 cm) na impressão',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  
                  // Modelo de impressora
                  const Text(
                    'Modelo de Impressora:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Modelo de Impressora',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedPrinterModel,
                    items: _printerModels.keys.map((model) {
                      return DropdownMenuItem<String>(
                        value: model,
                        child: Text(model),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPrinterModel = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Opções de conteúdo
                  const Text(
                    'Conteúdo da etiqueta:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Códigos de identificação:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: CheckboxListTile(
                                title: const Row(
                                  children: [
                                    Icon(Icons.qr_code, size: 20),
                                    SizedBox(width: 8),
                                    Text('QR Code'),
                                  ],
                                ),
                                value: _includeQrCode,
                                onChanged: (selected) {
                                  setState(() {
                                    _includeQrCode = selected!;
                                  });
                                },
                                dense: true,
                                controlAffinity: ListTileControlAffinity.leading,
                              ),
                            ),
                            Expanded(
                              child: CheckboxListTile(
                                title: const Row(
                                  children: [
                                    Icon(Icons.bar_chart, size: 20),
                                    SizedBox(width: 8),
                                    Text('Código de Barras'),
                                  ],
                                ),
                                value: _includeBarcode,
                                onChanged: (selected) {
                                  setState(() {
                                    _includeBarcode = selected!;
                                  });
                                },
                                dense: true,
                                controlAffinity: ListTileControlAffinity.leading,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Opções de informações
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informações adicionais:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            FilterChip(
                              label: const Text('Nome da Caixa'),
                              selected: _includeBoxName,
                              onSelected: (selected) {
                                setState(() {
                                  _includeBoxName = selected;
                                });
                              },
                            ),
                            FilterChip(
                              label: const Text('Localização'),
                              selected: _includeLocation,
                              onSelected: (selected) {
                                setState(() {
                                  _includeLocation = selected;
                                });
                              },
                            ),
                            FilterChip(
                              label: const Text('Categoria'),
                              selected: _includeCategory,
                              onSelected: (selected) {
                                setState(() {
                                  _includeCategory = selected;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Lista de caixas selecionadas
                  const Text(
                    'Caixas Selecionadas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  if (_selectedBoxes.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Nenhuma caixa selecionada',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _selectedBoxes.length,
                      itemBuilder: (context, index) {
                        final box = _selectedBoxes[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          child: ListTile(
                            title: Text(box.name),
                            subtitle: Text('ID: ${box.id}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () {
                                setState(() {
                                  _selectedBoxes.removeAt(index);
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Botões de ação
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _selectedBoxes.isEmpty ? null : _shareLabels,
                        icon: const Icon(Icons.save_alt),
                        label: const Text('Salvar PDF'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                      
                      ElevatedButton.icon(
                        onPressed: _selectedBoxes.isEmpty ? null : _printLabels,
                        icon: const Icon(Icons.print),
                        label: const Text('Imprimir'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Visualização de exemplo
                  const Text(
                    'Exemplo de Etiqueta',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Builder(
                    builder: (context) {
                      final labelType = _labelSizeTypes[_selectedLabelSize]!;
                      final labelConfig = _labelPrintingService.getLabelConfig(labelType);
                      
                      if (labelConfig == null) {
                        return const SizedBox.shrink();
                      }
                      
                      // Calcular proporção para o exemplo
                      final double labelWidth = labelConfig['width'] / PdfPageFormat.mm;
                      final double labelHeight = labelConfig['height'] / PdfPageFormat.mm;
                      final bool isPortrait = labelHeight > labelWidth;
                      
                      // Definir tamanho máximo do container de exemplo
                      final double maxWidth = 280.0;
                      final double maxHeight = 150.0;
                      
                      // Calcular escala para manter a proporção
                      final double widthRatio = maxWidth / labelWidth;
                      final double heightRatio = maxHeight / labelHeight;
                      final double scale = min(widthRatio, heightRatio);
                      
                      // Calcular dimensões finais do exemplo
                      final double exampleWidth = labelWidth * scale;
                      final double exampleHeight = labelHeight * scale;
                      
                      return Center(
                        child: Container(
                          width: exampleWidth,
                          height: exampleHeight,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                            color: Colors.white,
                          ),
                          padding: const EdgeInsets.all(8),
                          child: isPortrait
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (_includeBoxName)
                                      const Text(
                                        'Nome da Caixa',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    
                                    const SizedBox(height: 4),
                                    
                                    if (_includeLocation)
                                      const Text(
                                        'Local: Escritório',
                                        style: TextStyle(fontSize: 10),
                                        textAlign: TextAlign.center,
                                      ),
                                    
                                    if (_includeCategory)
                                      const Text(
                                        'Categoria: Documentos',
                                        style: TextStyle(fontSize: 10),
                                        textAlign: TextAlign.center,
                                      ),
                                    
                                    const Spacer(),
                                    
                                    if (_includeQrCode)
                                      QrImageView(
                                        data: 'BOX:1234',
                                        size: min(exampleWidth * 0.6, exampleHeight * 0.3),
                                        version: QrVersions.auto,
                                      ),
                                    
                                    const SizedBox(height: 4),
                                    
                                    if (_includeBarcode)
                                      Container(
                                        width: exampleWidth * 0.8,
                                        height: exampleHeight * 0.15,
                                        color: Colors.grey[300],
                                        child: const Center(
                                          child: Text(
                                            'Código de Barras',
                                            style: TextStyle(fontSize: 8),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    
                                    const SizedBox(height: 4),
                                    
                                    const Text(
                                      'ID: 1234',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  ],
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    if (_includeQrCode)
                                      QrImageView(
                                        data: 'BOX:1234',
                                        size: min(exampleWidth * 0.3, exampleHeight * 0.8),
                                        version: QrVersions.auto,
                                      ),
                                    
                                    const SizedBox(width: 8),
                                    
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          if (_includeBoxName)
                                            const Text(
                                              'Nome da Caixa',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          
                                          const SizedBox(height: 2),
                                          
                                          if (_includeLocation)
                                            const Text(
                                              'Local: Escritório',
                                              style: TextStyle(fontSize: 10),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          
                                          if (_includeCategory)
                                            const Text(
                                              'Categoria: Documentos',
                                              style: TextStyle(fontSize: 10),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          
                                          const SizedBox(height: 2),
                                          
                                          const Text(
                                            'ID: 1234',
                                            style: TextStyle(fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    const SizedBox(width: 8),
                                    
                                    if (_includeBarcode)
                                      Container(
                                        width: exampleWidth * 0.3,
                                        height: exampleHeight * 0.5,
                                        color: Colors.grey[300],
                                        child: const Center(
                                          child: Text(
                                            'Código de Barras',
                                            style: TextStyle(fontSize: 8),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
