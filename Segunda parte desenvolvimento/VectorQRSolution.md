# Solução de QR Codes Vetoriais para MagicBoxV2

## Problema Atual

O formato SVG atual para exportação de etiquetas apresenta problemas de qualidade nos QR codes:
- QR codes não são renderizados como verdadeiros vetores
- Perda de qualidade em comparação com a versão PDF
- Incompatibilidade com alguns leitores de QR code

## Solução Recomendada: PDF Vetorial Editável

O Inkscape suporta nativamente a edição de arquivos PDF, que podem conter QR codes de alta qualidade em formato vetorial. Esta solução combina:

1. A qualidade visual dos PDFs gerados pelo sistema atual
2. A editabilidade necessária para personalização no Inkscape
3. A precisão e legibilidade dos QR codes

### Implementação Técnica

#### 1. Geração de QR Codes como Paths Vetoriais

Em vez de usar bibliotecas que geram QR codes como imagens bitmap, implementaremos uma solução que gera os QR codes como paths SVG puros:

```dart
String generateVectorQrCode(String data, {
  required double size,
  required int errorCorrectionLevel,
}) {
  // Gerar matriz de dados do QR code
  final qrCode = QrCode.fromData(
    data: data,
    errorCorrectLevel: QrErrorCorrectLevel.L,
  );
  
  final qrMatrix = qrCode.modules;
  final moduleCount = qrCode.moduleCount;
  final moduleSize = size / moduleCount;
  
  // Gerar paths SVG para cada módulo do QR code
  final buffer = StringBuffer();
  buffer.write('<g>');
  
  for (int row = 0; row < moduleCount; row++) {
    for (int col = 0; col < moduleCount; col++) {
      if (qrMatrix[row][col]) {
        final x = col * moduleSize;
        final y = row * moduleSize;
        buffer.write('<rect x="$x" y="$y" width="$moduleSize" height="$moduleSize" />');
      }
    }
  }
  
  // Adicionar padrões de localização (finder patterns) como paths otimizados
  _addFinderPattern(buffer, 0, 0, moduleSize);
  _addFinderPattern(buffer, moduleCount - 7, 0, moduleSize);
  _addFinderPattern(buffer, 0, moduleCount - 7, moduleSize);
  
  buffer.write('</g>');
  return buffer.toString();
}

void _addFinderPattern(StringBuffer buffer, int x, int y, double moduleSize) {
  // Implementação otimizada dos padrões de localização como paths SVG
  // Isso cria um único path para cada padrão de localização em vez de múltiplos retângulos
}
```

#### 2. Integração com PDF Editável

Usaremos o pacote `pdf` para gerar PDFs, mas configurados especificamente para serem facilmente editáveis no Inkscape:

```dart
Future<Uint8List> generateEditablePdf({
  required List<Box> boxes,
  required Map<int, List<Item>> boxItems,
  required LabelModel model,
  required LabelFormat format,
}) async {
  final pdf = pw.Document(
    // Configurações específicas para compatibilidade com Inkscape
    version: PdfVersion.pdf_1_5,
    compress: false, // Facilita a edição
  );
  
  // Configurar metadados para melhor integração com Inkscape
  pdf.info = pw.PdfInfo(
    author: 'MagicBoxV2',
    creator: 'MagicBoxV2 Label System',
    keywords: 'labels,qrcode,editable',
    producer: 'MagicBoxV2 Flutter App',
    subject: 'Editable Labels with QR Codes',
    title: 'MagicBoxV2 Editable Labels',
  );
  
  // Gerar páginas com QR codes vetoriais
  // ...código de geração de páginas...
  
  return pdf.save();
}
```

#### 3. Exportação Direta para Inkscape

Implementaremos uma opção para abrir diretamente no Inkscape após a exportação:

```dart
Future<void> exportAndOpenInInkscape({
  required List<Box> boxes,
  required Map<int, List<Item>> boxItems,
  required LabelModel model,
  required LabelFormat format,
}) async {
  // Gerar PDF editável
  final pdfBytes = await generateEditablePdf(
    boxes: boxes,
    boxItems: boxItems,
    model: model,
    format: format,
  );
  
  // Salvar em arquivo temporário
  final tempDir = await getTemporaryDirectory();
  final file = File('${tempDir.path}/labels_for_inkscape.pdf');
  await file.writeAsBytes(pdfBytes);
  
  // Abrir no Inkscape (implementação específica por plataforma)
  if (Platform.isWindows) {
    await Process.run('inkscape', [file.path]);
  } else if (Platform.isLinux) {
    await Process.run('inkscape', [file.path]);
  } else if (Platform.isMacOS) {
    await Process.run('open', ['-a', 'Inkscape', file.path]);
  } else {
    // Em plataformas móveis ou web, apenas salvar ou compartilhar o arquivo
    // ...código específico para cada plataforma...
  }
}
```

## Alternativa: EPS (Encapsulated PostScript)

Se o PDF editável não atender completamente às necessidades, o formato EPS é outra excelente opção:

- Formato vetorial nativo suportado pelo Inkscape
- Excelente qualidade para QR codes
- Totalmente editável em software de design gráfico

