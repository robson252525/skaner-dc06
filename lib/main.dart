import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

void main() {
  runApp(const MaterialApp(
    home: SkanerEtykiet(),
    debugShowCheckedModeBanner: false,
  ));
}

class SkanerEtykiet extends StatefulWidget {
  const SkanerEtykiet({super.key});

  @override
  State<SkanerEtykiet> createState() => _SkanerEtykietState();
}

class _SkanerEtykietState extends State<SkanerEtykiet> {
  File? _imageFile;
  bool _isProcessing = false;

  String? wni;
  String? dostawca;
  String? zaklad;
  String? sapDostawca;
  String? eanKod;
  String? dataWaznosci;
  String? numerPartii;
  String? krajPochodzenia;
  String? masaNetto;

  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final BarcodeScanner _barcodeScanner = BarcodeScanner(formats: [BarcodeFormat.all]);

  final Map<String, Map<String, String>> bazaUbojni = {
    "28050201": {"d": "ANIMEX FOODS", "z": "Ełk", "s": "659323"},
    "10020202": {"d": "ANIMEX FOODS", "z": "Kutno K2", "s": "659323"},
    "10023801": {"d": "ANIMEX FOODS", "z": "Kutno K4", "s": "659323"},
    "04140316": {"d": "SOKOŁÓW S.A.", "z": "Osie", "s": "601497"},
    "12630215": {"d": "SOKOŁÓW S.A.", "z": "Tarnów", "s": "601497"},
    "14290201": {"d": "SOKOŁÓW S.A.", "z": "Sokołów Podlaski", "s": "601497"},
    "30090201": {"d": "SOKOŁÓW S.A.", "z": "Koło", "s": "601497"},
    "14130205": {"d": "CEDROB S.A.", "z": "Ujazdówek", "s": "612800"},
    "14040201": {"d": "CEDROB S.A.", "z": "Ciechanów", "s": "612800"},
    "14020201": {"d": "CEDROB S.A.", "z": "Niebieskie", "s": "612800"},
    "30020202": {"d": "DROSED S.A.", "z": "Ostrzeszów", "s": "600320"},
    "14260203": {"d": "DROSED S.A.", "z": "Siedlce", "s": "600320"},
    "04630201": {"d": "PLUKON", "z": "Grzmiąca", "s": "655900"},
    "14070201": {"d": "INDYKPOL", "z": "Olsztynek", "s": "604500"},
    "28620201": {"d": "INDYKPOL", "z": "Olsztyn", "s": "604500"},
    "30180201": {"d": "WIPASZ S.A.", "z": "Mława", "s": "664100"},
    "14180202": {"d": "WIPASZ S.A.", "z": "Koło", "s": "664100"},
    "14270201": {"d": "AGRO-RYDZYNA", "z": "Kłoda", "s": "621900"},
    "30040201": {"d": "SUPERDRIB", "z": "Karczew", "s": "618400"},
    "14170201": {"d": "PINI POLONIA", "z": "Kutno", "s": "639200"},
  };

  @override
  void dispose() {
    _textRecognizer.close();
    _barcodeScanner.close();
    super.dispose();
  }

  Future<void> _processImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return;

    setState(() {
      _imageFile = File(pickedFile.path);
      _isProcessing = true;
      _resetResults();
    });

    final inputImage = InputImage.fromFilePath(pickedFile.path);

    final barcodes = await _barcodeScanner.processImage(inputImage);
    if (barcodes.isNotEmpty) {
      eanKod = barcodes.first.rawValue;
    }

    final recognizedText = await _textRecognizer.processImage(inputImage);
    _analyzeText(recognizedText.text);

    setState(() {
      _isProcessing = false;
    });
  }

  void _resetResults() {
    wni = null;
    dostawca = null;
    zaklad = null;
    sapDostawca = null;
    eanKod = null;
    dataWaznosci = null;
    numerPartii = null;
    krajPochodzenia = null;
    masaNetto = null;
  }

  void _analyzeText(String fullText) {
    String clean = fullText.toUpperCase();

    for (String code in bazaUbojni.keys) {
      if (clean.replaceAll(RegExp(r'\s+'), '').contains(code)) {
        wni = code;
        dostawca = bazaUbojni[code]!['d'];
        zaklad = bazaUbojni[code]!['z'];
        sapDostawca = bazaUbojni[code]!['s'];
        break;
      }
    }

    final regData = RegExp(r'(\d{2}[.\-/]\d{2}[.\-/]\d{4})');
    final matchData = regData.firstMatch(clean);
    if (matchData != null) {
      dataWaznosci = matchData.group(0);
    }

    final regPartia = RegExp(r'(?:PARTIA|LOT|NR PARTII|PARTII|L\s*[:\.]?|P\s*[:\.]?)\s*([A-Z0-9\-\/]{4,15})');
    final matchPartia = regPartia.firstMatch(clean);
    if (matchPartia != null) {
      numerPartii = matchPartia.group(1);
    } else {
      final regDigits = RegExp(r'\b\d{8,12}\b');
      final matchDigits = regDigits.firstMatch(clean);
      if (matchDigits != null && matchDigits.group(0) != wni && matchDigits.group(0) != eanKod) {
        numerPartii = matchDigits.group(0);
      }
    }

    if (clean.contains("POLSKA") || clean.contains("KRAJ POCHODZENIA: PL") || clean.contains("POCHODZENIE: PL") || clean.contains("UBITO W: POLSKA")) {
      krajPochodzenia = "POLSKA (PL)";
    }

    final regMasa = RegExp(r'(\d+[\.,]?\d*)\s*(KG|G)\b');
    final matchMasa = regMasa.firstMatch(clean);
    if (matchMasa != null) {
      masaNetto = "${matchMasa.group(1)} ${matchMasa.group(2)}";
    }
  }

  Widget _buildRow(String tytul, String? wartosc, String domyslnyBrak) {
    bool ok = wartosc != null && wartosc.isNotEmpty;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ok ? Colors.green.withOpacity(0.08) : Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ok ? Colors.green.shade400 : Colors.red.shade400),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(tytul, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Flexible(
            child: Text(
              ok ? wartosc! : domyslnyBrak,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: ok ? Colors.green.shade800 : Colors.red.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kontrola Etykiety DC06"),
        backgroundColor: Colors.orange.shade800,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : () => _processImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Aparat"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700, foregroundColor: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : () => _processImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Z galerii"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_isProcessing)
              const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            if (_imageFile != null && !_isProcessing) ...[
              _buildRow("Ubojnia / Dostawca", dostawca != null ? "$dostawca ($zaklad)" : null, "BRAK W BAZIE"),
              _buildRow("SAP Dostawcy", sapDostawca, "BRAK"),
              _buildRow("Stempel WNI", wni, "NIE ROZPOZNANO"),
              _buildRow("Kod EAN (z kresek)", eanKod, "BRAK KODU"),
              _buildRow("Termin ważności", dataWaznosci, "BRAK DATY"),
              _buildRow("Numer partii", numerPartii, "BRAK PARTII"),
              _buildRow("Kraj pochodzenia", krajPochodzenia, "BRAK KRAJU"),
              _buildRow("Masa netto", masaNetto, "BRAK WAGI"),
            ],
          ],
        ),
      ),
    );
  }
}
