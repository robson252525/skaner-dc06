import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

void main() {
  runApp(const MaterialApp(
    home: SkanerApp(),
    debugShowCheckedModeBanner: false,
  ));
}

class SkanerApp extends StatefulWidget {
  const SkanerApp({super.key});
  @override
  State<SkanerApp> createState() => _SkanerAppState();
}

class _SkanerAppState extends State<SkanerApp> {
  File? _image;
  String _wynik = "Zrób zdjęcie owalu na opakowaniu";
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  final Map<String, List<String>> _baza = {
    "28050201": ["ANIMEX FOODS", "Ełk", "659323"],
    "28070501": ["ANIMEX FOODS", "Iława", "659323"],
    "10024002": ["ANIMEX FOODS", "K1", "659323"],
    "10024001": ["ANIMEX FOODS", "K2", "659323"],
    "10043902": ["ANIMEX FOODS", "K3", "659323"],
    "10023802": ["ANIMEX Kutno K4", "Kutno / K4", "636168"],
    "16610501": ["ANIMEX FOODS", "Opole", "659323"],
    "26110201": ["ANIMEX FOODS", "Starachowice", "659323"],
    "20630501": ["ANIMEX FOODS", "Suwałki", "659323"],
    "32620201": ["ANIMEX FOODS", "Szczecin", "659323"],
    "10020501": ["CEDROB S.A.", "Kutno", "600195"],
    "14023901": ["CEDROB S.A.", "Ujazdówek", "600195"],
    "10170206": ["CEDROB S.A. / KANIA", "Mokrsko", "600195"],
    "04610601": ["DROBEX PRZEDSIĘBIORSTWO DROBIARSKIE", "Bydgoszcz", "612590"],
    "4610601": ["DROBEX PRZEDSIĘBIORSTWO DROBIARSKIE", "Bydgoszcz", "612590"],
    "04033902": ["DROBEX PRZEDSIĘBIORSTWO DROBIARSKIE", "Solec Kujawski", "612590"],
    "4033902": ["DROBEX PRZEDSIĘBIORSTWO DROBIARSKIE", "Solec Kujawski", "612590"],
    "30083901": ["DROSED S.A.", "Drop", "600299"],
    "10160501": ["DROSED S.A.", "Roldrob", "600299"],
    "06013903": ["DROSED S.A.", "Sedar", "600299"],
    "6013903": ["DROSED S.A.", "Sedar", "600299"],
    "14260501": ["DROSED S.A.", "Siedlce", "600299"],
    "14290201": ["SOKOŁÓW S.A.", "Sokołów Podlaski", "601497"],
    "18040201": ["SOKOŁÓW S.A.", "Jarosław", "601497"],
    "30090201": ["SOKOŁÓW S.A.", "Koło", "601497"],
    "30210225": ["SOKOŁÓW S.A.", "Robakowo", "601497"],
    "04140316": ["SOKOŁÓW S.A.", "Osie", "601497"],
    "4140316": ["SOKOŁÓW S.A.", "Osie", "601497"],
    "12630215": ["SOKOŁÓW S.A.", "Tarnów", "601497"],
    "14170501": ["SUPERDROB S.A", "Karczew", "648711"],
    "06630501": ["SUPERDROB S.A", "Lublin", "648711"],
    "6630501": ["SUPERDROB S.A", "Lublin", "648711"],
    "14130502": ["WIPASZ SPÓŁKA AKCYJNA", "Mława", "642915"],
    "06013904": ["WIPASZ SPÓŁKA AKCYJNA", "Międzyrzec Podlaski", "642915"],
    "6013904": ["WIPASZ SPÓŁKA AKCYJNA", "Międzyrzec Podlaski", "642915"],
    "14293801": ["ZAKŁADY MIĘSNE ZAKRZEWSCY", "Kosów Lacki", "643968"],
    "14120202": ["ZAKŁADY MIĘSNE ZAKRZEWSCY", "Stanisławów", "643968"],
    "02023802": ["ZAKŁADY MIĘSNE ZAKRZEWSCY", "Szczuczyn", "643968"],
    "2023802": ["ZAKŁADY MIĘSNE ZAKRZEWSCY", "Szczuczyn", "643968"]
  };

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo == null) return;

    setState(() {
      _image = File(photo.path);
      _wynik = "Analizowanie...";
    });

    final inputImage = InputImage.fromFilePath(photo.path);
    final RecognizedText recognizedText = await _recognizer.processImage(inputImage);

    String clean = recognizedText.text.toUpperCase().replaceAll(RegExp(r'[^0-9A-Z]'), '');
    String? znaleziony;

    for (var entry in _baza.entries) {
      if (clean.contains(entry.key)) {
        znaleziony = "${entry.value[1]}\n${entry.value[0]}\nSAP: ${entry.value[2]} (WNI: ${entry.key})";
        break;
      }
    }

    setState(() {
      _wynik = znaleziony ?? "Nie rozpoznano zakładu w owalu.\nOdczytano:\n${recognizedText.text}";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Skaner DC06"), backgroundColor: Colors.amber[800]),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (_image != null) Image.file(_image!, height: 250),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                child: Text(_wynik, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.camera_alt, size: 28),
                label: const Text("Zrób zdjęcie", style: TextStyle(fontSize: 20)),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
