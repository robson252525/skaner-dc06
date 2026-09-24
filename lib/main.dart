void _analizujTekstOcr(String text) {
    // Normalizacja tekstu z zachowaniem podziału na linie
    final lines = text.split(RegExp(r'[\r\n]+')).map((e) => e.trim().toUpperCase()).where((e) => e.isNotEmpty).toList();
    final clean = text.toUpperCase();

    // =========================================================================
    // 1. STEMPEL WETERYNARYJNY (WNI) Z TYŁU TACKI (np. PL 28620501 UE, PL 22030207 WE)
    // =========================================================================
    final matchWniRaw = RegExp(r'PL\s*(\d{2}\s*\d{2}\s*\d{2}\s*\d{2})').firstMatch(clean);
    if (matchWniRaw != null) {
      wni = matchWniRaw.group(1)!.replaceAll(RegExp(r'\s+'), '');
    } else {
      final matchWni8 = RegExp(r'\b(\d{8})\b').firstMatch(clean.replaceAll(RegExp(r'\s+'), ''));
      if (matchWni8 != null && bazaWni.containsKey(matchWni8.group(1))) {
        wni = matchWni8.group(1);
      }
    }

    if (wni != null && bazaWni.containsKey(wni)) {
      dostawca = bazaWni[wni]!['d'];
      zaklad = bazaWni[wni]!['z'];
      sapDostawca = bazaWni[wni]!['s'];
    }

    // =========================================================================
    // 2. NAZWA PRODUCENTA (PRZEZ: INDYKPOL, GOODVALLEY, SOKOŁÓW)
    // =========================================================================
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

    // =========================================================================
    // 3. MASA NETTO (np. "500 g", "500g e", "0,463 kg", "0.335 kg")
    // =========================================================================
    if (masaNetto == null) {
      final regMasa = RegExp(r'(\d+[,\.]?\d*)\s*(KG|G)\b');
      // Szukamy najpierw w okolicy słowa MASA / NETTO
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].contains("MASA") || lines[i].contains("NETTO")) {
          final m1 = regMasa.firstMatch(lines[i]);
          if (m1 != null) {
            masaNetto = "${m1.group(1)} ${m1.group(2)}".replaceAll('.', ',');
            break;
          } else if (i + 1 < lines.length) {
            final m2 = regMasa.firstMatch(lines[i + 1]);
            if (m2 != null) {
              masaNetto = "${m2.group(1)} ${m2.group(2)}".replaceAll('.', ',');
              break;
            }
          }
        }
      }
      // Rezerwowe szukanie ogólne
      if (masaNetto == null) {
        final mAll = regMasa.firstMatch(clean);
        if (mAll != null) {
          masaNetto = "${mAll.group(1)} ${mAll.group(2)}".replaceAll('.', ',');
        }
      }
    }

    // =========================================================================
    // 4. DATA WAŻNOŚCI (Format DD-MM-YYYY lub DD.MM.YYYY)
    // =========================================================================
    if (dataWaznosci == null) {
      final regData = RegExp(r'\b(\d{2}[\.\-\/]\d{2}[\.\-\/]\d{4})\b');
      final mData = regData.firstMatch(clean);
      if (mData != null) {
        dataWaznosci = mData.group(1)!.replaceAll('/', '-').replaceAll('.', '-');
      }
    }

    // =========================================================================
    // 5. NUMER PARTII (Dedykowane pod tacki Biedronki: wiersz pod datą)
    // =========================================================================
    if (numerPartii == null) {
      for (int i = 0; i < lines.length; i++) {
        // Jeśli linijka to data ważności, partia na tackach Biedronki jest ZAWSZE bezpośrednio pod nią
        if (RegExp(r'\d{2}[\.\-\/]\d{2}[\.\-\/]\d{4}').hasMatch(lines[i])) {
          if (i + 1 < lines.length) {
            String candidate = lines[i + 1].replaceAll(RegExp(r'[^A-Z0-9]'), '');
            // Partia w Biedronce ma zazwyczaj od 6 do 14 znaków cyfrowo-literowych
            if (candidate.length >= 6 && !candidate.contains("PRZECHOWYWAĆ") && !candidate.contains("MASA")) {
              numerPartii = candidate;
              break;
            }
          }
        }
      }

      // Rezerwowe szukanie ciągu cyfr, jeśli data i partia skleiły się w jedną linię
      if (numerPartii == null) {
        final regFallbackPartia = RegExp(r'\b(\d{7,14})\b');
        for (var match in regFallbackPartia.allMatches(clean)) {
          String val = match.group(1)!;
          if (val != wni && val != eanKod && val != dataWaznosci?.replaceAll('-', '')) {
            numerPartii = val;
            break;
          }
        }
      }
    }

    // =========================================================================
    // 6. KRAJ POCHODZENIA
    // =========================================================================
    if (clean.contains("POLSKI") || clean.contains("POLSKA") || clean.contains("PL ") || clean.contains("POCHODZENIE: POLSKA")) {
      krajPochodzenia = "POLSKA (PL)";
    }
  }
