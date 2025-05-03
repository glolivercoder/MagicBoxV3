# Implementação de Códigos de Barras em Etiquetas

## Visão Geral

O MagicBoxV2 agora oferece a opção de gerar etiquetas com códigos de barras para os IDs das caixas, otimizando o espaço nas etiquetas e permitindo a leitura rápida por scanners convencionais, além dos QR codes.

## Tipos de Códigos de Barras Suportados

1. **Code 128**
   - Alta densidade de dados
   - Suporte a caracteres alfanuméricos
   - Excelente para IDs de caixas

2. **Code 39**
   - Amplamente utilizado
   - Fácil leitura por scanners básicos
   - Bom para IDs simples

3. **EAN-13/UPC-A**
   - Padrão para produtos comerciais
   - Compatível com scanners de supermercados
   - Limitado a dígitos numéricos

## Implementação Técnica

### 1. Modelo de Dados Atualizado

```dart
enum BarcodeType {
  qrCode,    // QR Code padrão
  code128,   // Code 128 (alfanumérico denso)
  code39,    // Code 39 (alfanumérico básico)
  ean13,     // EAN-13 (numérico, 13 dígitos)
  none,      // Sem código de barras
}

class LabelFormat {
  final String name;
  final bool showId;
  final bool showName;
  final bool showItems;
  final BarcodeType barcodeType;
  final bool optimizeSpace;
  
  const LabelFormat({
    required this.name,
    required this.showId,
    this.showName = false,
    this.showItems = false,
    this.barcodeType = BarcodeType.qrCode,
    this.optimizeSpace = false,
  });
  
  // Formatos predefinidos
  static const LabelFormat idWithQrCode = LabelFormat(
    name: 'ID com QR Code',
    showId: true,
    barcodeType: BarcodeType.qrCode,
  );
  
  static const LabelFormat idWithBarcode = LabelFormat(
    name: 'ID com Código de Barras',
    showId: true,
    barcodeType: BarcodeType.code128,
    optimizeSpace: true,
  );
  
  static const LabelFormat nameWithQrCode = LabelFormat(
    name: 'Nome com QR Code',
    showId: true,
    showName: true,
    barcodeType: BarcodeType.qrCode,
  );
  
  static const LabelFormat nameWithBarcode = LabelFormat(
    name: 'Nome com Código de Barras',
    showId: true,
    showName: true,
    barcodeType: BarcodeType.code128,
    optimizeSpace: true,
  );
  
  static const LabelFormat fullWithQrCode = LabelFormat(
    name: 'Completa com QR Code',
    showId: true,
    showName: true,
    showItems: true,
    barcodeType: BarcodeType.qrCode,
  );
  
  static const LabelFormat fullWithBarcode = LabelFormat(
    name: 'Completa com Código de Barras',
    showId: true,
    showName: true,
    showItems: true,
    barcodeType: BarcodeType.code128,
    optimizeSpace: true,
  );
  
  static const LabelFormat textOnly = LabelFormat(
    name: 'Apenas Texto',
    showId: true,
    showName: true,
    barcodeType: BarcodeType.none,
    optimizeSpace: true,
  );
  
  // Lista de todos os formatos predefinidos
  static List<LabelFormat> get predefinedFormats => [
    idWithQrCode,
    idWithBarcode,
    nameWithQrCode,
    nameWithBarcode,
    fullWithQrCode,
    fullWithBarcode,
    textOnly,
  ];
}
```

### 2. Geração de Códigos de Barras

