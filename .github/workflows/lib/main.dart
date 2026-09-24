import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

void main() {
  runApp(const MaterialApp(
    home: EkranGlowny(),
    debugShowCheckedModeBanner: false,
  ));
}

class RaportSkanu {
  final String czas;
  final String? wni;
  final String? dostawca;
  final String? produkt;
  final String? ean;
  final String? data;
  final String? partia;
  final String? waga;

  RaportSkanu({
    required this.czas,
    this.wni,
    this.dostawca,
    this.produkt,
    this.ean,
    this.data,
    this.partia,
    this.waga,
  });
}

class EkranGlowny extends StatefulWidget {
  const EkranGlowny({super.key});

  @override
  State<EkranGlowny> createState() => _EkranGlownyState();
}

class _EkranGlownyState extends State<EkranGlowny> {
  int _zakladka = 0;
  final List<RaportSkanu> _historia = [];

  File? _imageFile;
  bool _isProcessing = false;

  String? wni;
  String? dostawca;
  String? produkt;
  String? eanKod;
  String? dataWaznosci;
  String? numerPartii;
  String? masaNetto;

  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final BarcodeScanner _barcodeScanner = BarcodeScanner();

  final Map<String, String> bazaWNI = {
    "22030207": "GOODVALLEY (Przechlewo)",
    "28050201": "ANIMEX FOODS (Ełk)",
    "10020202": "ANIMEX FOODS (Kutno K2)",
    "10023801": "ANIMEX FOODS (Kutno K4)",
    "04140316": "SOKOŁÓW S.A. (Osie)",
    "12630215": "SOKOŁÓW S.A. (Tarnów)",
    "14290201": "SOKOŁÓW S.A. (Sokołów Podl.)",
    "30090201": "SOKOŁÓW S.A. (Koło)",
    "14130205": "CEDROB S.A. (Ujazdówek)",
    "14040201": "CEDROB S.A. (Ciechanów)",
    "14020201": "CEDROB S.A. (Niebieskie)",
    "30020202": "DROSED S.A. (Ostrzeszów)",
    "14260203": "DROSED S.A. (Siedlce)",
    "04630201": "PLUKON (Grzmiąca)",
    "14070201": "INDYKPOL (Olsztynek)",
    "28620201": "INDYKPOL (Olsztyn)",
    "30180201": "WIPASZ S.A. (Mława)",
    "14180202": "WIPASZ S.A. (Koło)",
    "14270201": "AGRO-RYDZYNA (Kłoda)",
    "30040201": "SUPERDRIB (Karczew)",
    "14170201": "PINI POLONIA (Kutno)",
  };

  @override
  void dispose() {
    _textRecognizer.close();
    _barcodeScanner.close();
    super.dispose();
  }

  Future<void> _skanuj(ImageSource zrodlo) async {
    final plik = await _picker.pickImage(source: zrodlo);
    if (plik == null) return;

    setState(() {
      _imageFile = File(plik.path);
      _isProcessing = true;
      _resetPola();
    });

    final inputImage = InputImage.fromFilePath(plik.path);

    // 1. Kody kreskowe
    try {
      final barcodes = await _barcodeScanner.processImage(inputImage);
      if (barcodes.isNotEmpty) {
        eanKod = barcodes.first.rawValue;
      }
    } catch (_) {}

    // 2. OCR Tekstu
    try {
      final recognizedText = await _textRecognizer.processImage(inputImage);
      _parsujEtykiete(recognizedText);
    } catch (_) {}

    // 3. Dodaj do historii
    final teraz = DateTime.now();
    final czasStr = "${teraz.hour.toString().padLeft(2, '0')}:${teraz.minute.toString().padLeft(2, '0')}:${teraz.second.toString().padLeft(2, '0')}";

    _historia.insert(
      0,
      RaportSkanu(
        czas: czasStr,
        wni: wni,
        dostawca: dostawca,
        produkt: produkt,
        ean: eanKod,
        data: dataWaznosci,
        partia: numerPartii,
        waga: masaNetto,
      ),
    );

    setState(() {
      _isProcessing = false;
    });
  }

  void _resetPola() {
    wni = null;
    dostawca = null;
    produkt = null;
    eanKod = null;
    dataWaznosci = null;
    numerPartii = null;
    masaNetto = null;
  }

