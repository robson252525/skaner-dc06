import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MaterialApp(
    home: ScannerScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});
  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  CameraController? _controller;
  final TextRecognizer _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  bool _isProcessing = false;
  Map<String, String>? _matchedResult;

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
    "2023802": ["ZAKŁADY MIĘSNE ZAKRZEWSCY", "Szczuczyn", "643968"],
    "32131802": ["ATLANTIC SP. Z O.O.", "Kowalewice", "648702"],
    "08090501": ["BOMADEK", "Trzebiechów", "642597"],
    "8090501": ["BOMADEK", "Trzebiechów", "642597"],
    "30094203": ["CARNIS-KOŁO ZAKŁADY MIĘSNE", "Koło", "643717"],
    "1020874": ["CARNIQUES CELRA", "Girona (Hiszpania)", "503644"],
    "10061801": ["CPF CULINAR SP. Z O.O.", "Żeromin", "653367"],
    "12011805": ["CONTIMAX SPÓŁKA AKCYJNA", "Bochnia", "645068"],
    "32620501": ["DROBIMEX SP.Z O.O.", "Szczecin", "600297"],
    "10079557": ["ESS-FOOD A/S", "CCV (Hiszpania)", "502503"],
    "1001293": ["ESS-FOOD A/S", "Patel (Hiszpania)", "502503"],
    "1004472": ["ESS-FOOD A/S", "Baucells (Hiszpania)", "502503"],
    "1007986": ["ESS-FOOD A/S", "Costa Food Meat", "502503"],
    "10027284": ["ESS-FOOD / LITERA MEAT", "Litera Meat (Hiszpania)", "502503"],
    "30094205": ["EUROBEEF", "Koło", "647033"],
    "22121834": ["EURO FISH SP. Z O. O.", "Bierkowo", "652422"],
    "22121829": ["FARIO EWA IWANOWSKA-BALCERZYK", "Potęgowo", "632553"],
    "30063901": ["FARMIO SP Z O. O.", "Golina", "649399"],
    "10153901": ["FARMIO SPÓŁKA AKCYJNA", "Lipce", "640048"],
    "1002453": ["FRIBIN, S.A.T.", "Hiszpania", "502821"],
    "22621809": ["GADUS SP.Z O.O.", "Gdynia", "643341"],
    "00220302": ["GOODVALLEY SP. Z O.O.", "Przechlewo", "616640"],
    "220302": ["GOODVALLEY SP. Z O.O.", "Przechlewo", "616640"],
    "04073901": ["GOSPODARSTWO RODZINNE / RSP NOWOŚĆ", "Kostrzyn / Struga", "652790"],
    "4073901": ["GOSPODARSTWO RODZINNE / RSP NOWOŚĆ", "Kostrzyn / Struga", "652790"],
    "24770305": ["HILTON FOODS LTD SP. Z O.O.", "Tychy", "650265"],
    "08120501": ["HODOWLA I UBÓJ INDYKA BODAMA", "Sława", "647322"],
    "8120501": ["HODOWLA I UBÓJ INDYKA BODAMA", "Sława", "647322"],
    "32070501": ["IKO KOMPANIA / MADAMA", "Golczewo", "656049"],
    "28620501": ["INDYKPOL S.A.", "Olsztyn", "614301"],
    "1005576": ["INTERCOELHO", "Hiszpania", "501843"],
    "12110317": ["KABANOS KOJS", "Jabłonka", "644478"],
    "18030701": ["KANWIL DĘBICA", "Dębica", "630814"],
    "22631802": ["KOHLER SP. Z O.O.", "Milarex", "648574"],
    "30230501": ["KONSPOL HOLDING SP.Z O.O.", "Słupca", "600627"],
    "32081801": ["KORAL S.A.", "Kukinia", "600632"],
    "10027366": ["LA COMARCA", "Murcja (Hiszpania)", "503487"],
    "32011807": ["LIBRU SEA SP. Z O. O.", "Białogard", "646500"],
    "79329004": ["LOEUL ET PIRIOT", "Francja", "501625"],
    "32131818": ["MIELESZCZYK / NORDFISH", "Warszkowo", "644967"],
    "22121815": ["MIRKO SP. Z O.O.", "Głobino", "643163"],
    "22121818": ["MOWI POLAND SALES S.A.", "Duninowo", "644540"],
    "22040305": ["ZAKŁADY MIĘSNE NOWAK", "Jankowo Gdańskie", "645317"],
    "32131815": ["PIRS SP. Z O.O.", "Darłowo", "636757"],
    "32044101": ["PLUKON SIERADZ SP. Z O.O.", "Sieradz", "647600"],
    "20041802": ["REKIN JAN MOZOLEWSKI", "Grajewo", "639641"],
    "14330501": ["POLANA", "Miedzna", "658082"],
    "22023801": ["ZAKŁADY MIĘSNE SKIBA S.A.", "Chojnice", "659384"],
    "24091801": ["SONA SP. Z O.O.", "Koziegłowy", "649004"],
    "30214307": ["STORTEBOOM HAMROL SP. Z O.O", "Komorniki", "646073"],
    "8216": ["TENDER MEAT SP. Z O.O.", "Wielka Brytania", "650983"],
    "72364": ["UAB AG SEAFOOD LITHUANIA", "Taurages (Litwa)", "503686"],
    "24724002": ["WAKPOL SPÓŁKA AKCYJNA", "Ruda Śląska", "625867"],
    "10184202": ["WĘDLINKA GROUP SPÓŁKA", "Dobrydział", "650415"],
    "30210513": ["WIELKOPOLSKI INDYK SP Z.O.O", "Mosina", "644590"],
    "04060501": ["ZAKŁAD DROBIARSKI LINODRÓB", "Linowo", "653285"],
    "4060501": ["ZAKŁAD DROBIARSKI LINODRÓB", "Linowo", "653285"],
    "14263902": ["ZAKŁAD DROBIARSKI W STASINIE", "Stasin", "647105"],
    "30063801": ["ZPM BIERNACKI", "Jarocin", "636848"],
    "10103901": ["ZAKŁADY DROBIARSKIE DROB-BOGS", "Kaleń", "621586"],
    "14260201": ["ZAKŁAD MIĘSNY MOŚCIBRODY", "Mościbrody", "642053"],
    "06110266": ["ZAKŁADY MIĘSNE ŁUKÓW S.A.", "Łuków", "635426"],
    "6110266": ["ZAKŁADY MIĘSNE ŁUKÓW S.A.", "Łuków", "635426"],
    "30210501": ["ZAKŁADY DROBIARSKIE KOZIEGŁOWY", "Koziegłowy", "601521"],
    "14270201": ["ZM OLEWNIK", "Sierpc", "653941"],
    "32131828": ["POLSKI KARP SP. Z O.O.", "Kraków", "660156"]
  };

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    await Permission.camera.request();
    if (cameras.isEmpty) return;

    _controller = CameraController(cameras[0], ResolutionPreset.high, enableAudio: false);
    await _controller!.initialize();
    _controller!.setZoomLevel(2.0); // Domyślny zoom 2x ułatwiający łapanie małych owali

    _controller!.startImageStream((image) => _processImage(image));
    if (mounted) setState(() {});
  }

  void _processImage(CameraImage img) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in img.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(img.width.toDouble(), img.height.toDouble()),
          rotation: InputImageRotation.rotation90deg,
          format: InputImageFormat.nv21,
          bytesPerRow: img.planes[0].bytesPerRow,
        ),
      );

      final recognizedText = await _recognizer.processImage(inputImage);
      _matchSupplier(recognizedText.text);
    } catch (_) {}

    _isProcessing = false;
  }

  void _matchSupplier(String text) {
    String clean = text.toUpperCase().replaceAll(RegExp(r'[^0-9A-Z]'), '');
    for (var entry in _baza.entries) {
      if (clean.contains(entry.key)) {
        setState(() {
          _matchedResult = {
            "lok": entry.value[1],
            "nazwa": entry.value[0],
            "sap": entry.value[2],
            "wni": entry.key
          };
        });
        return;
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _recognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CameraPreview(_controller!),
          if (_matchedResult != null)
            Positioned(
              bottom: 40,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withOpacity(0.95),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF38BDF8), width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_matchedResult!["lok"]!, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                    const SizedBox(height: 4),
                    Text(_matchedResult!["nazwa"]!, style: const TextStyle(fontSize: 16, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text("SAP: ${_matchedResult!["sap"]!} | WNI: ${_matchedResult!["wni"]!}", style: const TextStyle(fontSize: 14, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