### Implementação do EPS

```dart
String generateEpsFile({
  required Box box,
  required List<Item> items,
  required LabelModel model,
  required LabelFormat format,
}) {
  final buffer = StringBuffer();
  
  // Cabeçalho EPS
  buffer.writeln('%!PS-Adobe-3.0 EPSF-3.0');
  buffer.writeln('%%BoundingBox: 0 0 ${model.widthPt} ${model.heightPt}');
  buffer.writeln('%%Creator: MagicBoxV2');
  buffer.writeln('%%Title: Label ${box.formattedId}');
  buffer.writeln('%%Pages: 1');
  buffer.writeln('%%EndComments');
  
  // Definições e funções
  buffer.writeln('/m {moveto} def');
  buffer.writeln('/l {lineto} def');
  buffer.writeln('/h {closepath} def');
  buffer.writeln('/f {fill} def');
  buffer.writeln('/s {stroke} def');
  buffer.writeln('/q {gsave} def');
  buffer.writeln('/Q {grestore} def');
  buffer.writeln('/W {setlinewidth} def');
  buffer.writeln('/rgb {setrgbcolor} def');
  
  // Desenhar borda da etiqueta
  buffer.writeln('0.5 W');
  buffer.writeln('0 0 0 rgb');
  buffer.writeln('0 0 m');
  buffer.writeln('${model.widthPt} 0 l');
  buffer.writeln('${model.widthPt} ${model.heightPt} l');
  buffer.writeln('0 ${model.heightPt} l');
  buffer.writeln('h s');
  
  // Gerar QR code como paths vetoriais
  final qrCode = QrCode.fromData(
    data: box.formattedId,
    errorCorrectLevel: QrErrorCorrectLevel.L,
  );
  
  final moduleCount = qrCode.moduleCount;
  final moduleSize = 20.0; // Tamanho em pontos
  final qrSize = moduleSize * moduleCount;
  final qrX = model.widthPt - qrSize - 10;
  final qrY = 10.0;
  
  buffer.writeln('q');
  buffer.writeln('1 0 0 1 $qrX $qrY translate');
  
  // Desenhar cada módulo do QR code
  for (int row = 0; row < moduleCount; row++) {
    for (int col = 0; col < moduleCount; col++) {
      if (qrCode.modules[row][col]) {
        final x = col * moduleSize;
        final y = (moduleCount - row - 1) * moduleSize; // Inverter Y para coordenadas EPS
        buffer.writeln('$x $y m');
        buffer.writeln('${x + moduleSize} $y l');
        buffer.writeln('${x + moduleSize} ${y + moduleSize} l');
        buffer.writeln('$x ${y + moduleSize} l');
        buffer.writeln('h f');
      }
    }
  }
  
  buffer.writeln('Q');
  
  // Adicionar texto
  _addEpsText(buffer, 10, model.heightPt - 20, box.formattedId, 12);
  _addEpsText(buffer, 10, model.heightPt - 35, box.name, 10);
  
  // Adicionar itens (se necessário)
  if (format == LabelFormat.idWithBarcodeAndItems) {
    double yPos = model.heightPt - 50;
    for (int i = 0; i < min(5, items.length); i++) {
      _addEpsText(buffer, 15, yPos, '• ${items[i].name}', 8);
      yPos -= 10;
    }
  }
  
  // Finalizar arquivo EPS
  buffer.writeln('%%EOF');
  
  return buffer.toString();
}

void _addEpsText(StringBuffer buffer, double x, double y, String text, double fontSize) {
  // Escapar caracteres especiais
  final escapedText = text
      .replaceAll('(', '\\(')
      .replaceAll(')', '\\)')
      .replaceAll('\\', '\\\\');
  
  buffer.writeln('q');
  buffer.writeln('/Helvetica findfont $fontSize scalefont setfont');
  buffer.writeln('0 0 0 rgb');
  buffer.writeln('$x $y m');
  buffer.writeln('($escapedText) show');
  buffer.writeln('Q');
}
```

## Comparação das Soluções

| Característica | PDF Vetorial | EPS | SVG Atual |
|----------------|--------------|-----|-----------|
| Qualidade do QR Code | Excelente | Excelente | Baixa |
| Compatibilidade com Inkscape | Boa | Excelente | Boa |
| Facilidade de Edição | Boa | Excelente | Média |
| Tamanho do Arquivo | Médio | Pequeno | Médio |
| Complexidade de Implementação | Média | Alta | Baixa |
| Suporte Multiplataforma | Excelente | Bom | Excelente |

## Recomendação Final

**Recomendamos a implementação do PDF Vetorial Editável** como a melhor solução para o MagicBoxV2, pois:

1. Mantém a mesma qualidade do QR code do PDF atual
2. É totalmente compatível com Inkscape para edição
3. Tem melhor suporte multiplataforma (web, mobile, desktop)
4. Requer menos alterações na base de código existente

A solução EPS pode ser implementada como uma opção adicional para usuários que necessitem de compatibilidade com outros softwares de design gráfico além do Inkscape.
