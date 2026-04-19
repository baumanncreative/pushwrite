# 003C Results: Accessibility-Trust-Drift ueber Rebuild-, Bundle- und Launch-Pfade auf macOS

## 1) Kurze Zusammenfassung

Kernfrage:

**Unter welchen Bedingungen bleibt Accessibility-Trust stabil, und wann driftet er?**

Befund:

- Auf dem zuvor freigegebenen Stable-Bundle (`CDHash=f6d473...`) bleibt der beobachtete Trust bei wiederholtem LaunchServices-Start stabil (`preflight: ready`, `accessibilityTrusted=true`).
- Nach Bundle-Wechsel auf ein anderes Artefakt (`CDHash=461a4e...`) driftet der Trust im **LaunchServices-Pfad** reproduzierbar weg (`preflight/insert: blocked`, Accessibility-Blocked-Reason).
- Fuer dasselbe ersetzte Bundle zeigen **Direct-Executable** und **Control-Wrapper** gleichzeitig `ready/succeeded` statt `blocked`.
- Nach Rollback auf das urspruengliche Stable-Artefakt (`CDHash=f6d473...`) ist der LaunchServices-Pfad wieder stabil `ready/true`.

Gesamtentscheidung:

- **Primaer Bundle-/Rebuild-Thema (B)**
- mit zusaetzlichem **Launch-Pfad-Artefakt (C)**, das QA-Ergebnisse verfälschen kann.

Keine Produktcode-Aenderungen wurden vorgenommen.

## 2) Testaufbau und Evidenzbasis

Haupt-Evidenzwurzel:

- `/tmp/pushwrite-003c/matrix-20260419T055834Z`

Wichtige Identitaetsnachweise:

- Stable vor Test: `/tmp/pushwrite-003c/matrix-20260419T055834Z/identity/stable-before.txt`
- Old Candidate: `/tmp/pushwrite-003c/matrix-20260419T055834Z/identity/old-candidate-before.txt`
- Stable nach Promote: `/tmp/pushwrite-003c/matrix-20260419T055834Z/identity/stable-after-promote.txt`
- Stable nach Rollback: `/tmp/pushwrite-003c/matrix-20260419T055834Z/identity/stable-after-rollback.txt`
- Stable final bestaetigt: `/tmp/pushwrite-003c/matrix-20260419T055834Z/identity/stable-after-reprobe-rollback.txt`

TCC-Reprobe (vor/nach Promote/Rollback):

- `/tmp/pushwrite-003c/matrix-20260419T055834Z/tcc/tcc-reprobe-before.txt`
- `/tmp/pushwrite-003c/matrix-20260419T055834Z/tcc/tcc-reprobe-after-promote.txt`
- `/tmp/pushwrite-003c/matrix-20260419T055834Z/tcc/tcc-reprobe-after-rollback.txt`

System-TCC-Row blieb in dieser Sequenz unveraendert:

- `kTCCServiceAccessibility|ch.baumanncreative.pushwrite|0|2|4|1776533278|40`

## 3) Gepruefte Bundle-/Launch-Konstellationen

| Fall | Bundle-Pfad | CDHash | Startmethode | Rebuild/Replace seit Freigabe | Beobachtung |
| --- | --- | --- | --- | --- | --- |
| phase1_stable_ls_run1 | `build/pushwrite-product/PushWrite.app` | `f6d473...` | LaunchServices (`open -n ...`) | nein | `preflight=ready`, `insert=succeeded`, `accessibilityTrusted=true` |
| phase1_stable_ls_run2 | `build/pushwrite-product/PushWrite.app` | `f6d473...` | LaunchServices | nein | erneut stabil `ready/true` |
| phase3_stable_direct | `build/pushwrite-product/PushWrite.app` | `f6d473...` | Direct Executable | nein | `ready/true` |
| phase3_stable_control | `build/pushwrite-product/PushWrite.app` | `f6d473...` | Control-Wrapper | nein | `ready/true` |
| phase2_old_candidate_ls | `build/pushwrite-product-candidate/PushWrite.app` | `461a4e...` | LaunchServices | ja (anderes Bundle) | `preflight/insert=blocked`, Accessibility-Reason |
| phase2_same_path_after_promote_ls | `build/pushwrite-product/PushWrite.app` | `461a4e...` | LaunchServices | ja (same path, replaced via promote) | `preflight/insert=blocked`, Accessibility-Reason |
| phase2_same_path_after_promote_direct | `build/pushwrite-product/PushWrite.app` | `461a4e...` | Direct Executable | ja | `ready/true` |
| phase2_same_path_after_promote_control | `build/pushwrite-product/PushWrite.app` | `461a4e...` | Control-Wrapper | ja | `ready/true` |
| phase2_stable_after_rollback_ls | `build/pushwrite-product/PushWrite.app` | `f6d473...` | LaunchServices | rollback auf urspruengliches Bundle | wieder `ready/true` |

