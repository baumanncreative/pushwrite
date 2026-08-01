# Ausführungsbericht: PushWrite 0.2.0-alpha.1

Stand: 2026-08-01

## A. Ergebnis

- Version: `0.2.0-alpha.1`, Build `200001`
- Branch: `codex/release-0.2.0-alpha.1`
- Ausgangsrevision: `3a32d7d01a61f23fc16cef17d2f9a06582f2643d`
- Plattform: macOS 13.0 oder neuer, Apple Silicon arm64
- Whisper: whisper.cpp mit `ggml-tiny.bin`, 77.691.713 Byte
- Lokale Übersetzungsprüfung: Argos Translate / CTranslate2, Argos-Pakete `translate-en_de-1_3` und `translate-de_en-1_3`
- Kernfunktion: implementiert, paketiert und real lokal validiert
- Übersetzung: Architektur/UI vorbereitet, im Alpha-Build deaktiviert

## B. Umsetzung

Die App ist eine native AppKit-Menu-Bar-Anwendung. Carbon registriert den globalen Press-and-hold-Hotkey. AVFoundation zeichnet 16-kHz-Mono-WAV auf; der gebündelte statische `whisper-cli` transkribiert lokal. ApplicationServices prüft Fokus, Feldrolle, Editierbarkeit, Secure-Status und Ziel-PID. Text wird primär über `kAXSelectedTextAttribute`, ersatzweise über Unicode-CGEvents eingesetzt. Der produktive Pfad schreibt keinen Nutztext in `NSPasteboard.general`.

Whisper-CLI und Tiny-Modell liegen im App-Bundle. Das Modell wird vor Inferenz auf Grösse und SHA-256 geprüft. Die App besitzt Timeouts, räumt temporäre Artefakte auf und redigiert sensible JSON-Felder. Native Fenster decken Einstellungen, Berechtigungen und About ab; die Übersetzungsoption ist sichtbar als lokal, aber nicht verfügbar gekennzeichnet.

## C. Validierung

Automatisiert bestanden:

- Core-Unit-Tests: 6/6.
- Aufnahme-/Berechtigungsmatrix: 8/8.
- Transkription/Einfügung: normaler Erfolg, leeres Transkript, zu kurzes Transkript, Accessibility-Block und fehlendes Modell.
- Bundle-, Signatur-, Modell-, Abhängigkeits- und DMG-Prüfungen.

Real bestanden:

- Englische lokale Transkription unter vollständig gesperrtem Netzwerk.
- Deutsche lokale Transkription unter vollständig gesperrtem Netzwerk. Tiny-Ergebnis: `pro Schreit verarbeitet sprache vollständig lokal auf diese Mac.`
- Englisch → Deutsch im isolierten lokalen Argos-Spike: `PushWrite verarbeitet die Sprache vollständig auf diesem Mac und sendet das Transkript niemals an einen Server.`; Laden 0,149 s, Inferenz 0,318 s, maximale RSS rund 263 MB.
- Deutsch → Englisch im isolierten lokalen Argos-Spike: `PushWrite processes language entirely on this Mac and never sends the transcript to a server.`; Laden 0,069 s, Inferenz 0,174 s, maximale RSS rund 251 MB.
- Start der installierten App aus `/Applications`.

Nicht ausgeführt: vollständige UI-Matrix mit VoiceOver/allen Skalierungen, sauberer macOS-13-Testrechner, TCC-Erstdialog nach Reset sowie Gatekeeper/Notarisierung mit Developer ID. Details stehen im Testreport.

## D. Security und Privacy

Der Standardscan fand keine verbleibende reportable Schwachstelle im ausgelieferten Laufzeitpfad. Behoben wurden Clipboard-Exposition, persistente sensible QA-Artefakte im Produktmodus, ungeschützte lokale Control-Verzeichnisse, fehlende Modellintegritätsprüfung und dynamische Repository-Abhängigkeiten. Im produktiven Bundle gibt es keine Netzwerk-API und damit keine Übertragung von Nutzinhalten. Verbleibende Risiken sind im Security-Report eingestuft.

## E. Artefakte

- App: `build/releases/PushWrite-0.2.0-alpha.1/PushWrite.app`, CDHash `b0319764ca8f93b537c1f10356b6fca086e8e9ba`
- DMG: `build/releases/PushWrite-0.2.0-alpha.1/PushWrite-0.2.0-alpha.1-macos-arm64.dmg`, SHA-256 `84939ecd87ef91cd1c5299f1cc6e1e2007a800fc314fe25d1c2ee8c1f251526e`
- ZIP: `build/releases/PushWrite-0.2.0-alpha.1/PushWrite-0.2.0-alpha.1-macos-arm64.zip`, SHA-256 `2d7da771bb4268fa8b9be3ab633278d3a2c2528ba9fe45e898fa67cd388843fd`
- Icon: `app/macos/PushWrite/Assets/PushWrite.icns`, SHA-256 `0c01b07d3fa297cd25287fe908967e4f920a76a8b9896a3f218aace7b7c22211`
- Whisper-Modell: `models/ggml-tiny.bin`, SHA-256 `be07e048e1e599ad46341c8d2a135645097a538221678b7acdd1b1919c6e1b21`
- Übersetzungsmodelle: nicht ausgeliefert; geprüfte temporäre Binärdateien sind in `docs/architecture/local-translation.md` dokumentiert
- Testreport: `docs/testing/0.2.0-alpha.1-test-matrix.md`
- Security-Report: `docs/security/0.2.0-alpha.1-security-review.md`
- Release Notes: `docs/releases/0.2.0-alpha.1.md`
- Lizenzen: `THIRD_PARTY_NOTICES.md`

## F. Externe Blocker

Developer-ID-Zertifikat und Notarisierungsprofil fehlen lokal. Dies ist extern, weil nur der Apple-Developer-Kontoinhaber Identität und Notarisierungs-Credentials bereitstellen kann. Implementierung, ad-hoc-Hardened-Runtime-Signierung, ZIP/DMG, Checksummen und Installationstest sind abgeschlossen. Nächster Schritt: `PUSHWRITE_CODESIGN_IDENTITY` und `PUSHWRITE_NOTARY_PROFILE` setzen und `./scripts/build_pushwrite_alpha_release.sh` erneut ausführen.

## G. Endurteil

`READY FOR ALPHA TEST AFTER SIGNING`
