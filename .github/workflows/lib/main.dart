name: Zbuduj APK

on:
  push:
    branches: [ main, master ]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Konfiguracja Javy
        uses: actions/setup-java@v3
        with:
          distribution: 'zulu'
          java-version: '17'

      - name: Konfiguracja Fluttera
        uses: subosito/flutter-action@v2
        with:
          channel: 'stable'

      - run: flutter create . --platforms=android
      - run: flutter pub add google_mlkit_text_recognition image_picker
      - run: flutter build apk --release

      - name: Zapisz gotowy plik APK
        uses: actions/upload-artifact@v4
        with:
          name: Skaner-DC06-Gotowy
          path: build/app/outputs/flutter-apk/app-release.apk