## 4) Beobachtungen pro Konstellation (Pflichtfelder)

Hinweis zu Prompt/Setup-Blocker:

- Kein visueller Prompt-Screenshot erfasst; Feld daher als `nicht direkt beobachtet` markiert.
- In blocked-Faellen ist der Produkt-Blocked-Reason konsistent vorhanden.

### Phase 1 Baseline (real freigegebenes Bundle)

1. `phase1_stable_ls_run1`
- `bundlePath`: `/Users/michel/Code/pushwrite/build/pushwrite-product/PushWrite.app`
- `bundleID`: `ch.baumanncreative.pushwrite`
- `startMethod`: `launchservices_open`
- `bundleNeuSeitFreigabe`: `false`
- `accessibilityTrusted`: `true`
- `blockedReason`: `null`
- `promptOderSetupBlocker`: `nicht direkt beobachtet`
- `hotkeyDirektBlockiertDurchAccessibility`: `nicht ausgefuehrt in diesem Lauf`
- `insertWegenAccessibilityBlockiert`: `nein` (`status=succeeded`)
- Evidenz: `.../cases/phase1_stable_ls_run1/evidence/*`

2. `phase1_stable_ls_run2`
- gleiches Bundle, gleiche Startmethode, erneut `accessibilityTrusted=true`, `insert=succeeded`
- Trust blieb ueber wiederholten unveraenderten LS-Start stabil.
- Evidenz: `.../cases/phase1_stable_ls_run2/evidence/*`

### Phase 2 Rebuild-/Bundle-Drift

3. `phase2_old_candidate_ls` (anderer Bundle-Pfad)
- `bundlePath`: `/Users/michel/Code/pushwrite/build/pushwrite-product-candidate/PushWrite.app`
- `bundleCDHash`: `461a4ebc...`
- `startMethod`: `launchservices_open`
- `bundleNeuSeitFreigabe`: `true`
- `accessibilityTrusted`: `false`
- `blockedReason`: `Accessibility access is required before PushWrite can insert text with synthetic Cmd+V.`
- `hotkeyDirektBlockiertDurchAccessibility`: `nicht ausgefuehrt in diesem Lauf`
- `insertWegenAccessibilityBlockiert`: `ja` (`status=blocked`, `syntheticPastePosted=false`)
- Evidenz: `.../cases/phase2_old_candidate_ls/evidence/*`

4. `phase2_same_path_after_promote_ls` (same path, replaced bundle)
- `bundlePath`: `/Users/michel/Code/pushwrite/build/pushwrite-product/PushWrite.app`
- `bundleCDHash`: `461a4ebc...` (nach Promote)
- `startMethod`: `launchservices_open`
- `bundleNeuSeitFreigabe`: `true` (Replace am selben Pfad)
- `accessibilityTrusted`: `false`
- `blockedReason`: gleich wie oben
- `insertWegenAccessibilityBlockiert`: `ja`
- Evidenz: `.../cases/phase2_same_path_after_promote_ls/evidence/*`

5. `phase2_stable_after_rollback_ls`
- Rollback zurueck auf `CDHash=f6d473...`
- `startMethod`: `launchservices_open`
- `accessibilityTrusted`: `true`
- `insertWegenAccessibilityBlockiert`: `nein`
- Evidenz: `.../cases/phase2_stable_after_rollback_ls/evidence/*`

### Phase 3 Launch-Pfad-Trennung

6. `phase3_stable_direct` und `phase3_stable_control` (stable `f6d473...`)
- beide `ready/true`, kein Accessibility-Block.

