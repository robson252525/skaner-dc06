import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

  String? indeksProduktu;
  String? wni;
  String? dostawca;
  String? zaklad;
  String? sapDostawca;
  String? eanKod;
  String? dataWaznosci;
  String? numerPartii;
  String? krajPochodzenia;
  String? masaNetto;
  String _rawOcrText = "";

  List<Map<String, dynamic>> _historia = [];

  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final BarcodeScanner _barcodeScanner = BarcodeScanner(formats: [BarcodeFormat.all]);

  // =========================================================================
  // 1. PEŁNA BAZA INDEKSÓW PRODUKTÓW (MIĘSO, DRÓB, RYBY)
  // =========================================================================
  final Map<String, Map<String, String>> bazaIndeksow = {
    // SOKOŁÓW - KOŁO
    "269447": {"d": "SOKOŁÓW S.A.", "z": "Koło", "s": "601497"},
    "252992": {"d": "SOKOŁÓW S.A.", "z": "Koło", "s": "601497"},
    "242441": {"d": "SOKOŁÓW S.A.", "z": "Koło", "s": "601497"},
    "248309": {"d": "SOKOŁÓW S.A.", "z": "Koło", "s": "601497"},
    "252990": {"d": "SOKOŁÓW S.A.", "z": "Koło", "s": "601497"},
    "358678": {"d": "SOKOŁÓW S.A.", "z": "Koło", "s": "601497"},
    "311211": {"d": "SOKOŁÓW S.A.", "z": "Koło", "s": "601497"},
    "311306": {"d": "SOKOŁÓW S.A.", "z": "Koło", "s": "601497"},
    "351227": {"d": "SOKOŁÓW S.A.", "z": "Koło", "s": "601497"},
    "289245": {"d": "SOKOŁÓW S.A.", "z": "Koło", "s": "601497"},
    "255655": {"d": "SOKOŁÓW S.A.", "z": "Koło", "s": "601497"},
    "299187": {"d": "SOKOŁÓW S.A.", "z": "Koło", "s": "601497"},
    "288928": {"d": "SOKOŁÓW S.A.", "z": "Koło", "s": "601497"},
    "305118": {"d": "SOKOŁÓW S.A.", "z": "Koło", "s": "601497"},
    "283100": {"d": "SOKOŁÓW S.A.", "z": "Koło", "s": "601497"},
    "299186": {"d": "SOKOŁÓW S.A.", "z": "Koło", "s": "601497"},
    "283101": {"d": "SOKOŁÓW S.A.", "z": "Koło", "s": "601497"},
    "283185": {"d": "SOKOŁÓW S.A.", "z": "Koło", "s": "601497"},
    "284481": {"d": "SOKOŁÓW S.A.", "z": "Koło", "s": "601497"},
    "283099": {"d": "SOKOŁÓW S.A.", "z": "Koło", "s": "601497"},
    "298471": {"d": "SOKOŁÓW S.A.", "z": "Koło", "s": "601497"},
    "378161": {"d": "SOKOŁÓW S.A.", "z": "Koło", "s": "601497"},
    "283102": {"d": "SOKOŁÓW S.A.", "z": "Koło", "s": "601497"},
    "371258": {"d": "SOKOŁÓW S.A.", "z": "Koło", "s": "601497"},
    "385472": {"d": "SOKOŁÓW S.A.", "z": "Koło", "s": "601497"},
    "376289": {"d": "SOKOŁÓW S.A.", "z": "Koło", "s": "601497"},
    "235414": {"d": "SOKOŁÓW S.A.", "z": "Koło", "s": "601497"},
    "365852": {"d": "SOKOŁÓW S.A.", "z": "Koło", "s": "601497"},
    "421238": {"d": "SOKOŁÓW S.A.", "z": "Koło", "s": "601497"},
    "274688": {"d": "SOKOŁÓW S.A.", "z": "Koło", "s": "601497"},
    "432543": {"d": "SOKOŁÓW S.A.", "z": "Koło", "s": "601497"},
    "489879": {"d": "SOKOŁÓW S.A.", "z": "Koło", "s": "601497"},
    "267902": {"d": "SOKOŁÓW S.A.", "z": "Koło", "s": "601497"},
    "528886": {"d": "SOKOŁÓW S.A.", "z": "Koło", "s": "601497"},
    "273411": {"d": "SOKOŁÓW S.A.", "z": "Koło", "s": "601497"},
    "540145": {"d": "SOKOŁÓW S.A.", "z": "Koło", "s": "601497"},
    "582162": {"d": "SOKOŁÓW S.A.", "z": "Koło", "s": "601497"},
    "594820": {"d": "SOKOŁÓW S.A.", "z": "Koło", "s": "601497"},

    // SOKOŁÓW - TARNÓW
    "266821": {"d": "SOKOŁÓW S.A.", "z": "Tarnów", "s": "601497"},
    "427830": {"d": "SOKOŁÓW S.A.", "z": "Tarnów", "s": "601497"},
    "202068": {"d": "SOKOŁÓW S.A.", "z": "Tarnów", "s": "601497"},
    "658339": {"d": "SOKOŁÓW S.A.", "z": "Tarnów", "s": "601497"},
    "240565": {"d": "SOKOŁÓW S.A.", "z": "Tarnów", "s": "601497"},
    "210216": {"d": "SOKOŁÓW S.A.", "z": "Tarnów", "s": "601497"},
    "232107": {"d": "SOKOŁÓW S.A.", "z": "Tarnów", "s": "601497"},
    "281098": {"d": "SOKOŁÓW S.A.", "z": "Tarnów", "s": "601497"},
    "365665": {"d": "SOKOŁÓW S.A.", "z": "Tarnów", "s": "601497"},
    "488256": {"d": "SOKOŁÓW S.A.", "z": "Tarnów", "s": "601497"},

    // SOKOŁÓW - OSIE
    "196985": {"d": "SOKOŁÓW S.A.", "z": "Osie", "s": "601497"},
    "207571": {"d": "SOKOŁÓW S.A.", "z": "Osie", "s": "601497"},
    "203384": {"d": "SOKOŁÓW S.A.", "z": "Osie", "s": "601497"},
    "324462": {"d": "SOKOŁÓW S.A.", "z": "Osie", "s": "601497"},
    "359517": {"d": "SOKOŁÓW S.A.", "z": "Osie", "s": "601497"},
    "374183": {"d": "SOKOŁÓW S.A.", "z": "Osie", "s": "601497"},
    "379497": {"d": "SOKOŁÓW S.A.", "z": "Osie", "s": "601497"},
    "299089": {"d": "SOKOŁÓW S.A.", "z": "Osie", "s": "601497"},
    "374058": {"d": "SOKOŁÓW S.A.", "z": "Osie", "s": "601497"},
    "418452": {"d": "SOKOŁÓW S.A.", "z": "Osie", "s": "601497"},

    // SOKOŁÓW - ROBAKOWO
    "275768": {"d": "SOKOŁÓW S.A.", "z": "Robakowo", "s": "601497"},
    "229123": {"d": "SOKOŁÓW S.A.", "z": "Robakowo", "s": "601497"},
    "310698": {"d": "SOKOŁÓW S.A.", "z": "Robakowo", "s": "601497"},
    "246813": {"d": "SOKOŁÓW S.A.", "z": "Robakowo", "s": "601497"},
    "280393": {"d": "SOKOŁÓW S.A.", "z": "Robakowo", "s": "601497"},
    "259817": {"d": "SOKOŁÓW S.A.", "z": "Robakowo", "s": "601497"},
    "265330": {"d": "SOKOŁÓW S.A.", "z": "Robakowo", "s": "601497"},
    "259811": {"d": "SOKOŁÓW S.A.", "z": "Robakowo", "s": "601497"},
    "259816": {"d": "SOKOŁÓW S.A.", "z": "Robakowo", "s": "601497"},
    "259819": {"d": "SOKOŁÓW S.A.", "z": "Robakowo", "s": "601497"},
    "577363": {"d": "SOKOŁÓW S.A.", "z": "Robakowo", "s": "601497"},

    // SOKOŁÓW - JAROSŁAW
    "282528": {"d": "SOKOŁÓW S.A.", "z": "Jarosław", "s": "601497"},
    "252991": {"d": "SOKOŁÓW S.A.", "z": "Jarosław", "s": "601497"},
    "205348": {"d": "SOKOŁÓW S.A.", "z": "Jarosław", "s": "601497"},
    "311305": {"d": "SOKOŁÓW S.A.", "z": "Jarosław", "s": "601497"},
    "290467": {"d": "SOKOŁÓW S.A.", "z": "Jarosław", "s": "601497"},
    "270974": {"d": "SOKOŁÓW S.A.", "z": "Jarosław", "s": "601497"},
    "359181": {"d": "SOKOŁÓW S.A.", "z": "Jarosław", "s": "601497"},
    "270065": {"d": "SOKOŁÓW S.A.", "z": "Jarosław", "s": "601497"},
    "356732": {"d": "SOKOŁÓW S.A.", "z": "Jarosław", "s": "601497"},
    "379395": {"d": "SOKOŁÓW S.A.", "z": "Jarosław", "s": "601497"},
    "379484": {"d": "SOKOŁÓW S.A.", "z": "Jarosław", "s": "601497"},
    "386042": {"d": "SOKOŁÓW S.A.", "z": "Jarosław", "s": "601497"},
    "406745": {"d": "SOKOŁÓW S.A.", "z": "Jarosław", "s": "601497"},
    "418475": {"d": "SOKOŁÓW S.A.", "z": "Jarosław", "s": "601497"},
    "389456": {"d": "SOKOŁÓW S.A.", "z": "Jarosław", "s": "601497"},
    "503456": {"d": "SOKOŁÓW S.A.", "z": "Jarosław", "s": "601497"},
    "421211": {"d": "SOKOŁÓW S.A.", "z": "Jarosław", "s": "601497"},
    "432673": {"d": "SOKOŁÓW S.A.", "z": "Jarosław", "s": "601497"},

    // ANIMEX
    "259180": {"d": "ANIMEX FOODS", "z": "Kutno K3", "s": "659323"},
    "436206": {"d": "ANIMEX FOODS", "z": "Kutno K3", "s": "659323"},
    "302260": {"d": "ANIMEX FOODS", "z": "Kutno K3", "s": "659323"},
    "303926": {"d": "ANIMEX FOODS", "z": "Szczecin K1", "s": "659323"},
    "205301": {"d": "ANIMEX FOODS", "z": "Szczecin K1", "s": "659323"},
    "275063": {"d": "ANIMEX FOODS", "z": "Szczecin K1", "s": "659323"},
    "275062": {"d": "ANIMEX FOODS", "z": "Szczecin K1", "s": "659323"},
    "351345": {"d": "ANIMEX FOODS", "z": "Szczecin K1", "s": "659323"},
    "311365": {"d": "ANIMEX FOODS", "z": "Kutno K4", "s": "659323"},
    "478966": {"d": "ANIMEX FOODS", "z": "Kutno K4", "s": "659323"},
    "422590": {"d": "ANIMEX FOODS", "z": "Kutno K4", "s": "659323"},
    "436212": {"d": "ANIMEX FOODS", "z": "Kutno K4", "s": "659323"},
    "259809": {"d": "ANIMEX FOODS", "z": "Starachowice", "s": "659323"},
    "259808": {"d": "ANIMEX FOODS", "z": "Starachowice", "s": "659323"},
    "259827": {"d": "ANIMEX FOODS", "z": "Starachowice", "s": "659323"},
    "514211": {"d": "ANIMEX FOODS", "z": "Starachowice", "s": "659323"},
    "372980": {"d": "ANIMEX FOODS", "z": "Opole", "s": "659323"},
    "265064": {"d": "ANIMEX FOODS", "z": "Ełk", "s": "659323"},
    "312590": {"d": "ANIMEX FOODS", "z": "Suwałki", "s": "659323"},
    "438882": {"d": "ANIMEX FOODS", "z": "Suwałki", "s": "659323"},
    "365137": {"d": "ANIMEX FOODS", "z": "Suwałki", "s": "659323"},
    "190244": {"d": "ANIMEX FOODS", "z": "Iława", "s": "659323"},
    "204655": {"d": "ANIMEX FOODS", "z": "Iława", "s": "659323"},
    "208126": {"d": "ANIMEX FOODS", "z": "Iława", "s": "659323"},

    // CEDROB
    "259770": {"d": "CEDROB S.A.", "z": "Ujazdówek", "s": "600195"},
    "259768": {"d": "CEDROB S.A.", "z": "Ujazdówek", "s": "600195"},
    "259766": {"d": "CEDROB S.A.", "z": "Ujazdówek", "s": "600195"},
    "405259": {"d": "CEDROB S.A.", "z": "Ujazdówek", "s": "600195"},
    "360275": {"d": "CEDROB S.A.", "z": "Ujazdówek", "s": "600195"},
    "504929": {"d": "CEDROB S.A.", "z": "Mokrsko", "s": "600195"},
    "657782": {"d": "CEDROB S.A.", "z": "Mokrsko", "s": "600195"},
    "205658": {"d": "CEDROB S.A.", "z": "Mokrsko", "s": "600195"},
    "382704": {"d": "CEDROB S.A.", "z": "Mokrsko", "s": "600195"},
    "652598": {"d": "CEDROB S.A.", "z": "Mokrsko", "s": "600195"},
    "540226": {"d": "CEDROB S.A.", "z": "Mokrsko", "s": "600195"},

    // DROSED / ROLDROB / SEDAR / DROP
    "233828": {"d": "DROSED S.A.", "z": "Sedar", "s": "600299"},
    "202199": {"d": "DROSED S.A.", "z": "Sedar", "s": "600299"},
    "260720": {"d": "DROSED S.A.", "z": "Sedar", "s": "600299"},
    "369466": {"d": "DROSED S.A.", "z": "Sedar", "s": "600299"},
    "285489": {"d": "DROSED S.A.", "z": "Sedar", "s": "600299"},
    "372006": {"d": "DROSED S.A.", "z": "Sedar", "s": "600299"},
    "371978": {"d": "DROSED S.A.", "z": "Sedar", "s": "600299"},
    "372005": {"d": "DROSED S.A.", "z": "Sedar", "s": "600299"},
    "377973": {"d": "DROSED S.A.", "z": "Sedar", "s": "600299"},
    "531804": {"d": "DROSED S.A.", "z": "Sedar", "s": "600299"},
    "304131": {"d": "DROSED S.A.", "z": "Drop", "s": "600299"},
    "290016": {"d": "DROSED S.A.", "z": "Drop", "s": "600299"},
    "289758": {"d": "DROSED S.A.", "z": "Drop", "s": "600299"},
    "307905": {"d": "DROSED S.A.", "z": "Drop", "s": "600299"},
    "252996": {"d": "DROSED S.A.", "z": "Drop", "s": "600299"},
    "369782": {"d": "DROSED S.A.", "z": "Drop", "s": "600299"},
    "364754": {"d": "DROSED S.A.", "z": "Drop", "s": "600299"},
    "503709": {"d": "DROSED S.A.", "z": "Drop", "s": "600299"},
    "297072": {"d": "DROSED S.A.", "z": "Roldrob", "s": "600299"},
    "252834": {"d": "DROSED S.A.", "z": "Roldrob", "s": "600299"},
    "365372": {"d": "DROSED S.A.", "z": "Roldrob", "s": "600299"},
    "293987": {"d": "DROSED S.A.", "z": "Roldrob", "s": "600299"},
    "367855": {"d": "DROSED S.A.", "z": "Roldrob", "s": "600299"},
    "366921": {"d": "DROSED S.A.", "z": "Roldrob", "s": "600299"},
    "377840": {"d": "DROSED S.A.", "z": "Roldrob", "s": "600299"},
    "436660": {"d": "DROSED S.A.", "z": "Roldrob", "s": "600299"},
    "536162": {"d": "DROSED S.A.", "z": "Roldrob", "s": "600299"},
    "477445": {"d": "DROSED S.A.", "z": "Roldrob", "s": "600299"},
    "477476": {"d": "DROSED S.A.", "z": "Roldrob", "s": "600299"},

    // ZAKRZEWSCY
    "259798": {"d": "ZAKRZEWSCY", "z": "Szczuczyn", "s": "643968"},
    "259799": {"d": "ZAKRZEWSCY", "z": "Szczuczyn", "s": "643968"},
    "259800": {"d": "ZAKRZEWSCY", "z": "Szczuczyn", "s": "643968"},
    "259801": {"d": "ZAKRZEWSCY", "z": "Szczuczyn", "s": "643968"},
    "259796": {"d": "ZAKRZEWSCY", "z": "Szczuczyn", "s": "643968"},
    "268120": {"d": "ZAKRZEWSCY", "z": "Stanisławów", "s": "643968"},
    "370128": {"d": "ZAKRZEWSCY", "z": "Stanisławów", "s": "643968"},
    "385365": {"d": "ZAKRZEWSCY", "z": "Stanisławów", "s": "643968"},
    "464158": {"d": "ZAKRZEWSCY", "z": "Stanisławów", "s": "643968"},
    "600128": {"d": "ZAKRZEWSCY", "z": "Stanisławów", "s": "643968"},
  };

  // =========================================================================
  // 2. PEŁNA BAZA STEMPLI WETERYNARYJNYCH WNI (DRÓB, WIEPRZOWINA, WOŁOWINA, RYBY)
  // =========================================================================
  final Map<String, Map<String, String>> bazaWni = {
    // --- RYBY ---
    "32081801": {"d": "KORAL", "z": "Kukinia", "s": "600632"},
    "22121801": {"d": "MILAREX", "z": "Słupsk", "s": "648574"},
    "32131801": {"d": "PIRS", "z": "Darłowo", "s": "636757"},
    "20041801": {"d": "REKIN", "z": "Grajewo", "s": "639641"},
    "20031801": {"d": "SUEMPOL", "z": "Bielsk Podlaski", "s": "600588"},
    "22121802": {"d": "MOWI / MORPOL", "z": "Duninowo", "s": "610900"},
    "12011801": {"d": "CONTIMAX", "z": "Bochnia", "s": "622100"},
    "22071801": {"d": "SEKO", "z": "Chojnice", "s": "608400"},
    "32091801": {"d": "NORD CAPITAL", "z": "Rekowo Górne", "s": "633200"},

    // --- ANIMEX ---
    "28050201": {"d": "ANIMEX FOODS", "z": "Ełk", "s": "659323"},
    "10020202": {"d": "ANIMEX FOODS", "z": "Kutno K2", "s": "659323"},
    "10023801": {"d": "ANIMEX FOODS", "z": "Kutno K4", "s": "659323"},
    "10020201": {"d": "ANIMEX FOODS", "z": "Kutno K3", "s": "659323"},
    "32620201": {"d": "ANIMEX FOODS", "z": "Szczecin K1", "s": "659323"},
    "26110201": {"d": "ANIMEX FOODS", "z": "Starachowice", "s": "659323"},
    "28070201": {"d": "ANIMEX FOODS", "z": "Iława", "s": "659323"},
    "20630201": {"d": "ANIMEX FOODS", "z": "Suwałki", "s": "659323"},
    "16610201": {"d": "ANIMEX FOODS", "z": "Opole", "s": "659323"},

    // --- SOKOŁÓW ---
    "30090201": {"d": "SOKOŁÓW S.A.", "z": "Koło", "s": "601497"},
    "12630215": {"d": "SOKOŁÓW S.A.", "z": "Tarnów", "s": "601497"},
    "14290201": {"d": "SOKOŁÓW S.A.", "z": "Sokołów Podlaski", "s": "601497"},
    "04140316": {"d": "SOKOŁÓW S.A.", "z": "Osie", "s": "601497"},
    "30210201": {"d": "SOKOŁÓW S.A.", "z": "Robakowo", "s": "601497"},
    "18040201": {"d": "SOKOŁÓW S.A.", "z": "Jarosław", "s": "601497"},
    "20130201": {"d": "SOKOŁÓW S.A.", "z": "Czyżew", "s": "601497"},
    "18030201": {"d": "SOKOŁÓW S.A.", "z": "Dębica", "s": "601497"},

    // --- CEDROB ---
    "14130205": {"d": "CEDROB S.A.", "z": "Ujazdówek", "s": "600195"},
    "14040201": {"d": "CEDROB S.A.", "z": "Ciechanów", "s": "600195"},
    "14020201": {"d": "CEDROB S.A.", "z": "Niebieskie", "s": "600195"},
    "10180201": {"d": "CEDROB S.A.", "z": "Mokrsko", "s": "600195"},
    "10020203": {"d": "CEDROB S.A.", "z": "Kutno", "s": "600195"},

    // --- DROSED / ROLDROB / SEDAR / DROP ---
    "14260203": {"d": "DROSED S.A.", "z": "Siedlce", "s": "600299"},
    "06010201": {"d": "DROSED S.A.", "z": "Sedar", "s": "600299"},
    "30020202": {"d": "DROSED S.A.", "z": "Drop", "s": "600299"},
    "10160201": {"d": "DROSED S.A.", "z": "Roldrob", "s": "600299"},

    // --- PLUKON ---
    "04630201": {"d": "PLUKON", "z": "Grzmiąca", "s": "647600"},
    "10010201": {"d": "PLUKON", "z": "Wyrębski", "s": "647600"},

    // --- ZAKRZEWSCY ---
    "20040201": {"d": "ZAKRZEWSCY", "z": "Szczuczyn", "s": "643968"},
    "14120201": {"d": "ZAKRZEWSCY", "z": "Stanisławów", "s": "643968"},
    "14290202": {"d": "ZAKRZEWSCY", "z": "Kosów Lacki", "s": "643968"},

    // --- POZOSTALI ---
    "14180202": {"d": "WIPASZ S.A.", "z": "Koło", "s": "642915"},
    "14130201": {"d": "WIPASZ S.A.", "z": "Mława", "s": "642915"},
    "28620201": {"d": "INDYKPOL", "z": "Olsztyn", "s": "614301"},
    "14070201": {"d": "INDYKPOL", "z": "Olsztynek", "s": "614301"},
    "22030201": {"d": "GOODVALLEY", "z": "Przechlewo", "s": "616640"},
    "06110201": {"d": "ŁUKÓW", "z": "Łuków", "s": "635426"},
    "14270201": {"d": "AGRO-RYDZYNA", "z": "Kłoda", "s": "621900"},
    "30040201": {"d": "SUPERDROB", "z": "Karczew", "s": "648711"},
    "06630201": {"d": "SUPERDROB", "z": "Lublin", "s": "648711"},
    "30060201": {"d": "BIERNA", "z": "Jarocin", "s": "636848"},
    "22040201": {"d": "NOWAK", "z": "Jankowo", "s": "645317"},
    "30210202": {"d": "WIELKOPOLSKI INDYK", "z": "Mosina", "s": "644590"},
    "10180202": {"d": "DOBRYDZIAŁ", "z": "Dobrydział", "s": "650415"},
    "14170201": {"d": "PINI POLONIA", "z": "Kutno", "s": "639200"},
  };

  // =========================================================================
  // 3. BAZA NAZW DOSTAWCÓW I KODÓW SAP GŁÓWNYCH
  // =========================================================================
  final Map<String, Map<String, String>> bazaDostawcowNazwy = {
    "KORAL": {"d": "KORAL", "z": "Kukinia", "s": "600632"},
    "MILAREX": {"d": "MILAREX", "z": "Słupsk", "s": "648574"},
    "PIRS": {"d": "PIRS", "z": "Darłowo", "s": "636757"},
    "REKIN": {"d": "REKIN", "z": "Grajewo", "s": "639641"},
    "SUEMPOL": {"d": "SUEMPOL", "z": "Bielsk Podlaski", "s": "600588"},
    "MOWI": {"d": "MOWI / MORPOL", "z": "Duninowo", "s": "610900"},
    "MORPOL": {"d": "MOWI / MORPOL", "z": "Duninowo", "s": "610900"},
    "CONTIMAX": {"d": "CONTIMAX", "z": "Bochnia", "s": "622100"},
    "SEKO": {"d": "SEKO", "z": "Chojnice", "s": "608400"},
    "ANIMEX": {"d": "ANIMEX FOODS", "z": "Kutno", "s": "659323"},
    "SOKOŁÓW": {"d": "SOKOŁÓW S.A.", "z": "Sokołów Podlaski", "s": "601497"},
    "SOKOLOW": {"d": "SOKOŁÓW S.A.", "z": "Sokołów Podlaski", "s": "601497"},
    "CEDROB": {"d": "CEDROB S.A.", "z": "Ujazdówek", "s": "600195"},
    "DROSED": {"d": "DROSED S.A.", "z": "Siedlce", "s": "600299"},
    "PLUKON": {"d": "PLUKON", "z": "Grzmiąca", "s": "647600"},
    "WIPASZ": {"d": "WIPASZ S.A.", "z": "Mława", "s": "642915"},
    "INDYKPOL": {"d": "INDYKPOL", "z": "Olsztyn", "s": "614301"},
    "GOODVALLEY": {"d": "GOODVALLEY", "z": "Przechlewo", "s": "616640"},
    "ŁUKÓW": {"d": "ŁUKÓW", "z": "Łuków", "s": "635426"},
    "LUKOW": {"d": "ŁUKÓW", "z": "Łuków", "s": "635426"},
    "AGRO-RYDZYNA": {"d": "AGRO-RYDZYNA", "z": "Kłoda", "s": "621900"},
    "SUPERDROB": {"d": "SUPERDROB", "z": "Lublin", "s": "648711"},
  };

  @override
  void initState() {
    super.initState();
    _wczytajHistorieZPamieci();
  }

  @override
  void dispose() {
    _textRecognizer.close();
    _barcodeScanner.close();
    super.dispose();
  }

  Future<void> _wczytajHistorieZPamieci() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('historia_skanow');
    if (data != null) {
      setState(() {
        _historia = List<Map<String, dynamic>>.from(json.decode(data));
      });
    }
  }

  Future<void> _zapiszDoPamieci(Map<String, dynamic> wpis) async {
    final prefs = await SharedPreferences.getInstance();
    _historia.insert(0, wpis);
    await prefs.setString('historia_skanow', json.encode(_historia));
    setState(() {});
  }

  Future<void> _wyczyscPamiec() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('historia_skanow');
    setState(() {
      _historia.clear();
    });
  }

  Future<void> _processImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 100);
    if (pickedFile == null) return;

    setState(() {
      _imageFile = File(pickedFile.path);
      _isProcessing = true;
      _resetResults();
    });

    final inputImage = InputImage.fromFilePath(pickedFile.path);

    // 1. ODCZYT KODÓW KRESKOWYCH (EAN / GS1-128 / DATABAR)
    try {
      final barcodes = await _barcodeScanner.processImage(inputImage);
      for (var b in barcodes) {
        final val = b.rawValue;
        if (val != null && val.trim().isNotEmpty) {
          eanKod = val.trim();
          _parsujGS1(val.trim());
          break;
        }
      }
    } catch (_) {}

    // 2. ODCZYT TEKSTU (OCR)
    try {
      final recognizedText = await _textRecognizer.processImage(inputImage);
      _rawOcrText = recognizedText.text;
      _analizujTekstOcr(_rawOcrText);
    } catch (_) {}

    // 3. ZAPIS DO HISTORII W PAMIĘCI TELEFONU
    final wpis = {
      "czas": DateTime.now().toIso8601String(),
      "indeks": indeksProduktu,
      "dostawca": dostawca,
      "zaklad": zaklad,
      "sap": sapDostawca,
      "wni": wni,
      "ean": eanKod,
      "data": dataWaznosci,
      "partia": numerPartii,
      "kraj": krajPochodzenia,
      "masa": masaNetto,
    };
    await _zapiszDoPamieci(wpis);

    setState(() {
      _isProcessing = false;
    });
  }

  void _parsujGS1(String raw) {
    final matchEan = RegExp(r'(?:\(01\)|01)(\d{14})').firstMatch(raw);
    if (matchEan != null) eanKod = matchEan.group(1);

    final matchData = RegExp(r'(?:\(15\)|\(17\)|15|17)(\d{2})(\d{2})(\d{2})').firstMatch(raw);
    if (matchData != null && dataWaznosci == null) {
      dataWaznosci = "20${matchData.group(1)}-${matchData.group(2)}-${matchData.group(3)}";
    }

    final matchWaga = RegExp(r'(?:\(310[0-5]\)|310[0-5])(\d{6})').firstMatch(raw);
    if (matchWaga != null && masaNetto == null) {
      double val = double.parse(matchWaga.group(1)!) / 100.0;
      masaNetto = "${val.toStringAsFixed(2)} KG";
    }

    final matchPartia = RegExp(r'(?:\(10\)|10)([A-Z0-9]{3,15})').firstMatch(raw);
    if (matchPartia != null && numerPartii == null) {
      numerPartii = matchPartia.group(1);
    }
  }

  void _analizujTekstOcr(String text) {
    String clean = text.toUpperCase();

    // 1. SZUKANIE INDEKSU PRODUKTU W BAZIE
    for (String ind in bazaIndeksow.keys) {
      if (clean.contains(ind)) {
        indeksProduktu = ind;
        dostawca = bazaIndeksow[ind]!['d'];
        zaklad = bazaIndeksow[ind]!['z'];
        sapDostawca = bazaIndeksow[ind]!['s'];
        break;
      }
    }

    // 2. SZUKANIE STEMPLA WETERYNARYJNEGO WNI (8 CYFR)
    String cleanNoSpaces = clean.replaceAll(RegExp(r'\s+'), '');
    for (String code in bazaWni.keys) {
      if (cleanNoSpaces.contains(code)) {
        wni = code;
        if (dostawca == null) {
          dostawca = bazaWni[code]!['d'];
          zaklad = bazaWni[code]!['z'];
          sapDostawca = bazaWni[code]!['s'];
        }
        break;
      }
    }

    // 3. STEMPEL FORMATU: PL XX XX XX XX
    if (wni == null) {
      final matchWni = RegExp(r'PL\s*(\d{2}\s*\d{2}\s*\d{2}\s*\d{2})').firstMatch(clean);
      if (matchWni != null) {
        wni = matchWni.group(1)!.replaceAll(RegExp(r'\s+'), '');
        if (bazaWni.containsKey(wni) && dostawca == null) {
          dostawca = bazaWni[wni]!['d'];
          zaklad = bazaWni[wni]!['z'];
          sapDostawca = bazaWni[wni]!['s'];
        }
      }
    }

    // 4. JEŚLI DALEJ BRAK DOSTAWCY -> SZUKAJ PO NAZWIE FIRMY
    if (dostawca == null) {
      for (String nazwa in bazaDostawcowNazwy.keys) {
        if (clean.contains(nazwa)) {
          dostawca = bazaDostawcowNazwy[nazwa]!['d'];
          zaklad = bazaDostawcowNazwy[nazwa]!['z'];
          sapDostawca = bazaDostawcowNazwy[nazwa]!['s'];
          break;
        }
      }
    }

    // 5. DATA WAŻNOŚCI
    if (dataWaznosci == null) {
      final regData = RegExp(r'(\d{2}[\.\-\/]\d{2}[\.\-\/]\d{2,4})');
      final matchData = regData.firstMatch(clean);
      if (matchData != null) {
        dataWaznosci = matchData.group(0);
      }
    }

    // 6. NUMER PARTII
    if (numerPartii == null) {
      final regPartia = RegExp(r'(?:PARTIA|LOT|SERIA|NR\s*PARTII|PARTII|L\s*[:\.]?|P\s*[:\.]?)\s*([A-Z0-9\-\/]{3,18})');
      final matchP = regPartia.firstMatch(clean);
      if (matchP != null) {
        numerPartii = matchP.group(1);
      } else {
        final regCyfry = RegExp(r'\b\d{7,12}\b');
        for (var m in regCyfry.allMatches(clean)) {
          final s = m.group(0);
          if (s != wni && s != eanKod && s != indeksProduktu) {
            numerPartii = s;
            break;
          }
        }
      }
    }

    // 7. MASA NETTO
    if (masaNetto == null) {
      final regMasa = RegExp(r'(\d+[,\.]\d{1,3})\s*(?:KG|G)\b');
      final matchM = regMasa.firstMatch(clean);
      if (matchM != null) {
        masaNetto = "${matchM.group(1)} KG";
      }
    }

    // 8. KRAJ POCHODZENIA
    if (clean.contains("POLSKA") || clean.contains("KRAJ POCHODZENIA: PL") || clean.contains("POCHODZENIE: PL") || clean.contains("UBITO W: PL") || clean.contains("PL ")) {
      krajPochodzenia = "POLSKA (PL)";
    }
  }

  void _resetResults() {
    indeksProduktu = null;
    wni = null;
    dostawca = null;
    zaklad = null;
    sapDostawca = null;
    eanKod = null;
    dataWaznosci = null;
    numerPartii = null;
    krajPochodzenia = null;
    masaNetto = null;
    _rawOcrText = "";
  }

  Widget _buildRow(String tytul, String? wartosc) {
    bool ok = wartosc != null && wartosc.trim().isNotEmpty;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ok ? Colors.green.withOpacity(0.12) : Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ok ? Colors.green.shade600 : Colors.red.shade400, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(tytul, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Flexible(
            child: Text(
              ok ? wartosc! : "BRAK DANYCH",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: ok ? Colors.green.shade900 : Colors.red.shade800,
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Historia skanów (${_historia.length})", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      if (_historia.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.delete_forever, color: Colors.red, size: 28),
                          onPressed: () async {
                            await _wyczyscPamiec();
                            setModalState(() {});
                          },
                        ),
                    ],
                  ),
                  const Divider(),
                  _historia.isEmpty
                      ? const Expanded(child: Center(child: Text("Brak zapisanych skanów w pamięci")))
                      : Expanded(
                          child: ListView.builder(
                            itemCount: _historia.length,
                            itemBuilder: (context, index) {
                              final h = _historia[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                elevation: 3,
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        h['dostawca'] != null ? "${h['dostawca']} (${h['zaklad']})" : "NIEZNANY DOSTAWCA",
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(height: 4),
                                      Text("Indeks: ${h['indeks'] ?? '-'} | SAP: ${h['sap'] ?? '-'}"),
                                      Text("Partia: ${h['partia'] ?? '-'} | Data: ${h['data'] ?? '-'}"),
                                      Text("Waga: ${h['masa'] ?? '-'} | EAN: ${h['ean'] ?? '-'}"),
                                      Text("WNI: ${h['wni'] ?? '-'}"),
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
            icon: const Icon(Icons.history, size: 28),
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
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : () => _processImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Z galerii"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
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
              _buildRow("Wykryty Indeks SAP", indeksProduktu),
              _buildRow("Ubojnia / Dostawca", dostawca != null ? "$dostawca ($zaklad)" : null),
              _buildRow("SAP Dostawcy", sapDostawca),
              _buildRow("Stempel WNI", wni),
              _buildRow("Kod EAN / Kreski", eanKod),
              _buildRow("Termin ważności", dataWaznosci),
              _buildRow("Numer partii", numerPartii),
              _buildRow("Kraj pochodzenia", krajPochodzenia),
              _buildRow("Masa netto", masaNetto),
              const SizedBox(height: 15),
              ExpansionTile(
                title: const Text("Podgląd surowego tekstu z etykiety (OCR)", style: TextStyle(fontSize: 12, color: Colors.grey)),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    color: Colors.grey.shade200,
                    child: Text(_rawOcrText.isEmpty ? "Brak odczytanego tekstu" : _rawOcrText, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
