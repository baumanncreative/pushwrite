# Auftrag 003C: Accessibility-Trust-Drift ueber Rebuild-, Bundle- und Launch-Pfade auf macOS eingrenzen

## Ziel

Pruefe und dokumentiere, warum PushWrite im Entwicklungs- und QA-Alltag wiederholt wie "nicht freigegeben fuer Bedienungshilfen" wirken kann, obwohl Accessibility zuvor bereits aktiviert wurde.

Der Auftrag dient nicht dazu, sofort neue Produktlogik einzubauen.  
Er dient dazu, die reale Ursache des beobachteten Accessibility-Trust-Drifts sauber einzugrenzen, damit danach entschieden werden kann, ob:

- das Problem primaer am Bundle-/Signatur-/Pfad-Wechsel haengt,
- der Launch-Pfad verfälscht,
- ein Produktpfad unklar ist,
- oder ein echter Nachschnitt im Produkt noetig wird.

---

## Ausgangslage

Der bestehende PushWrite-Kern ist produktnah vorhanden:

- globaler Hotkey
- Recording
- lokale Inferenz
- Insert am Cursor
- Gate fuer `empty|tooShort`
- minimale Rueckmeldung fuer Gate-Faelle

Accessibility ist bereits heute eine reale Kernvoraussetzung des bestehenden Produktpfads.

Aus 003 ist gesichert abgeleitet:

- Accessibility-Trust ist fuer den bestehenden Insert-Kern zwingend
- stabile Bundle-Identitaet ist fuer den Accessibility-Trust im aktuellen Produktstand relevant
- ein vormals freigegebenes Produkt kann sich nach Rebuild wieder wie "nicht freigegeben" verhalten
- dieses Thema ist ein realer Blocker fuer ehrliche QA und reproduzierbaren Startfluss

Aus 003B ist zusaetzlich klar:

- der echte LaunchServices-Start des `.app`-Bundles ist fuer belastbare Bundle-/TCC-Aussagen relevant
- direkte Script-/Executable-Starts sind fuer reale TCC-Zurechnung nicht immer belastbar
- das aktuelle Bundle musste fuer realen Bundle-Test bundle-spezifisch Accessibility erhalten

Damit ist das naechste sinnvolle Thema nicht weitere Produktfunktion, sondern die saubere Eingrenzung der beobachteten Accessibility-Trust-Drift im Dev-/QA-Pfad.

---

## Zweck

Dieser Auftrag soll:

- das beobachtete Wiederauftreten von Accessibility-Prompts oder Accessibility-Blockern reproduzierbar eingrenzen
- Bundle-Pfad, Rebuild-Verhalten und Launch-Pfad sauber auseinanderhalten
- Produktproblem, System-/TCC-Verhalten und QA-/Harness-Problem strikt trennen
- eine belastbare Entscheidungsgrundlage liefern, ob danach:
  - nur Dokumentation/Arbeitsregel reicht
  - der Build-/Launch-Pfad angepasst werden muss
  - oder ein kleiner Produktnachschnitt sinnvoll ist

Dieser Auftrag soll **nicht**:

- neue Produktlogik einbauen
- neue UI-Flaechen erstellen
- Insert-Logik umbauen
- neue Permission-Architektur bauen
- allgemeine macOS-Theorie referieren
- Mikrofon- oder Insert-Themen erneut aufrollen

---

## Kernfrage

Der Auftrag soll am Ende genau diese Frage beantworten:

**Unter welchen konkreten Bedingungen bleibt Accessibility-Trust fuer PushWrite stabil, und unter welchen Bedingungen driftet er ueber Rebuild-, Bundle- oder Launch-Pfade sichtbar weg?**

---

## Strenge Grenzen

1. Keine Produktcode-Aenderungen
2. Keine neue UI
3. Keine neue Insert-Methode
4. Keine neue Gate-Logik
5. Keine Vermischung von:
   - Produktproblem
   - bundle-/signatur-/pfadbedingtem Trust-Verhalten
   - Launch-/Harness-Artefakten
6. Kein Ausweiten auf allgemeine Komfort- oder Onboarding-Themen

---

## Arbeitshypothesen

Diese Hypothesen sollen geprueft, nicht vorausgesetzt werden:

### H1
Der beobachtete Accessibility-Trust haengt im aktuellen Dev-/QA-Pfad an der **genauen Bundle-Identitaet** des freigegebenen `.app`-Bundles.

### H2
Ein Rebuild oder Promote-Schritt kann dazu fuehren, dass das System das Ergebnis praktisch wie ein anderes Bundle behandelt oder der Trust fuer den beobachteten Pfad nicht mehr greift.

### H3
Der beobachtete Unterschied entsteht nicht primaer im Produktzustand selbst, sondern durch **verschiedene Startpfade**:
- LaunchServices-Start des `.app`-Bundles
- direkter Executable-Start
- scriptgesteuerter Control-/Validator-Start

### H4
Das Produkt meldet den Zustand moeglicherweise ehrlich, aber der Dev-/QA-Pfad erzeugt wiederholt neue "First-Run"-aehnliche Situationen.

Keine dieser Hypothesen darf vor dem Review als bewiesen behandelt werden.

---

## Pflichtpruefungen

### Phase 1 – Baseline mit real freigegebenem Bundle

Pruefe fuer **genau ein** aktuell freigegebenes Bundle:

- exakter Bundle-Pfad
- Bundle-ID
- beobachteter Accessibility-Zustand im Produkt
- System-TCC-Eintrag fuer Accessibility
- LaunchServices-Start des `.app`-Bundles