7. **Gleicher ersetzter Produktstand (`CDHash=461a4e...`) mit verschiedenen Startpfaden**
- `phase2_same_path_after_promote_ls`: `blocked/false`
- `phase2_same_path_after_promote_direct`: `ready/true`
- `phase2_same_path_after_promote_control`: `ready/true`

Interpretation:

- Fuer realistische Accessibility-Aussagen ist der LaunchServices-Pfad belastbar.
- Direct/Control koennen im Drift-Zustand einen false-green Eindruck erzeugen.

## 5) Zusatzlauf Hotkey (direkte Blockierbeobachtung)

Matrixlaeufe hatten keinen expliziten Hotkey-Trigger je Fall. Deshalb wurden zwei gezielte Zusatzlaeufe ausgefuehrt:

1. Stable LS Hotkey-Probe
- Runtime: `/tmp/pushwrite-003c/hotkey-probe-stable-ls`
- Response: `status=failed`, `kind=recordAudio`, `accessibilityTrusted=true`, **kein Accessibility-Block**
- Evidenz: `/tmp/pushwrite-003c/hotkey-probe-stable-ls/logs/last-hotkey-response.json`

2. Old-Candidate LS Hotkey-Probe
- Runtime: `/tmp/pushwrite-003c/hotkey-probe-old-candidate-ls`
- Response: `status=blocked`, `kind=insertTranscription`, `accessibilityTrusted=false`, `blockedReason=Accessibility ... required`
- Evidenz: `/tmp/pushwrite-003c/hotkey-probe-old-candidate-ls/logs/last-hotkey-response.json`

Damit ist der Hotkey-Blocked-Fall im Drift-Zustand direkt bestaetigt.

## 6) Zuordnung A-E

- **A (Trust stabil bestaetigt):**
  - `phase1_stable_ls_run1`
  - `phase1_stable_ls_run2`
  - `phase3_stable_direct`
  - `phase3_stable_control`
  - `phase2_stable_after_rollback_ls`
  - `hotkey-probe-stable-ls` (kein Accessibility-Block)

- **B (Bundle-/Rebuild-Drift bestaetigt):**
  - `phase2_old_candidate_ls`
  - `phase2_same_path_after_promote_ls`
  - `hotkey-probe-old-candidate-ls`

- **C (Launch-Pfad-Artefakt bestaetigt):**
  - Vergleich desselben ersetzten Bundles (`CDHash=461a4e...`):
    - LaunchServices `blocked/false`
    - Direct + Control `ready/true`

- **D (Produktproblem plausibel):**
  - nicht belegt

- **E (nicht belastbar):**
  - nicht belegt fuer die Kernfrage

## 7) Saubere Trennung der Ursachen

Produktpfad:

- In allen beobachteten blocked-Faellen wird derselbe Accessibility-Blocked-Reason konsistent geliefert.
- Insert wird im blocked-Fall konsistent unterbunden (`syntheticPastePosted=false`).

Bundle-/Trust-Drift:

- Wechsel von `f6d473...` auf `461a4e...` korreliert mit Trust-Verlust im LS-Pfad.
- Rollback auf `f6d473...` stellt LS-Trust wieder her.

Launch-/Harness-Artefakt:

- Beim gleichen ersetzten Bundle liefern Direct/Control `ready/true`, waehrend LS `blocked/false` liefert.
- Control-Wrapper meldet bei diesem aelteren State-Schema zwar `launch timeout`, das Runtime liefert aber verwertbare Responses. Das ist ein Harness-Indikator, kein Produktkernbefund.

System-TCC-Befund:

- System-Row blieb ueber Promote/Rollback gleich, obwohl LS-Verhalten zwischen Bundles wechselte.
- Praktisch relevant fuer QA bleibt daher: beobachteter Trust haengt an der konkreten Bundle-Identitaet im realen LS-Pfad.

## 8) Klare Gesamtentscheidung

**Primaer Bundle-/Rebuild-Thema, mit zusaetzlichem Launch-Pfad-Artefakt.**

## 9) Genau eine Empfehlung fuer den naechsten Schritt

Fuehre eine verbindliche QA-Arbeitsregel ein:

- **Accessibility-Trust-Aussagen nur ueber LaunchServices-Start des freigegebenen Stable-Bundles mit dokumentiertem Bundle-Pfad + CDHash treffen; Direct-/Control-Starts duerfen fuer diesen Befund nur als Nebenbeobachtung verwendet werden.**
