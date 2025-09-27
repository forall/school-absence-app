# 📱 School Absence App - Szybkie zgłaszanie nieobecności

## 🎯 Opis
Aplikacja mobilna do **super szybkiego** zgłaszania nieobecności dziecka w szkole w związku z obiadami.

## ⚡ Główne funkcje
- 🚀 **1-klikowe zgłaszanie** nieobecności na dziś/jutro/pojutrze
- 📧 **Automatyczne otwieranie maila** z gotową treścią
- 📅 **Kalendarz** do planowania nieobecności
- 📊 **Podsumowania miesięczne** z statystykami
- ⚙️ **Ustawienia** (imię dziecka, email szkoły)
- 💾 **Lokalne przechowywanie** (SQLite) - działa offline
- 🗑️ **Usuwanie** błędnie dodanych nieobecności

## 🚀 Jak zbudować APK

### Opcja 1: GitHub Actions (ZALECANA - automatycznie)
1. **Wgraj kod na GitHub:**
   - Utwórz nowe repozytorium na GitHub
   - Wgraj wszystkie pliki z tego projektu

2. **GitHub automatycznie zbuduje APK:**
   - Idź w zakładkę "Actions"
   - Poczekaj ~5-10 minut na zakończenie

3. **Pobierz APK:**
   - Kliknij na ukończony workflow
   - Przewiń w dół do sekcji "Artifacts"
   - Pobierz odpowiedni plik APK dla swojego telefonu:
     - `school-absence-app-arm64.apk` (większość nowoczesnych telefonów)
     - `school-absence-app-arm32.apk` (starsze telefony)

### Opcja 2: Lokalnie (jeśli masz Flutter)
```bash
flutter pub get
flutter build apk --release --split-per-abi
```

## 📲 Instalacja na telefonie
1. Pobierz odpowiedni plik `.apk`
2. W ustawieniach Androida włącz "Instalowanie z nieznanych źródeł"
3. Kliknij na plik `.apk` i zainstaluj

## 🎮 Jak używać

### Pierwsze uruchomienie:
1. Otwórz aplikację
2. Idź w ⚙️ **Ustawienia**
3. Wpisz **imię i nazwisko dziecka**
4. Wpisz **adres email szkoły**
5. Kliknij **"ZAPISZ USTAWIENIA"**

### Codzienne użytkowanie:
1. **Szybkie zgłaszanie:**
   - Otwórz aplikację
   - Kliknij **"DZIŚ"**, **"JUTRO"** lub **"POJUTRZE"**
   - Automatycznie otworzy się Gmail/Outlook z gotowym mailem
   - Kliknij **"Wyślij"** w aplikacji pocztowej

2. **Planowanie z kalendarza:**
   - Kliknij **"OTWÓRZ KALENDARZ"**
   - Kliknij na wybraną datę
   - Mail otworzy się automatycznie

3. **Sprawdzanie historii:**
   - Kliknij ikonę 📊 w prawym górnym rogu
   - Zobacz statystyki i historię nieobecności

## 📧 Format wysyłanego maila
```
Do: szkola@example.com
Temat: Nieobecność - obiady

Dzień dobry,

Informuję, że Jan Kowalski nie będzie obecny w szkole w dniu 26.09.2025 (czwartek).

Pozdrawiam
```

## 🔧 Wymagania systemowe
- **Android 5.0+** (API 21+)
- **Aplikacja pocztowa** (Gmail, Outlook, itp.)
- **Połączenie internetowe** (do wysyłania maili)

## 🛡️ Bezpieczeństwo i prywatność
- ✅ Wszystkie dane przechowywane **lokalnie na telefonie**
- ✅ **Brak wysyłania danych** do zewnętrznych serwerów
- ✅ Maile wysyłane **przez Twoją skrzynkę pocztową**
- ✅ **Brak reklam** i śledzenia

## 🐛 Rozwiązywanie problemów

**Nie otwiera się aplikacja pocztowa:**
- Sprawdź czy masz zainstalowaną aplikację Gmail/Outlook
- Sprawdź czy aplikacja pocztowa jest skonfigurowana

**Nie można zainstalować APK:**
- Włącz "Instalowanie z nieznanych źródeł" w ustawieniach
- Sprawdź czy pobrałeś odpowiedni plik APK dla swojego telefonu

**Aplikacja się zawiesza:**
- Wymuś zamknięcie i uruchom ponownie
- Sprawdź czy masz wystarczająco miejsca na telefonie

## 📞 Wsparcie
Jeśli masz problemy z aplikacją, możesz:
- Sprawdzić sekcję "Issues" w repozytorium GitHub
- Utworzyć nowy "Issue" z opisem problemu

---

**Wersja:** 1.0.0  
**Ostatnia aktualizacja:** $(date +'%d.%m.%Y')  
**Licencja:** MIT