Zu dokumentieren:
- bleibt `accessibilityTrusted=true` ueber wiederholte Starts desselben unveraenderten Bundles stabil?
- erscheint trotzdem erneut ein Prompt oder Blocker?
- falls ja: bei welchem exakten Startpfad?

### Phase 2 – Rebuild-/Bundle-Drift

Pruefe danach eng, was nach einem realen Rebuild passiert.

Mindestens zu unterscheiden:

1. **derselbe Bundle-Pfad, neuer Rebuild**
2. **anderer Bundle-Pfad / neues Runtime-Ziel**
3. **gleiches `.app``, aber anderer Launch-Pfad**

Zu dokumentieren:
- welcher Pfad behaelt den beobachteten Trust
- welcher Pfad verliert ihn
- ob der Verlust im Produktzustand, im System-TCC oder nur in der Startmethode sichtbar wird

### Phase 3 – Launch-Pfad-Trennung

Vergleiche fuer denselben Produktstand nur so weit noetig:

- `open .../PushWrite.app --args ...`
- direkter Executable-Start
- bestehender Control-/Validator-Start, falls relevant

Nicht Ziel ist breite Automationsarbeit.  
Ziel ist nur die saubere Frage:

**Welcher Startpfad ist fuer reale Accessibility-Aussagen belastbar, und welcher verfälscht die Beobachtung?**

---

## Zu dokumentierende Beobachtungen

Pro Lauf mindestens:

- exakter Bundle-Pfad
- Bundle-ID
- Startmethode
- ob das Bundle seit der letzten Freigabe neu gebaut oder ersetzt wurde
- beobachteter `accessibilityTrusted`-Zustand
- beobachteter `blockedReason`, falls vorhanden
- ob ein Prompt / Setup-Blocker erschien
- ob der Hotkey-Lauf deshalb direkt blockierte
- ob der Insert-Pfad wegen Accessibility blockierte
- relevante Evidenzdateien
- System-TCC-Befund, soweit real und ohne Scope-Drift pruefbar

---

## Bewertungslogik

Jeder Befund muss genau einer dieser Kategorien zugeordnet werden:

### A. Trust stabil bestaetigt
Der freigegebene Bundle-/Launch-Pfad behaelt den Accessibility-Trust reproduzierbar.

### B. Bundle-/Rebuild-Drift bestaetigt
Der Trust driftet reproduzierbar bei Rebuild, Bundle-Ersatz oder Pfadwechsel.

### C. Launch-Pfad-Artefakt bestaetigt
Der Unterschied entsteht primaer durch die Startmethode, nicht durch den Produktkern.

### D. Produktproblem plausibel
Der Produktpfad meldet oder behandelt Accessibility moeglicherweise inkonsistent.

### E. Nicht belastbar beurteilbar
Der Testaufbau laesst keine saubere Zuordnung zu.

---

## Erwartetes Ergebnis

Am Ende soll **keine Code-Aenderung**, sondern ein Diagnosebefund stehen mit:

1. kurzer Zusammenfassung
2. geprueften Bundle-/Launch-Konstellationen
3. Beobachtungen pro Konstellation
4. sauberer Trennung von:
   - Produktpfad
   - Bundle-/Trust-Drift
   - Launch-Pfad-Artefakt
5. klarer Gesamtentscheidung:
   - primär Bundle-/Rebuild-Thema
   - primär Launch-Pfad-Thema
   - oder Produktnachschnitt plausibel
6. genau einer Empfehlung fuer den naechsten Schritt

---

## Abnahmekriterien

Der Auftrag ist abgeschlossen, wenn:

- mindestens ein real freigegebenes Bundle als Baseline dokumentiert ist
- mindestens ein Rebuild-/Bundle-Wechsel gegen diese Baseline geprueft wurde
- mindestens zwei relevante Startpfade gegeneinander eingegrenzt wurden
- klar ist, ob der beobachtete Drift eher an Bundle-/Rebuild-Wechseln oder eher an der Startmethode haengt
- keine Produktcode-Aenderungen vorgenommen wurden
- am Ende genau eine klare Handlungsempfehlung vorliegt

---

## Nicht-Ziele

Nicht Teil dieses Auftrags sind:

- neue Produktimplementierung
- neue Accessibility-UI
- breite macOS-Permission-Forschung
- erneute Mikrofon-Revalidierung
- breiter App-Kompatibilitaetstest
- neuer Insert-Nachschnitt
- allgemeines UX-Polishing

---

## Erwartete Ergebnisdateien

Nach Ausfuehrung dieses Auftrags sollen die Resultate in folgenden Dateien festgehalten werden:

- `docs/execution/003C-results-review-accessibility-trust-drift-across-rebuild-bundle-and-launch-paths-on-macos.md`
- `docs/execution/003C-results-review-accessibility-trust-drift-across-rebuild-bundle-and-launch-paths-on-macos.json`

---

## Kurzform fuer Codex

Fuehre keinen neuen Entwicklungsauftrag aus, sondern einen engen Diagnoseauftrag zur Accessibility-Trust-Drift. Pruefe, unter welchen Bedingungen ein freigegebenes PushWrite.app-Bundle seinen beobachteten Accessibility-Trust stabil behaelt oder nach Rebuild, Bundle-Ersatz oder anderem Startpfad wieder wie "nicht freigegeben" wirkt. Trenne sauber zwischen Produktpfad, Bundle-/Rebuild-Drift und Launch-Pfad-Artefakt. Fuehre keine Code-Aenderungen ein.