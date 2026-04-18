# Auftrag 002N: Robustheit der bestehenden Textinjektion in typischen macOS-App-Kontexten pruefen und dokumentieren

## Ziel

Pruefe die Robustheit des bestehenden PushWrite-Insert-Pfads in wenigen typischen realen macOS-Zielkontexten und dokumentiere die Beobachtungen so, dass danach eine belastbare Entscheidung moeglich ist, ob reine Dokumentation ausreicht oder ein spaeterer technischer Nachschnitt notwendig wird.

Der Auftrag dient nicht dazu, eine neue Insert-Methode zu bauen oder die bestehende Insert-Logik umzubauen.

---

## Ausgangslage

Der funktionale MVP-Kern von PushWrite ist bereits vorhanden:

- Hotkey
- Recording
- lokale Inferenz
- Insert am Cursor
- Gate fuer `empty|tooShort`
- minimale Rueckmeldung fuer Gate-Faelle

002L ist abgeschlossen.  
002M ist als Pruefauftrag abgeschlossen und hat ergeben, dass fuer den MVP keine weitere Code-Aenderung noetig ist.

Der aktuell wichtigste verbleibende produktnahe Hebel ist deshalb nicht Audio, nicht Inferenz und nicht Gate-Feedback, sondern die Frage:

**Wie robust funktioniert die bestehende Textinjektion in typischen realen macOS-App-Kontexten?**

---

## Zweck

Dieser Auftrag soll den offenen Schritt 002N sauber und enger neu aufsetzen.

Er soll:

- die bestehende Textinjektion pruefen
- reale Grenzen sichtbar machen
- Produktproblem und Test-Harness-Problem sauber trennen
- eine belastbare Entscheidungsgrundlage liefern

Er soll **nicht**:

- neue Insert-Methoden einfuehren
- Accessibility-Strategien erweitern
- allgemeine GUI-Testarchitektur aufbauen
- AppleScript-/System-Events-Automation breit ausbauen
- allgemeines Stabilitaetsprogramm fuer v0.2 aufmachen

---

## Wichtige Leitplanken

1. **Keine Code-Aenderung am bestehenden Insert-Pfad**
   - kein zweiter Insert-Weg
   - keine neue Insert-Methode
   - keine Aenderung an Gate-Logik oder Feedback-Logik

2. **Pruefen statt reparieren**
   - zuerst beobachten
   - dann dokumentieren
   - erst danach bewerten

3. **Keine Harness-Drift**
   - wenn AppleScript, System Events oder andere GUI-Automation selbst zum Hauptproblem werden, muss das offen dokumentiert und vom Produktpfad getrennt werden
   - in diesem Fall den Testansatz enger schneiden statt neue Testinfrastruktur aufzubauen

4. **Kleiner, kontrollierbarer Scope**
   - wenige Kontexte
   - keine breite App-Matrix
   - keine langen Hängeläufe ohne Erkenntnisgewinn

---

## Pruefumfang

### Phase 1 – Pflichtkontexte

Es werden genau diese Kontexte geprueft:

1. **TextEdit** als native Baseline
2. **Safari-Textarea** als Web-Baseline

### Phase 2 – optionale Fremd-Baseline

3. **Genau eine** Drittanbieter-App, aber nur wenn sie ohne fragile System-Events-/AppleScript-Automation sinnvoll und kontrollierbar testbar ist

Wichtig:

- nicht mehrere Drittanbieter-Apps gleichzeitig
- wenn bereits TextEdit oder Safari nur ueber fragile Automation belastbar pruefbar waeren, wird **keine** Drittanbieter-App hinzugefuegt

---

## Prueffragen

Fuer jeden Zielkontext soll beantwortet werden:

1. Laesst sich der bestehende PushWrite-Insert-Pfad in diesem Kontext sinnvoll pruefen?
2. Funktioniert der bestehende Insert-Pfad dort beobachtbar?
3. Falls nicht: liegt das Problem plausibel im Produktpfad oder im Test-Harness?
4. Falls die Lage unklar bleibt: was genau blockiert die Aussagefaehigkeit?
5. Reicht die Beobachtung fuer Dokumentation oder deutet sie auf spaeteren technischen Nachschnitt hin?

---

## Strikte Trennung in der Bewertung

