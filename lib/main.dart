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

class WynikSkanu {
  final DateTime czas;
  final String? dostawca;
  final String? zaklad;
  final String? sapDostawca;
  final String? wni;
  final String? eanKod;
  final String? dataWaznosci;
  final String? numerPartii;
  final String? krajPochodzenia;
  final String? masaNetto;

  WynikSkanu({
    required this.czas,
    this.dostawca,
    this.zaklad,
    this.sapDostawca,
    this.wni,
    this.eanKod,
    this.dataWaznosci,
    this.numerPartii,
    this.krajPochodzenia,
    this.masaNetto,
  });
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

  final List<WynikSkanu> _historia = [];

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
    "30040201": {"d": "SUPERDROB", "z": "Karczew", "s": "618400"},
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

    // Zapis do historii
    _historia.insert(0, WynikSkanu(
      czas: DateTime.now(),
      dostawca: dostawca,
      zaklad: zaklad,
      sapDostawca: sapDostawca,
      wni: wni,
      eanKod: eanKod,
      dataWaznosci: dataWaznosci,
      numerPartii: numerPartii,
      krajPochodzenia: krajPochodzenia,
      masaNetto: masaNetto,
    ));

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

  void _pokazHistorie() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Historia skanów",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (_historia.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.delete_sweep, color: Colors.red),
                          tooltip: "Wyczyść historię",
                          onPressed: () {
                            setState(() => _historia.clear());
                            setModalState(() {});
                          },
                        ),
                    ],
                  ),
                  const Divider(),
                  _historia.isEmpty
                      ? const Expanded(
                          child: Center(
                            child: Text("Brak zapisanych skanów w tej sesji"),
                          ),
                        )
                      : Expanded(
                          child: ListView.builder(
                            itemCount: _historia.length,
                            itemBuilder: (context, index) {
                              final h = _historia[index];
                              final czasStr = "${h.czas.hour.toString().padLeft(2, '0')}:${h.czas.minute.toString().padLeft(2, '0')}:${h.czas.second.toString().padLeft(2, '0')}";
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            h.dostawca != null ? "${h.dostawca} (${h.zaklad})" : "NIEZNANY DOSTAWCA",
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                          Text(czasStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text("WNI: ${h.wni ?? '-'} | SAP: ${h.sapDostawca ?? '-'}"),
                                      Text("Partia: ${h.numerPartii ?? '-'} | Ważność: ${h.dataWaznosci ?? '-'}"),
                                      Text("EAN: ${h.eanKod ?? '-'} | Waga: ${h.masaNetto ?? '-'}"),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kontrola Etykiety DC06"),
        backgroundColor: Colors.orange.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: "Historia skanów",
            onPressed: _pokazHistorie,
          ),
        ],
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