```dart
import 'package:barcode/barcode.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class BarcodeGenerator {
  // Gerar código de barras para PDF
  static pw.Widget generateBarcode({
    required String data,
    required BarcodeType type,
    required double width,
    required double height,
    PdfColor? color,
  }) {
    color ??= PdfColors.black;
    
    switch (type) {
      case BarcodeType.qrCode:
        return pw.BarcodeWidget(
          data: data,
          barcode: Barcode.qrCode(),
          width: width,
          height: height,
          color: color,
        );
        
      case BarcodeType.code128:
        return pw.BarcodeWidget(
          data: data,
          barcode: Barcode.code128(),
          width: width,
          height: height * 0.3, // Altura reduzida para economizar espaço
          drawText: true,
          color: color,
        );
        
      case BarcodeType.code39:
        return pw.BarcodeWidget(
          data: data,
          barcode: Barcode.code39(),
          width: width,
          height: height * 0.3, // Altura reduzida para economizar espaço
          drawText: true,
          color: color,
        );
        
      case BarcodeType.ean13:
        // Garantir que temos exatamente 12 dígitos (o 13º é calculado)
        final numericData = data.replaceAll(RegExp(r'[^0-9]'), '');
        final paddedData = numericData.padRight(12, '0').substring(0, 12);
        
        return pw.BarcodeWidget(
          data: paddedData,
          barcode: Barcode.ean13(),
          width: width,
          height: height * 0.3, // Altura reduzida para economizar espaço
          drawText: true,
          color: color,
        );
        
      case BarcodeType.none:
      default:
        // Retornar apenas o texto do ID
        return pw.Text(
          data,
          style: pw.TextStyle(
            font: pw.Font.helveticaBold(),
            fontSize: 14,
            color: color,
          ),
        );
    }
  }
  
  // Gerar código de barras para SVG
  static String generateBarcodeSvg({
    required String data,
    required BarcodeType type,
    required double width,
    required double height,
    String color = '#000000',
  }) {
    switch (type) {
      case BarcodeType.qrCode:
        return Barcode.qrCode().toSvg(
          data,
          width: width,
          height: height,
          color: color,
        );
        
      case BarcodeType.code128:
        return Barcode.code128().toSvg(
          data,
          width: width,
          height: height * 0.3,
          drawText: true,
          color: color,
        );
        
      case BarcodeType.code39:
        return Barcode.code39().toSvg(
          data,
          width: width,
          height: height * 0.3,
          drawText: true,
          color: color,
        );
        
      case BarcodeType.ean13:
        final numericData = data.replaceAll(RegExp(r'[^0-9]'), '');
        final paddedData = numericData.padRight(12, '0').substring(0, 12);
        
        return Barcode.ean13().toSvg(
          paddedData,
          width: width,
          height: height * 0.3,
          drawText: true,
          color: color,
        );
        
      case BarcodeType.none:
      default:
        // Retornar um elemento SVG de texto
        return '<text x="${width/2}" y="${height/2}" '
            'text-anchor="middle" dominant-baseline="middle" '
            'font-family="Helvetica" font-weight="bold" font-size="14" '
            'fill="$color">$data</text>';
    }
  }
  
  // Calcular espaço necessário para o código de barras
  static double calculateBarcodeHeight(BarcodeType type, double labelHeight) {
    switch (type) {
      case BarcodeType.qrCode:
        return labelHeight * 0.6; // QR code ocupa 60% da altura
      case BarcodeType.code128:
      case BarcodeType.code39:
      case BarcodeType.ean13:
        return labelHeight * 0.25; // Códigos de barras lineares ocupam 25%
      case BarcodeType.none:
      default:
        return labelHeight * 0.15; // Apenas texto ocupa 15%
    }
  }
}
```

### 3. Integração no Serviço de Impressão

```dart
class LabelPrintingService {
  // Método para gerar etiqueta com código de barras otimizado
  pw.Widget _buildLabelContent(
    Box box,
    List<Item> items,
    LabelFormat format,
    double width,
    double height,
  ) {
    // Calcular espaços disponíveis
    final barcodeHeight = BarcodeGenerator.calculateBarcodeHeight(
      format.barcodeType, 
      height,
    );
    
    final remainingHeight = height - barcodeHeight - 20; // 20pt para margens
    
    return pw.Container(
      width: width,
      height: height,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // ID e Nome (se habilitado)
          pw.Container(
            height: format.showName ? remainingHeight * 0.3 : remainingHeight * 0.2,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  box.formattedId,
                  style: pw.TextStyle(
                    font: pw.Font.helveticaBold(),
                    fontSize: format.optimizeSpace ? 10 : 12,
                  ),
                ),
                if (format.showName) pw.SizedBox(height: 2),
                if (format.showName)
                  pw.Text(
                    box.name,
                    style: pw.TextStyle(
                      font: pw.Font.helvetica(),
                      fontSize: format.optimizeSpace ? 9 : 10,
                    ),
                    maxLines: 1,
                    overflow: pw.TextOverflow.clip,
                  ),
              ],
            ),
          ),
          
          // Código de barras
          if (format.barcodeType != BarcodeType.none)
            pw.Center(
              child: BarcodeGenerator.generateBarcode(
                data: box.formattedId,
                type: format.barcodeType,
                width: width - 16, // Margem de 8pt de cada lado
                height: barcodeHeight,
              ),
            ),
          
          // Lista de itens (se habilitado)
          if (format.showItems) pw.SizedBox(height: 4),
          if (format.showItems)
            pw.Expanded(
              child: pw.ListView(
                children: items
                    .take(format.optimizeSpace ? 3 : 5) // Limitar quantidade
                    .map((item) => pw.Text(
                          '• ${item.name}',
                          style: pw.TextStyle(
                            font: pw.Font.helvetica(),
                            fontSize: format.optimizeSpace ? 7 : 8,
                          ),
                          maxLines: 1,
                          overflow: pw.TextOverflow.clip,
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}
```