Jede Beobachtung muss genau einer dieser Kategorien zugeordnet werden:

### A. Produktpfad funktioniert
- beobachtbare Einfuegung im Zielkontext
- kein Hinweis auf ein Produktproblem in diesem Kontext

### B. Produktpfad funktioniert mit Einschraenkung
- grundsaetzlich funktional
- aber mit klar benennbarer Grenze oder reduzierter Robustheit

### C. Produktproblem plausibel
- beobachtete Symptome sprechen eher fuer ein Problem des bestehenden Insert-Pfads
- aber noch kein harter Nachweis

### D. Produktproblem nachgewiesen
- beobachtete Symptome lassen sich belastbar dem Produktpfad zuordnen

### E. Test-Harness-/Automation-Problem
- die eigentliche Blockade liegt in der Testmethode
- keine belastbare Aussage ueber den Produktpfad moeglich

### F. Nicht belastbar beurteilbar
- weder funktionaler Erfolg noch klare Problemzuordnung moeglich
- Grund muss konkret benannt werden

---

## Durchfuehrungsregeln

- Keine Scope-Ausweitung waehrend des Laufs
- Keine breiten Umwege ueber Mail, Nachrichten oder weitere GUI-lastige Sonderfaelle
- Keine neue Testarchitektur
- Keine Vermischung von Produktbeobachtung und Automationsfehlern
- Keine voreilige technische Loesung vorschlagen, solange die Beobachtungslage nicht sauber ist

Wenn ein Lauf haengt oder der Erkenntniskanal kippt, ist abzubrechen und sauber zu dokumentieren:

- was getestet wurde
- woran es hing
- warum das ein Harness-Problem ist oder sein koennte
- warum deshalb keine belastbare Produktaussage moeglich war

---

## Erwartetes Ergebnis

Am Ende soll **keine Code-Aenderung** stehen, sondern ein sauberer Befund mit:

1. kurzer Zusammenfassung
2. geprueften Zielkontexten
3. Beobachtungen pro Zielkontext
4. klarer Trennung zwischen Produktpfad-Problem und Harness-/Automation-Problem
5. Gesamtbewertung:
   - Dokumentation reicht vorerst
   - oder spaeterer technischer Nachschnitt ist begruendet
6. klare Empfehlung fuer den naechsten Schritt

---

## Abnahmekriterien

Der Auftrag ist abgeschlossen, wenn:

- TextEdit dokumentiert bewertet ist
- Safari-Textarea dokumentiert bewertet ist
- eine Drittanbieter-App nur dann enthalten ist, wenn sie ohne Drift sinnvoll pruefbar war
- Produktpfad-Problem und Harness-Problem nirgends vermischt werden
- keine Code-Aenderung am Insert-Pfad vorgenommen wurde
- keine neue Insert-Methode eingefuehrt wurde
- keine allgemeine Testarchitektur entstanden ist
- am Ende eine belastbare Entscheidungsvorlage vorliegt

---

## Erwartete Ergebnisdateien

Nach Ausfuehrung dieses Auftrags sollen die Resultate in folgenden Dateien festgehalten werden:

- `docs/execution/002N-results-review-insert-robustness-in-typical-macos-app-contexts.md`
- `docs/execution/002N-results-review-insert-robustness-in-typical-macos-app-contexts.json`

---

## Wichtige Abgrenzung

Nicht erneut aufrollen:

- Produktname
- Whisper.cpp als MVP-Basis
- grundsaetzliche Tragfaehigkeit des bestehenden Pasteboard/Cmd+V-Pfads
- Existenz des End-to-End-Pfads bis Insert
- Gate fuer `empty|tooShort`
- 002M als offener Schritt

Diese Punkte gelten fuer diesen Auftrag als gesetzt.

---

## Kurzform fuer Codex

Pruefe den bestehenden PushWrite-Insert-Pfad nur in TextEdit, Safari-Textarea und hoechstens einer robust testbaren Drittanbieter-App. Dokumentiere pro Kontext sauber, ob der bestehende Produktpfad funktioniert, nur eingeschraenkt funktioniert, plausibel problematisch ist oder ob die eigentliche Blockade im Test-Harness liegt. Nimm keine Code-Aenderung am Insert-Pfad vor und erweitere keine GUI-/AppleScript-/System-Events-Testarchitektur.