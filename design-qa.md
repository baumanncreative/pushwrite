# PushWrite 0.3.2 Design QA

## Comparison target

- selected visual direction: Variante 3
- persistent reference: `docs/qa/pushwrite-0.3.2-variant-3-reference.png`
- final implementation capture: `docs/qa/pushwrite-0.3.2-implementation-pass-4.png`
- final combined comparison: `docs/qa/pushwrite-0.3.2-design-comparison-pass-4.png`
- compared state: active recording at `00:18`, Swiss German input, System output, permissions granted
- native viewport: AppKit popover content `520 x 630` points
- reference pixels after proportional normalization: `601 x 727`
- implementation capture pixels: `592 x 728`, including native popover border and pointer

The implementation capture uses the deterministic native preview fixture. It does not claim that a real microphone session happened at capture time. Production duration, audio level, language, permission and workflow values are wired to the application snapshot and are covered separately by product and UI tests.

## Full-view comparison

The final comparison preserves the selected hierarchy and interaction model: product header, one red settings gear, recording status, dominant timer, live level, hold-to-speak keys, four workflow phases, languages, local processing, permissions, bottom-left quit action and offline assurance.

Required fidelity surfaces:

- typography: Futura Medium for display text and Arial for body text, with documented system fallbacks
- spacing: consistent 20-point outer inset, compact section rhythm and 10-point card radii without overlap or clipping
- handbook palette: black and dark neutral surfaces, `#F4F4F4` primary text, restrained grey secondary text and `#C00000` for action or active-state emphasis
- success semantics: green is limited to affirmative local-processing and permission states and meets the required contrast on the dark surface
- icons: native SF Symbols plus the existing PushWrite asset; no placeholder imagery or emoji
- copy: German/Swiss-standard product text, accurate local-processing claim and no duplicated settings action

## Findings

- P0: none
- P1: none
- P2: none
- P3 accepted native adaptation: the real audio signal is shown by an accessible continuous AppKit level indicator instead of the decorative multi-bar waveform in the reference.

## Comparison history

### Pass 1

- findings: only three workflow phases; recording timer and active-state hierarchy too weak
- fixes: added `Textverarbeitung`, enlarged and centred the timer, integrated the recording status and added visible local-processing state

### Pass 2

- findings from code and accessibility review: transforming state was not reached by the production flow; settings windows could duplicate; status text, meter and workflow needed stronger non-colour semantics
- fixes: added the real transforming transition, reused the existing settings controller, added accessibility labels and values, and made the active workflow label explicit

### Pass 3

- evidence: `docs/qa/pushwrite-0.3.2-design-comparison-pass-3.png`
- P2: disabled AppKit buttons dimmed the static shortcut keycaps and the successful permission labels
- fixes: replaced shortcut buttons with static accessible keycap labels and kept permission actions enabled so AppKit no longer lowers their contrast

### Pass 4

- evidence: `docs/qa/pushwrite-0.3.2-design-comparison-pass-4.png`
- result: selected layout, single settings entry, bottom-left quit action, hierarchy, contrast and four-stage workflow are resolved with no actionable P0, P1 or P2 finding

## Implementation checklist

- [x] one red top-right settings gear
- [x] no bottom settings action
- [x] bottom-left `PushWrite beenden`
- [x] real recording duration and audio level bindings
- [x] four-stage workflow retained for 0.3.2
- [x] company-handbook palette and typography applied
- [x] permission and language states remain functional
- [x] persistent visual evidence stored in the repository

final result: passed