  void _parsujEtykiete(RecognizedText recognized) {
    List<String> linie = [];
    for (var b in recognized.blocks) {
      for (var l in b.lines) {
        linie.add(l.text.trim());
      }
    }

    String calosc = linie.join("\n").toUpperCase();

    // 1. Nazwa Produktu z etykiety
    if (calosc.contains("KOTLETY")) {
      produkt = "MIĘSO NA KOTLETY Z INDYKA";
    } else if (calosc.contains("GULASZ")) {
      produkt = "MIĘSO NA GULASZ Z SZYNKI";
    } else if (calosc.contains("ROSOŁOWA")) {
      produkt = "PORCJA ROSOŁOWA WOŁOWA";
    } else if (calosc.contains("ŻEBERKA") || calosc.contains("ZEBERKA")) {
      produkt = "ŻEBERKA WIEPRZOWE";
    }

    // 2. WNI
    for (var code in bazaWNI.keys) {
      if (calosc.replaceAll(RegExp(r'\s+'), '').contains(code)) {
        wni = code;
        dostawca = bazaWNI[code];
        break;
      }
    }

    // 3. Data i Partia (analiza pionowa)
    final regData = RegExp(r'(\b\d{2}[.\-/]\d{2}[.\-/]\d{4}\b)');
    for (int i = 0; i < linie.length; i++) {
      var match = regData.firstMatch(linie[i]);
      if (match != null) {
        dataWaznosci = match.group(0);

        // Numer partii znajduje się bezpośrednio w kolejnej linii pod datą
        if (i + 1 < linie.length) {
          String kolejnaLinia = linie[i + 1].trim();
          final regPartiaLinia = RegExp(r'^[A-Z0-9\-/]{5,15}$');
          if (regPartiaLinia.hasMatch(kolejnaLinia)) {
            numerPartii = kolejnaLinia;
          }
        }
        break;
      }
    }

    // Dodatkowe sprawdzenie partii po słowach kluczowych
    if (numerPartii == null) {
      final regPartiaKey = RegExp(r'(?:PARTIA|LOT|PARTII|L|P)[\s.:]*([A-Z0-9\-/]{5,15})');
      var matchP = regPartiaKey.firstMatch(calosc);
      if (matchP != null) {
        numerPartii = matchP.group(1);
      }
    }

    // 4. Masa Netto
    final regMasa = RegExp(r'(\d+[\.,]?\d*)\s*(KG|G)\b');
    var matchM = regMasa.firstMatch(calosc);
    if (matchM != null) {
      masaNetto = "${matchM.group(1)} ${matchM.group(2)}";
    }
  }

  Widget _wierszRaportu(String tytul, String? wartosc, String brak) {
    bool ok = wartosc != null && wartosc.isNotEmpty;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ok ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: ok ? Colors.green.shade400 : Colors.red.shade400),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(tytul, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Flexible(
            child: Text(
              ok ? wartosc! : brak,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: ok ? Colors.green.shade900 : Colors.red.shade900,
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
        title: Text(_zakladka == 0 ? "Kontrola Etykiety DC06" : "Historia Kontroli (${_historia.length})"),
        backgroundColor: Colors.orange.shade800,
        actions: [
          if (_zakladka == 1 && _historia.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: "Wyczyść historię",
              onPressed: () {
                setState(() {
                  _historia.clear();
                });
              },
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _zakladka,
        onTap: (i) => setState(() => _zakladka = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: "Skaner"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "Historia"),
        ],
      ),
      body: _zakladka == 0 ? _budujSkaner() : _budujHistorie(),
    );
  }

  Widget _budujSkaner() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : () => _skanuj(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Aparat"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700, foregroundColor: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : () => _skanuj(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text("Galeria"),
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
            _wierszRaportu("Produkt", produkt, "BRAK NAZWY"),
            _wierszRaportu("Termin ważności", dataWaznosci, "BRAK DATY"),
            _wierszRaportu("Numer partii", numerPartii, "BRAK PARTII"),
            _wierszRaportu("Masa netto", masaNetto, "BRAK WAGI"),
            _wierszRaportu("Kod EAN", eanKod, "BRAK KRESKÓWKI"),
            _wierszRaportu("Stempel WNI", wni, "BRAK STEMPLA"),
            _wierszRaportu("Dostawca / Zakład", dostawca, "NIEZNANY"),
          ],
        ],
      ),
    );
  }

  Widget _budujHistorie() {
    if (_historia.isEmpty) {
      return const Center(child: Text("Brak zapisanych skanów w historii."));
    }
    return ListView.builder(
      itemCount: _historia.length,
      itemBuilder: (context, idx) {
        final r = _historia[idx];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(r.czas, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    Text(r.waga ?? "--", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(),
                Text("Produkt: ${r.produkt ?? 'Nie rozpoznano'}", style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("Data do: ${r.data ?? 'Brak'} | Partia: ${r.partia ?? 'Brak'}"),
                Text("Dostawca: ${r.dostawca ?? 'Brak'} (WNI: ${r.wni ?? '--'})"),
                if (r.ean != null) Text("EAN: ${r.ean}"),
              ],
            ),
          ),
        );
      },
    );
  }
}