### 4. Interface de Seleção de Formato

```dart
class LabelFormatSelector extends StatelessWidget {
  final LabelFormat selectedFormat;
  final Function(LabelFormat) onFormatSelected;
  
  const LabelFormatSelector({
    Key? key,
    required this.selectedFormat,
    required this.onFormatSelected,
  }) : super(key: key);
  
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
              'Formato da Etiqueta',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            
            // Lista de formatos predefinidos
            ...LabelFormat.predefinedFormats.map((format) => 
              RadioListTile<LabelFormat>(
                title: Text(format.name),
                subtitle: _buildFormatDescription(format),
                value: format,
                groupValue: selectedFormat,
                onChanged: (value) {
                  if (value != null) {
                    onFormatSelected(value);
                  }
                },
                secondary: _buildFormatIcon(format),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFormatDescription(LabelFormat format) {
    final List<String> features = [];
    
    if (format.showId) features.add('ID');
    if (format.showName) features.add('Nome');
    if (format.showItems) features.add('Itens');
    
    String barcodeType = '';
    switch (format.barcodeType) {
      case BarcodeType.qrCode:
        barcodeType = 'QR Code';
        break;
      case BarcodeType.code128:
        barcodeType = 'Code 128';
        break;
      case BarcodeType.code39:
        barcodeType = 'Code 39';
        break;
      case BarcodeType.ean13:
        barcodeType = 'EAN-13';
        break;
      case BarcodeType.none:
        barcodeType = 'Sem código';
        break;
    }
    
    features.add(barcodeType);
    if (format.optimizeSpace) features.add('Espaço otimizado');
    
    return Text(features.join(' • '));
  }
  
  Widget _buildFormatIcon(LabelFormat format) {
    IconData iconData;
    
    switch (format.barcodeType) {
      case BarcodeType.qrCode:
        iconData = Icons.qr_code;
        break;
      case BarcodeType.code128:
      case BarcodeType.code39:
      case BarcodeType.ean13:
        iconData = Icons.bar_chart;
        break;
      case BarcodeType.none:
      default:
        iconData = Icons.text_fields;
        break;
    }
    
    return Icon(iconData);
  }
}
```

## Vantagens dos Códigos de Barras Lineares

1. **Economia de Espaço**
   - Ocupam menos altura que QR codes
   - Permitem incluir mais informações na etiqueta
   - Ideal para etiquetas pequenas

2. **Compatibilidade**
   - Lidos por scanners básicos e aplicativos de smartphone
   - Não requerem câmeras de alta resolução
   - Funcionam bem mesmo em impressões de baixa qualidade

3. **Versatilidade**
   - Diferentes tipos para diferentes necessidades
   - Code 128 para IDs alfanuméricos
   - EAN-13 para integração com sistemas de varejo

## Comparação de Formatos

| Formato | Tipo de Código | Espaço Ocupado | Melhor Uso |
|---------|----------------|----------------|------------|
| QR Code | 2D Matricial | Alto (quadrado) | Muitos dados, leitura por smartphone |
| Code 128 | 1D Linear | Baixo (retangular) | IDs alfanuméricos, economia de espaço |
| Code 39 | 1D Linear | Médio (retangular) | Compatibilidade com scanners antigos |
| EAN-13 | 1D Linear | Baixo (retangular) | Integração com sistemas comerciais |
| Sem código | Texto | Mínimo | Máxima economia de espaço |

## Considerações de Implementação

1. **Qualidade de Impressão**
   - Códigos de barras lineares exigem boa resolução horizontal
   - Recomendado mínimo de 300 DPI para impressão

2. **Tamanho Mínimo**
   - Altura mínima recomendada: 10mm para códigos lineares
   - Largura mínima: dependente do número de caracteres

3. **Contraste**
   - Alto contraste entre barras e fundo é essencial
   - Evitar cores que não ofereçam contraste suficiente
