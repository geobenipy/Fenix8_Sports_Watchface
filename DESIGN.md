# Beni Watchface — Design Specification

**Target:** fenix 8 43 mm (`fenix843mm`), 416 × 416 px, round, AMOLED, touch, CIQ 6.0.0
**SDK:** `connectiq-sdk-win-9.1.0-2026-03-09-6a872a80b`
**Guiding idea:** all information at a glance, a calm center, goals at the edge.
**Language:** German throughout, 24-hour format — independent of the watch setting.

---

## 1. Color system

There are **three schemes**, switchable on the watch (section 4a). Section 1
consistently describes the **"Full"** scheme; the other two are described in
section 1a as deviations from it.

Technically the colors in `Theme.mc` are therefore `var` and not `const`:
`Theme.applyScheme()` rewrites the table, and all the remaining code only knows
`Theme.STEPS` and needs to know nothing about the schemes. Anyone adding a color
has to handle it in **all three** branches of `applyScheme`.

One rule carries everything: **every metric has exactly one color, and it applies
everywhere.** The steps arc is orange, so everything orange on this watch face is
a statement about steps. Cyan is Body Battery and nothing else. Assigning a color
twice takes away its function and turns it into decoration.

Color sits in **icons, arcs and scales** — not in the numbers. Colored digits on a
black background lose contrast, colored symbols don't. That makes the watch face
colorful and still readable: color in the small shapes, calm in the large ones.

### Base levels

| Level | Hex | Carries |
|---|---|---|
| Background | `#000000` | True black → AMOLED pixels off, saves battery |
| **Primary** | `#FFFFFF` | Time, date, temperature |
| **Value** | `#DDE3EA` | All secondary values, uniform |
| **Label** | `#6B7580` | Labels, units, separators |
| Arc empty | `#252B33` | Unfilled part of the edge ring |

### Metric colors

| Color | Hex | Metric | Appears in |
|---|---|---|---|
| Orange | `#FF6B1A` | Steps | Top-left arc, footprint legend |
| Amber | `#FFB000` | Floors | Top-right arc, stairs legend |
| Magenta | `#FF2E88` | Active minutes | Bottom-right arc, stopwatch legend, unread notifications |
| Cyan | `#00C8FF` | Body Battery | Bottom-left arc, bolt legend, Bluetooth |
| Red | `#FF4438` | Heart rate | Heart icon **and** HR value |
| Light orange | `#FF8C42` | Calories | Flame icon |
| Turquoise | `#00D9B2` | VO₂max | Label "VO2" |
| Green | `#2FD35B` | Running | Runner icon, VO₂max running value, race prediction label |
| Violet | `#A96BFF` | Cycling | Bike icon, VO₂max cycling value |
| Slate | `#8C99A8` | Altitude | Mountain icon (rock; summit in white) |

The mountain is **two-tone**, like the weather symbol: at 18 px only the jump in
brightness separates the shape from the outline. And it spares the color system a
ninth hue that would have found no safe distance between rain blue and cycling
violet anyway.

Heart rate is the only live value on the watch face and therefore the only value
that is colored itself. Everything else carries its color in the symbol.

Two places deliberately break the rule "color only in the symbol", because there
**two values share one element** and the separator would otherwise leave you
guessing which number is which:

- `VO2 54|42` — running value green, cycling value violet, label turquoise, separator grey.
- `72/48` — current pulse red, resting heart rate grey.

This is the same reasoning as for the forecast `21|9°`, just one level deeper.

### Weather colors

| Color | Hex | Carries |
|---|---|---|
| Sun yellow | `#FFD429` | Sun disc, sunset, bolt in a thunderstorm |
| Warm | `#FF9A3D` | Sun rays, forecast high |
| Rain blue | `#4FA3FF` | Drops, forecast low |
| Cloud grey | `#9AA5B1` | Cloud |
| Haze grey | `#7D8794` | Fog, thunderstorm cloud |

The weather symbol is **two-tone**. At 22 px a single-color symbol is barely
decipherable — only the color difference separates cloud from precipitation. And
that makes the conditions recognizable without having to read the shape.

The forecast `21|15°` is colored in three parts: high warm, separator grey, low
cold. As one piece of text you had to read it to know which number is which. In
color you can see it.

### Status scale

For everything that runs from "good" to "bad". Deliberately the same hex values as
green / amber / red — a scale shouldn't open up a color family of its own.

| Level | Hex |
|---|---|
| good | `#2FD35B` |
| medium | `#FFB000` |
| bad | `#FF4438` |

Four elements use it. Here the color doesn't say *what* something is, but *how it
stands*:

| Element | Scale |
|---|---|
| Stress | ≤ 25 good, ≤ 50 medium, above that bad |
| Watch battery | ≥ 30 % good, ≥ 15 % medium, below that bad |
| Recovery time | 0 good, ≤ 6 h medium, above that bad |
| Pressure trend | rising good, falling medium, steady cloud grey |

The battery thresholds are low because a fenix runs for two weeks: 50 % is not a
half warning but a week of peace. A scale that warns at half calls too early and is
therefore ignored. The predecessor made the mistake in the other direction — it
only colored below 15 % and was silent 85 % of the time.

Recovery time runs **the other way round from its number**: few hours left is
green. It is read as "can I train today?", not as a measured value.

### Training status — the only eight-level scale

The training status is the only element without a number and without text: a
rocket, and its color is the whole message. It is therefore the only one that needs
an **eight-level scale of its own** — with the three levels good/medium/bad, eight
states couldn't be told apart.

The colors follow the mapping Garmin itself uses:

| Status | Hex | |
|---|---|---|
| Peaking | `#B35CFF` | violet |
| Productive | `#2FD35B` | green |
| Maintaining | `#3E9BFF` | blue |
| Recovery | `#FFD429` | yellow |
| Unproductive | `#FF8C42` | orange |
| Strained | `#FF6B1A` | strong orange |
| Overreaching | `#C4241A` | dark red |
| Detraining | `#FF4438` | red |
| Paused, No Result, unknown | `#6B7580` | grey |

Violet and strong orange are the same hex families as cycling and steps. That is
the only double assignment in the color system and acceptable here: they never meet
in the same element, and the rocket is unambiguous as a shape.

### Time-of-day color

The weekday in the date carries a color that travels with the day: four anchor
points, mixed linearly channel by channel in between.

| Time | Hex | |
|---|---|---|
| 0 h | `#2B3BAF` | Night indigo |
| 6 h | `#FF8A2B` | Morning orange |
| 12 h | `#00C8FF` | Noon cyan |
| 18 h | `#FF2E88` | Evening magenta |
| 24 h | `#2B3BAF` | Indigo again, so it doesn't jump at midnight |

This is the only color that doesn't categorize anything but tells something — and
the only one that moves.

### State rules

- **Goal reached** → the arc fills completely, **keeps its metric color** and gains
  a white hairline on the outside at radius 204. The predecessor switched to white
  and thereby made exactly the reached goal impossible to assign.
- **Unread notifications** → envelope in magenta, counter at value brightness.
- **Phone disconnected** → Bluetooth symbol in the arc-empty color. The phone's
  absence should be noticeable without looking like a warning.

---

## 1a. The other two schemes

### "Muted" — the same colors, just quieter

**Calculated, not picked.** The brief is "same colors, less glaring", and that is
exactly a formula: every tone moves by the same amount toward *its own* grey
(45 %) and gets darker by the same factor (82 %). Thirty hand-picked values would
be thirty individual decisions that stop matching each other as soon as one of
them is adjusted.

The two numbers were measured on the image, not guessed. A first version with
32 % / 90 % was barely distinguishable from the full version in the simulator —
the VO₂max turquoise only moved from `#00D9B2` to `#2AAF97`. At 55 % the running
green tips into muddy. With 45 % / 82 % the same turquoise becomes `#369687`.

Label and empty arc track stay untouched — they are already neutral, desaturating
them further would only cost contrast. White and value grey drop slightly
(`#E8EBEF` / `#C2C8CF`): on AMOLED pure white is what stands out most.

The eight-level training scale is fully preserved.

### "Calm" — color identifies the kind, not the metric

This is where the basic rule of the color system deliberately breaks. Two families
in two brightness levels each carry almost everything, plus pulse red and sun
yellow. Twelve hues become five.

| Role | Hex | Carries |
|---|---|---|
| warm light | `#E8A857` | Steps, calories, running, warm forecast |
| warm dark | `#C67C33` | Floors |
| cool light | `#7FB6D8` | Body Battery, VO₂max, cycling, rain / cold forecast |
| cool dark | `#4E86AB` | Active minutes, unread notifications |
| Pulse | `#C9584E` | Heart rate |
| Sun | `#E8C15C` | Sun disc, sun cycle |
| Status scale | `#5FA86B` / `#D9A038` / `#C9584E` | good / medium / bad |

That steps, calories and running share a color is no loss: since the ring has its
four legend icons and every data row carries its own symbol, the **shape** tells
what it is about. Color can limit itself to grouping.

Two places keep their distinction regardless, because they would otherwise become
unreadable:

- **The four ring sections.** Light and dark per family, laid crosswise — warm
  light / warm dark at the top, cool light / cool dark at the bottom. That way no
  two equal tones meet at any of the four seams (12, 3, 6, 9 o'clock).
- **The split values** `54|42` and `21|9°`. Warm against cool.

The eight-level training scale collapses into the three levels of the status
scale. That costs information — peaking and maintaining can no longer be told
apart — and is exactly what "fewer colors" means.

The time-of-day color keeps moving, but only within the two families now:
`#3E5A7A` → `#C67C33` → `#7FB6D8` → `#E8A857`.

---

## 2. Geometry

Center `(208, 208)`, radius 208. Usable inner radius **188** (the ring occupies
the edge).

### Edge ring

Four color sections of **84°**, gaps of **6°** at 12, 3, 6 and 9 o'clock.
Radius **195**, stroke width **11 px** → the ring occupies radii 189.5 to 200.5.
Angles in Monkey C convention (0° = 3 o'clock, counterclockwise).

The stroke width used to be 14 px. Thinner, the ring looks like a bezel around the
watch face instead of an instrument of its own — and leaves room inside for the
legend icons. The usable inner radius nevertheless stays at **188**: the one and a
half pixels gained would not make a single row wider, and all row widths are
calculated from 188.

| Section | Anchor | Direction | Metric | Color |
|---|---|---|---|---|
| top-left | 93° | counterclockwise → 177° | Steps / daily goal | Orange |
| top-right | 87° | clockwise → 3° | Floors / daily goal | Amber |
| bottom-left | 267° | clockwise → 183° | Body Battery (0–100) | Cyan |
| bottom-right | 273° | counterclockwise → 357° | Weekly active minutes / goal | Magenta |

Both upper sections grow outwards from 12 o'clock, both lower ones outwards from 6
o'clock — so the fill level is symmetric and readable without thinking.

**Why a 6° gap instead of 20°:** with 20° there were four separate gauge
instruments. With 6° the same layout reads as **one** ring in four color sections —
calmer and more colorful at the same time. The gap stays visible anyway: 6° at
radius 195 is about 20 px of arc length, of which the round caps eat up 14 px,
leaving roughly 6 px.

**Round caps:** `drawArc` draws blunt ends, and at 14 px stroke width four blunt
sections look like a sawn-off ring. The cap is a circle with half the stroke width
on the arc's center line at the respective angle — cheaper than any other solution
and pixel-exact. They are placed at both ends of the empty track **and** both ends
of the fill.

**Quarter marks:** each section is divided by three marks at 25/50/75 %. They are
not lines *on* the arc but 4 px wide gaps in background color *straight through*
it — so they stay visible whether they currently sit on a filled or an empty
background. That makes the fill level readable instead of estimable.

An earlier version drew 10 px wide arcs in `#2A2E33`. On AMOLED black the empty
track was practically invisible — the most striking feature of the watch face
vanished. Width and track brightness are therefore deliberately strong.

### Legend icons of the ring

Four symbols say what the four color sections stand for: footprint (steps), stairs
(floors), bolt (Body Battery), stopwatch (active minutes). They are the only
concession to first contact — whoever knows the watch face reads the colors,
whoever sees it for the first time reads the symbols.

| Icon | Position | Angle | Section |
|---|---|---|---|
| Footprint | (41, 179) | 170° | Steps, top-left |
| Stairs | (375, 179) | 10° | Floors, top-right |
| Bolt | (41, 238) | 190° | Body Battery, bottom-left |
| Stopwatch | (375, 238) | 350° | Active minutes, bottom-right |

They sit **not** in the middle of their section but at its outer end, i.e. near 9
and 3 o'clock. That is no stopgap but the only free area: at the height of the arc
centers (y ≈ 90 and y ≈ 326) the weather, date and data rows run right up to the
ring. Left and right of the time, however, about 60 px each remain unused — exactly
where the four icons sit, at radius 172. The outermost icon corner is then at
radius 180, i.e. 9 px inside the ring.

That also redeems the earlier sentence "why no flanks": the free space next to the
time was never too small for *something*, only too small for label plus value. For
an 18 px symbol it is enough.

### Why the accent bar is gone

Below the time there was a bar of 232 × 6 px showing the progress of the day in the
time-of-day color. It was meant as a resting point — the only element without a
number.

It was dropped because it answered the one question it answered twice: how far the
day is along is already shown 40 px above as the time, and more precisely. The
resting-point idea doesn't justify an area that costs 17 px of vertical rhythm —
and those 17 px are now the fourth data row. The time-of-day color lives on in the
weekday.

### Font sizes (measured on the device)

These values are **measured, not estimated** — an earlier version of this spec
calculated with a 80 px tall time and was off by more than a factor of two.
Anyone changing the rhythm below has to check against this.

| Font | Height | Width "08:09" |
|---|---|---|
| XTINY | 34 | 71 |
| TINY | 43 | 93 |
| SMALL | 50 | 106 |
| MEDIUM | 58 | 124 |
| NUMBER_MILD | 103 | 178 |
| NUMBER_MEDIUM | 141 | 242 |
| NUMBER_HOT | 159 | 273 |
| NUMBER_THAI_HOT | **192** | 332 |

The time uses **NUMBER_MEDIUM**. It is the anchor of the watch face: an earlier
version set it in NUMBER_MILD, which made it barely larger than the data rows below
— the eye found no hold.

`NUMBER_HOT` and larger fail on arithmetic: the digit height pushes all rows
downwards, and on a round display the usable width drops steeply there. At 159 px
row D lands at y ≈ 390, where only a good 100 px of chord remain.

### Usable width — the rule you cut yourself on

Usable width is the chord of the circle with radius 188 at the row's **narrowest
ink edge**. Which edge that is depends on where the row sits:

- **below** the display center → the **bottom edge**
- **above** the display center → the **top edge**

The circle gets narrower toward *both* poles, not just downwards.

This distinction is no subtlety. An earlier version of this spec only knew "always
the bottom edge" and therefore gave the status row ~215 px — that is the chord at
its *bottom edge* (y = 54). It would have needed the one at the *top edge* (y = 26):
**94 px**. The row reached into the edge ring with both ends, the upper corner sat
at radius 199 right in the arc. At y = 20 — the apex of the inner circle — the
usable width is exactly **0**.

Chord widths at radius 188, for checking:

| y | 20 | 26 | 32 | 42 | 48 | 62 | 72 | 102 |
|---|---|---|---|---|---|---|---|---|
| Width | 0 | 94 | 132 | 176 | 197 | 237 | 260 | 311 |

Calculation uses the **ink edge**, not the font box. The fonts have headroom at the
top that no glyph uses, and a descender at the bottom that digits don't reach:

| Font | Height | Ink top | Ink bottom |
|---|---|---|---|
| XTINY | 34 | +7 | +26 |
| TINY | 43 | +10 | +33 |
| SMALL | 50 | +11 | +38 |
| NUMBER_MEDIUM | 141 | +15 | +121 |

### Layout: outside on top, inside below

The watch face is mirrored at the time. **Above** it sits what comes from outside —
connection, battery, weather, date, sun cycle. **Below** it, what the body reports —
pulse, calories, stress, form, recovery, predictions, weekly volumes.

This is the only structure the watch face has, and it replaces any divider line:
after two glances you know which half to look in.

### Vertical rhythm

| y | Row | Font | Content | Width |
|---|---|---|---|---|
| 36 | Status | XTINY | Bluetooth · `✉ 3` · battery `14d` | **172 px** |
| 67 | Weather | XTINY | `⛅ 18°` · `21\|9°` · `▲ 1013` | 255 px |
| 95 | Date | TINY + XTINY | `DO · 30.07.` · `🌇 21:14` | 300 px |
| 120 | **Time** | NUMBER_MEDIUM | `10:24` + seconds in SMALL | 346 px |
| 248 | Row A | XTINY | `♥ 72/48` · `🔥 1842` · `▄▆█ 22` | 310 px |
| 280 | Row B | XTINY | Rocket · `VO2 54\|42` · `⌛ 18h` | 315 px |
| 312 | Row C | XTINY | `10K 44:12` · `⛰ 412` | 265 px |
| 344 | Row D | XTINY | Running icon `42,3` · bike icon `118` | 185 px |

From the ink top edge of the status row (y = 43; lower isn't possible without
losing width) to the ink bottom edge of row D (y = 370; lower and the chord gets too
narrow) there are **327 px** to distribute, of which the eight elements occupy 243.
The remaining 84 px are **not** distributed evenly:

| Gap | px | Why |
|---|---|---|
| Status → Weather | 12 | |
| Weather → Date | 12 | |
| Date → Time | 7 | both answer the same question and belong together |
| Time → Row A | 14 | this is where the boundary between "outside" and "inside" runs |
| Row A → B → C → D | 13 each | four equally heavy rows need an equal beat |

The largest gap is below the time, the smallest above it. That is intentional: the
time pulls the date toward itself and pushes the data rows away.

The predecessor had three data rows and an accent bar. The bar is gone (see above),
the weather moved up from row A, and row A shrank from SMALL to XTINY — together
60 px, which became the fourth data row.

### Status row: self-allotted width

The status row is the only row that does **not** set its gaps statically. At y = 42
(top edge of the Bluetooth icon) 176 px of chord remain; `STATUS_WIDTH` is set to
172 and leaves four pixels for the imprecision of the ink estimate. The content
varies by over 50 px, however, depending on what the system delivers:

| Case | fixed | Gap | total | Counter |
|---|---|---|---|---|
| `✉0` · `5d` | 112 | 24 | 160 | yes |
| `✉12` · `14d` | 140 | 16 | 172 | yes |
| `✉12` · `100%` | 154 | 9 | 172 | yes |
| `✉100` · `100%` | 121 | 24 | 169 | **no** |

The remaining space is distributed evenly over the two gaps, clamped to 8 to 24 px.
If the gap falls below 8, the **notification counter** is dropped: that something is
unread at all is told by the magenta envelope, and the exact number is on the phone
anyway. It is the cheapest detail that can be sacrificed here — and `100%` only
appears when `batteryInDays` returns null.

```
        ╭───── Steps ────────┬───── Floors ─────╮
       ╱        ⚵    ✉ 3    🔋 14d               ╲
      │        ⛅ 18°  21|9°  ▲ 1013              │
      │      DO · 30.07.      🌇 21:14            │
      │  👣                              🪜       │
      │          1 0 : 2 4    45                  │
      │  ⚡                              ⏱        │
      │    ♥ 72/48    🔥 1842    ▄▆█ 22           │
      │    🚀      VO2 54|42      ⌛ 18h          │
      │       10K 44:12       ⛰ 412               │
       ╲        🏃 42,3      🚴 118              ╱
        ╰── Body Battery ───┴── Active min. ───╯
```

**Why no divider line:** a perfectly straight 300 px line on a round display is a
foreign body. The separation between "outside" and "inside" is done by the time
itself — it is 141 px tall and separates by its mass alone.

**Why the flanks are occupied after all:** next to the 242 px wide time only about
60 px remain on each side — too little for label plus value, but enough for an 18 px
symbol. The four legend icons of the ring sit there. The space thus carries
information without the time losing impact.

**Why equally wide columns:** the data rows don't distribute their elements over
equal gaps but over equally wide columns, in each of which the element is centered.
That puts the elements of different rows on the same axes. A grid you don't see, but
notice immediately when it is missing — an earlier version centered each row on its
own and looked ragged as a result.

**Why the grid has an emergency level:** if an element doesn't fit its column, the
row gives up the grid and distributes equal gaps instead. An element that is too wide
would otherwise run past its column boundary into its neighbor, and two numbers on
top of each other are worse than a shifted axis. Row B is permanently in this level:
`VO2 54|42` is 116 px wide, wider than its 105 px column.

**Why icons instead of abbreviations:** `BB`, `ST`, `KCAL` and `hPa` were four
abbreviations you had to decode first, and they cost 30–60 px each. Bolt, bars and
trend arrow say the same thing narrower and without an intermediate step. The icon
carries the color, the value stays grey.

**Why row B pairs form and recovery:** VO₂max says how fit the body *is*, the
training status where it is *heading*, the recovery time what it can take *now*.
Three answers to the same question: can I train hard today?

**Why the training status is only a rocket now:** it was the only text item on the
watch face, and the only one with an unpredictable width — `Bestform` and
`Überlast` are eight characters of about 14 px each and burst their column. A symbol
is always 18 px wide. That the meaning of the word is lost is made up for by the
eight-level color scale (section 1): it distinguishes more states than the shortened
text did (`Unprod.`, `Überlast`, `Verlust` were already abbreviations).

**Why Body Battery has no numeric value anymore:** the arc at the bottom left already
shows the same number as a scale from 0 to 100 — Body Battery *is* a percentage and
needs no goal. The same thing twice is not a second piece of information. The bolt
symbol stays and is now the legend of that arc.

**Why only *one* race prediction, but configurable:** four distances (5 km, 10 km,
HM, marathon) need 403 px, row C has 265. A predecessor showed two hard-wired ones —
and had to pick two out of four, a choice the watch face cannot make at all, because
it depends on the next season. Now you choose the distance on the watch, the label
changes with it (`5K` / `10K` / `HM` / `MAR`), and the second column became free for
something that has nothing to do with running.

**Why the altitude sits in the sports half:** it is the only item below the time that
doesn't come from the body, and thus breaks the structure from section 2. The
justification is that it has the same source as the air pressure above the time —
just in a unit you understand without converting. Whoever sees both has weather and
terrain in one glance.

**Why icons in row D:** at 185 px of available width the text label "LAUF" alone
costs 72 px. For the same reason the unit is missing — **both values are
kilometers**. From 100 km the decimal place is dropped.

**Why calories carry the flame instead of " kcal":** the other way round from a
predecessor. A *grey* flame at 18 px inevitably gets read as a water drop — point at
the top, rounding at the bottom is the same silhouette. In orange the confusion
disappears, and the spelled-out unit loses its justification: it costs 60 px in a
row that has to fit three elements into 310 px.

**Why only ever *one* sun event:** the sunset in the afternoon, the next day's
sunrise after sunset. A time that has already passed is no information — and both at
once would have cost 200 px. Which one applies is decided at draw time, to the
second, not on the 15-minute beat of the weather refresh, otherwise the display would
lag a quarter of an hour behind after sunset.

---

## 3. Language

The watch face is German, **regardless of what the watch is set to**. Otherwise both
would go wrong as soon as the watch speaks English:

- **Weekday** from `Locale.weekday()` instead of `Gregorian.info(..., FORMAT_MEDIUM)`.
  That means we don't need FORMAT_MEDIUM at all anymore — and the pitfall from
  section 6 that it returns month and weekday as *text* instead of as a number is
  gone too. `FORMAT_SHORT` returns `day_of_week` as a number, 1 = Sunday.
- **Time** always 24-hour, even if `DeviceSettings.is24Hour` is false. A watch face
  with a fixed language also has a fixed time format — and without an AM/PM marker
  12-hour would be ambiguous here anyway.
- **Training status** via `Locale.trainingColor()`. The complication delivers
  ready-made localized text; the mapping recognizes English *and* German system texts
  via substrings.
- **Decimal comma** instead of a point, `Locale.comma()`. Monkey C has no
  `String.replace`, hence the detour through the characters.

### Training status

Since the status only appears as a colored rocket, **nothing gets translated
anymore** — but both languages are still recognized. The order of the table in
`Locale.mc` is essential: `"unproductive"` contains `"productive"`, so the negative
case has to be checked first. The search patterns avoid umlauts because `toLower()`
in Monkey C only touches ASCII — a pattern `"ueberlast"` would never match
`"Ueberlastung"`, `"berlast"` matches both spellings, and `"chstform"` matches
`"Höchstform"` the same way.

| System text (en / de) | Search pattern | Rocket color |
|---|---|---|
| Peaking / Bestform, Höchstform | `peaking`, `chstform`, `bestform` | violet |
| Productive / Formaufbau | `productive`, `produktiv`, `aufbau` | green |
| Maintaining / Formerhalt | `maintain`, `erhalt` | blue |
| Recovery / Erholung | `recovery`, `erholung` | yellow |
| Unproductive / Unproduktiv | `unproduc`, `unproduk` | orange |
| Strained / Belastet | `strain`, `strapaz`, `belastet` | strong orange |
| Overreaching / Überlastung | `overreach`, `berlast` | dark red |
| Detraining / Formverlust | `detrain`, `formverl` | red |
| Paused, No Result, unknown | — | grey |

The hex values are in section 1. Unknown system texts fall back to grey — that is
bearable here because nothing can be shown in the wrong language anymore.

---

## 4. Data sources

All accesses are compiled and verified against `fenix843mm` (`BUILD SUCCESSFUL`).
The compile proves API availability — whether the watch delivers a value instead of
`null` at runtime is checked in the first device test. **Every field needs null
handling.**

| Element | Source |
|---|---|
| Time, seconds | `System.getClockTime()` |
| Date | `Time.Gregorian.info()` `FORMAT_SHORT` + `Locale.weekday()` |
| Steps + goal | `ActivityMonitor.getInfo().steps` / `.stepGoal` |
| Floors + goal | `.floorsClimbed` / `.floorsClimbedGoal` |
| Active minutes + goal | `.activeMinutesWeek.total` / `.activeMinutesWeekGoal` |
| Calories | `.calories` |
| HR current | `Activity.getActivityInfo().currentHeartRate`, 5-sample ring buffer |
| Resting heart rate | `UserProfile.getProfile().averageRestingHeartRate`, fallback `.restingHeartRate` |
| **VO₂max running** | `UserProfile.getProfile().vo2maxRunning` |
| **VO₂max cycling** | `UserProfile.getProfile().vo2maxCycling` |
| **Body Battery** | `COMPLICATION_TYPE_BODY_BATTERY` |
| **Stress** | `COMPLICATION_TYPE_STRESS` |
| **Training status** | `COMPLICATION_TYPE_TRAINING_STATUS` |
| **Recovery time** | `COMPLICATION_TYPE_RECOVERY_TIME` (minutes) |
| **Race prediction** | `COMPLICATION_TYPE_RACE_PREDICTOR_{5K,10K,HALF_MARATHON,MARATHON}` (seconds), depending on the setting |
| Altitude | `Activity.getActivityInfo().altitude`, fallback `SensorHistory.getElevationHistory()` |
| **Weekly km running** | `COMPLICATION_TYPE_WEEKLY_RUN_DISTANCE` |
| **Weekly km cycling** | `COMPLICATION_TYPE_WEEKLY_BIKE_DISTANCE` |
| Sunrise, sunset | `COMPLICATION_TYPE_SUNRISE` / `_SUNSET` (seconds since midnight), fallback `Weather.getSunrise/getSunset` |
| Weather now | `Weather.getCurrentConditions()` |
| Forecast 2 days | `Weather.getDailyForecast()` |
| Barometer + trend | `SensorHistory.getPressureHistory()`, trend from the last ~3 h |
| Watch battery | `System.getSystemStats().battery` / `.batteryInDays` |
| Bluetooth, notifications | `System.getDeviceSettings().phoneConnected` / `.notificationCount` |

**Important:** Body Battery and stress come via **complications, not SensorHistory** —
the device definition lists only altitude, HR, pressure, PulseOx and temperature as
sensor history.

### Two fields that stayed empty on the watch

Both bugs were invisible in the simulator and only noticed on the wrist.

**Resting heart rate.** According to the SDK, `restingHeartRate` is "as configured
by the user" — only the value entered by hand. Anyone who never entered one gets
`null`, and the field stayed empty even though Garmin does know a resting heart rate.
The calculated value is called `averageRestingHeartRate` (seven-day average) and is
the one you also see in Connect. It is now first choice; the entered one stays as a
fallback — whoever set it did so for a reason.

**Sun cycle.** The first version fetched both times via
`Weather.getSunrise(position, …)` and needed the `observationLocationPosition` of the
current conditions for that. On the watch that was `null` — the field stayed
permanently on `--:--` while temperature and forecast appeared correctly next to it.
The `SUNRISE` / `SUNSET` complications deliver the same times as seconds since
midnight, **without a location and without the position permission**. The weather API
stays as a fallback.

After sunset the watch face shows the sunrise of **today**, not tomorrow's. Depending
on the season the two are one to four minutes apart — close enough for a display that
rounds to the minute, and it saves a second data path.

### What the complications actually deliver (measured in the simulator)

The field types are undocumented, so they were read out instead of guessed:

| Type | `value` | `unit` | Note |
|---|---|---|---|
| `BODY_BATTERY` | `19` (Number) | `%` | |
| `STRESS` | `81` (Number) | — | `shortLabel` is `null` |
| `TRAINING_STATUS` | **`"No Result"` (String!)** | — | The status is in `value`, **not** in the label. The labels only contain the name of the metric. |
| `WEEKLY_RUN_DISTANCE` | `0.0` (**Float**) | `1` | `unit 1` = `UNIT_DISTANCE` → **value in meters** |
| `WEEKLY_BIKE_DISTANCE` | `0.0` (Float) | `1` | ditto |

`UserProfile.getProfile()` directly returns `vo2maxRunning = 40` and `restingHeartRate = 60`.

**Manifest permissions:** `SensorHistory`, `UserProfile`, `ComplicationSubscriber`
(the permission is called `ComplicationSubscriber`, *not* `Complications`.)

### Not possible: the race calendar

**Connect IQ has no access to the Garmin race calendar.** There is no API for the
next planned race — neither date nor distance nor sport, and hence no prediction "for
the next race" either. The complete list of complication types in SDK 9.1.0 (44 of
them) contains nothing of the kind; `COMPLICATION_TYPE_CALENDAR_EVENTS` is the next
appointment from the **phone calendar** as a time string, not the watch's race
calendar.

What exists is the **Race Predictor**: four predictions for 5 km, 10 km, HM and
marathon, each in seconds. The watch face shows one of them, selectable on the watch
(section 4a). A symbol per race type — triathlon, bike, running distances — would
have nothing to distinguish without knowing which race is coming up; the prediction
therefore carries a text label instead of an icon.

### Deliberately not on the watch face

- **Weekly swimming and strength training:** there is no complication type for them.
  Both are covered via the **active-minutes section**, which counts every intense
  activity — automatically and without gaps, just without a distance of its own.
- Available but left out for space: respiration rate, Pulse Ox, solar entry, weekly
  active minutes as a number.

---

## 4a. Configuration — two separate routes

**App settings cannot be edited on the watch.** That is not a gap in this watch face
but the design of the framework; Garmin's docs say it literally:

> The app settings framework enables app developers to present options to end users
> for their apps **within Garmin Connect and Garmin Express**. This will allow app
> customization and setup, especially for watch faces and data fields, **that have no
> way to receive user input on Garmin devices.**

An earlier version of this spec claimed the opposite ("switchable on the watch"). It
was simply wrong, and the first device test uncovered it: the settings were nowhere
to be found on the wrist.

To make matters worse, Garmin Connect and Garmin Express fetch their settings
description from the Connect IQ store. For a **sideloaded** watch face nothing is
stored there, and the settings may not appear there either.

There are therefore two routes, and the color scheme takes the one that gets by
without the store and without a phone.

### The watch's face editor

From API 5.1.0 the fēnix 8 has a **built-in watch face editor**. It knows four
axes: styles, complications, data color and accent color. Only **styles** is used —
the whole configuration of the watch face is there.

The editor only knows **one** selection list, however. Both decisions have to share
that one, which means: their product. **3 schemes × 4 distances = 12 entries**,
encoded as

```
styleId = scheme * 4 + distance
```

| | 5 km | 10 km | HM | Marathon |
|---|---|---|---|---|
| **Full** | 0 | 1 *(default)* | 2 | 3 |
| **Muted** | 4 | 5 | 6 | 7 |
| **Calm** | 8 | 9 | 10 | 11 |

The same calculation is in `resources/configs/watchface.xml` and in
`BeniView.applyConfiguration`; the two may only be changed together.

This is not a nice pattern: two independent decisions are multiplied into one long
list, and with a third axis it explodes. But it is the only one that lets you set
**everything** on the wrist — and that was the requirement. Twelve entries are still
scrollable; a third axis wouldn't be, and would have to be housed differently.

The `styleId` is read in `BeniView.applyConfiguration`;
`BeniWatchFaceDelegate.onWatchFaceConfigEdited` makes sure the preview in the editor
follows immediately instead of only on leaving.

This costs `minApiLevel = 5.1.0` in the manifest. For a watch face that only builds
for `fenix843mm` anyway, that is inconsequential.

### What belongs to it

Two files: `resources/configs/watchface.xml` (the twelve styles) and the labels in
`resources/strings.xml`. The selection is read in `BeniView.applyConfiguration`, the
result goes on as the scheme to `Theme.applyScheme` and as the distance via
`WatchData.setRaceDistance`.

**There are no app settings anymore.** `settings.xml`, `properties.xml` and the
fallback via `Application.Properties` were removed once the editor was confirmed on
the device — they could never have taken effect and would have been a second, silent
source for the same two values. If the editor delivers nothing, it stays at Full and
10 km; that is no fallback route, merely a defined state.

**Pitfall — the `<resources>` root element:** `configs/watchface.xml` has to sit in
`<resources>…</resources>` like every resource file. If it is missing, **the compiler
silently skips the file**: the build reports `BUILD SUCCESSFUL`, but there are no
styles, and the watch face quietly falls back to its built-in default. That is
exactly what happened to the first version of `properties.xml`.

The quickest way to check whether a resource file is read at all is a deliberate
error in it — reference a string that doesn't exist. If the compiler complains, the
file is being processed; if it stays silent, it isn't.

**Language folders:** the strings are additionally in `resources-deu/` and
`resources-eng/`. Without them they only land in the default bucket, which the SDK
internally calls `valyrian`, while the manifest announces `deu` and `eng`. They now
carry the style labels that appear on the watch — that is why they stay, although the
original reason (the labels of the app settings) has gone away.

The watch face subscribes to **all four** prediction complications, although it only
shows one. Otherwise the subscription would depend on a setting that can change at any
time and would have to be rebuilt on every change — four values that move at most
daily cost less than this state machine.

**The four ring sections need special treatment on a scheme change.** `ArcGauge`
copies its metric color on construction; rewriting `Theme` bypasses that.
`BeniView.applyConfiguration` therefore sets them explicitly once more via
`ArcGauge.setColor`. All other elements read `Theme` on every draw and need nothing.

---

## 5. Always-on display

In AOD the watch only updates ~1× per minute and heavily dimmed.

**Visible:** time (**NUMBER_MILD**, value grey, **without seconds**) · HR (small) · battery % (small, grey)
**Off:** ring, legend icons, date, weather, all data rows, status row.

- In AOD deliberately **one font size smaller** than in active mode. NUMBER_MEDIUM
  would be too bold here: the always-on display should light up few pixels. The time
  moves down 16 px so that it visually sits in the same place.
- Dimmed grey instead of white — on AMOLED that directly means less power.
- **Exactly one color:** the heart rate in a strongly darkened red
  (`Theme.mix(HEART, BG, 0.45)`). It is the same color code as in active mode but
  costs hardly any power on AMOLED — red subpixels alone, a third of the power of
  white.
- Burn-in protection: shift the whole content by ±2 px every minute.
- HR is frozen in AOD (per-minute beat) — the 5-sample average only runs in active
  mode.

---

## 6. Runtime behavior

- `onUpdate()` 1×/s in active mode → seconds and HR ring buffer.
- **Subscribe** to complications (`subscribeToUpdates()`) and cache them in member
  variables — never poll per frame, that is too expensive.
- Refresh weather and sunset every 15 min, cache in between.
- Wrap `onUpdate()` and all sensor accesses completely in `try/catch`, so that no
  single null value freezes the watch face.
- **No `Toybox.Attention`** — not available in this context.

## 7. Build and simulator

The project path contains `!` (`!GitHub\!Garmin`). The SDK's `.bat` wrappers mangle
`!` through delayed expansion — copy the `.prg` to a `!`-free path before `monkeydo`.

```
monkeyc.bat -f monkey.jungle -o bin/Beni_Watchface.prg -y developer_key_pkcs8.der -d fenix843mm -w
```

`monkeydo` stays attached as long as the app runs — start it in the background,
otherwise it blocks. Memory budget of the watch face: **~124 kB**.

**Simulator screenshots without GUI interaction:** the simulator window renders the
watch at a fixed size and does *not* scale with the window; the Java Swing menus don't
respond to synthetic mouse clicks. The reliable way is **`PrintWindow`** (user32) on
`MainWindowHandle` with flag 2 (`PW_RENDERFULLCONTENT`): it delivers the complete
window content in one image, independent of screen size and overlap, and the watch
face area arrives in it at its native 416 × 416 px.

`CopyFromScreen` works too, but only as long as the session is unlocked — otherwise
it fails with "The handle is invalid". An older version of this spec recommended
moving the window to negative y positions and grabbing twice; with `PrintWindow` that
is no longer necessary.

**Resetting settings in the simulator:** the simulator remembers the app settings in

```
%TEMP%\com.garmin.connectiq\GARMIN\APPS\SETTINGS\BENI_WATCHFACE.SET
```

and does so **across restarts**. A changed default in `properties.xml` therefore
doesn't become visible as long as this file exists — the stored value wins. To test a
new default, delete the file and start `monkeydo` again. Otherwise this costs half an
hour of debugging in the wrong place.

The same applies to the **watch face configuration** at a different location:

```
%TEMP%\com.garmin.connectiq\GARMIN\APPS\DATA\MEDIA\OBJSTORE\BENI_WATCHFACE\config\
```

This folder also survives restarts. Anyone who sets a different `default="true"` in
the `watchface-config` and sees nothing hasn't got the encoding wrong — they are
looking at the old stored selection. Delete the folder, reload.

This is exactly how the `styleId` encoding was verified: default set to 0, 6 and 11 in
turn and checked whether color scheme and distance label matched (Full · 5 km,
Muted · HM, Calm · Marathon). Without the deletion every attempt showed style 0.

### Renewing the screenshots for the README

The images in `docs/` show **sample data**. The simulator delivers no sensor data, and
a watch face full of `--` says nothing about the layout. The way there, should the
images be needed again:

1. **Temporarily** set the return values in `WatchData` (pulse, calories, arc
   progress, weather …) as well as time, status row and sun time in `BeniView` to
   fixed values. A fixed time is important, otherwise the three images show different
   seconds and can no longer be compared. The patch stays in the working directory
   and is discarded afterwards with `git checkout -- source/`.
2. Per scheme, set the default `colorScheme`, build, delete `BENI_WATCHFACE.SET`,
   `monkeydo`, grab the window via `PrintWindow`.
3. From the window, cut the section **x = 105…520, y = 248…663** — those are the
   416 × 416 of the display.

Point 3 is the pitfall: the display area **cannot** be found visually. The bezel of
the device photo is also pure black, so every threshold search yields a box that is
too large. The section was measured with a calibration frame — once
`dc.drawRectangle(0, 0, dc.getWidth(), dc.getHeight())` in magenta at the end of
`onUpdate`, grab, find magenta pixels, remove the frame again. The coordinates hold as
long as the window sits at (0, 0) at 1250 × 1350.

**Pitfall (historical):** `Gregorian.info(..., Time.FORMAT_MEDIUM)` returns `month`
and `day_of_week` as **text**, not as a number. `.format("%02d")` on it crashes at
runtime, and the `try/catch` in `onUpdate` does *not* catch it. Since section 3 the
watch face no longer uses FORMAT_MEDIUM — the pitfall stays here so nobody goes back
there by accident.

---

## 8. Implementation status

| Part | Status |
|---|---|
| Project scaffold, manifest, permissions, launcher icon | done |
| Edge ring, four color sections (11 px), round caps, quarter marks | done, checked in the simulator |
| Legend icons footprint / stairs / bolt / stopwatch | done, checked in the simulator |
| Goal reached → white hairline at radius 204 | done, checked in the simulator (not clipped) |
| Weather row above the time (now, forecast, air pressure) | done, checked in the simulator |
| Date + next sun event | done, checked in the simulator (simulator delivers no position → `--:--`) |
| Time 24 h with seconds in SMALL | done, checked in the simulator |
| Status row (Bluetooth, notifications, battery with scale) | done, checked in the simulator |
| Status row within radius 188, self-allotted width | done, checked in the simulator |
| Rows A–D in column grid with emergency level, split values | done, checked in the simulator |
| Training status as rocket with eight-level color scale | done, checked in the simulator (simulator only delivers `No Result` → grey) |
| Race prediction selectable via setting, altitude next to it | done, checked in the simulator for 10 km and marathon |
| Color scheme **and** race distance via twelve styles of the watch face editor | done, encoding checked in the simulator at styles 0, 6 and 11, operation confirmed on the device |
| All data sources from section 4 | wired up, with null handling |
| AOD (time, HR in dark red, battery, burn-in offset) | implemented, **not yet tested** |

### Open points for the device test

The simulator lacks real sensor data, so the following remains to be checked:

- Do `TRAINING_STATUS`, `RECOVERY_TIME`, the two `RACE_PREDICTOR` types and the weekly
  distances deliver real values on the watch? In the simulator they are "No Result",
  300 min and 0 respectively.
- Does `Locale.trainingColor()` hit the wording the watch really delivers? The table
  covers English and German Garmin terms, but only "No Result" has been verified. A
  text that isn't matched falls back to a **grey** rocket — the same state as "no
  result", and thus no longer distinguishable from outside. At the first device test,
  compare against `dumpComplications()`.
- Does the color mapping of the eight training states match what the watch itself
  displays? The scale is derived from Garmin documentation, not read off the device.
- Does `vo2maxCycling` deliver a value, or does the cycling part of `54|42` stay at `--`?
- Does the watch face show up in the watch's **face editor**, and can the three styles
  be selected there? The simulator delivers `styleId` but has no editor to operate.
  That also leaves open whether `onWatchFaceConfigEdited` fires and the four arcs get
  their new color in the process.
- Are twelve entries in the watch's style menu still usable, or does the menu shorten
  the labels ("Gedämpft · Marathon" is the longest)?
- Does `averageRestingHeartRate` deliver a value on the watch? The hand-entered
  `restingHeartRate` was `null` there.
- Do the `SUNRISE` / `SUNSET` complications deliver real times?
- Can the four ring sections in the "Calm" scheme be told apart at their seams on the
  real display? There they differ only in brightness, no longer in hue. In the
  simulator yes — but it shows the arcs almost empty for lack of data.
- Does `ActivityInfo.altitude` deliver a value outside a recording, or does the
  fallback to the altitude history kick in every time? The simulator shows −17 m.
- Does the weather row, with double-digit minus temperatures in both high **and** low,
  still stay within the ring? 254 px of content are calculated against 264 px of chord
  — the extreme case `-15|-22°` runs 2 px into the arc on paper.
- Does the emergency level of the status row (notification counter dropped) kick in?
  It needs a two- to three-digit counter **and** a battery display in percent instead
  of remaining days. In the simulator only the narrowest case (`✉0` · `5d`) was seen.
- Does the fenix 8 reliably deliver `batteryInDays`? If so, the status row is never
  wider than 172 px and the emergency level remains dead code — then it can go.
- Does row A stay in the column grid when the pulse is three digits? `♥ 199/45`
  measures about 103 px at a column width of 103 px — the grid's emergency level
  should switch exactly there and has not been seen yet.
- Are the four legend icons far enough from the ring at radius 172 on the real
  display? 9 px of distance to the inner edge of the arc are calculated.
- Does the AOD pixel share stay under the 10 % Garmin requires? If the watch face is
  only sideloaded, that is uncritical — for the store it is not.
- Can amber (floors) and orange (steps) be told apart reliably at the 12 o'clock
  transition on the real display? In the simulator yes, but they are the closest color
  pair of the ring.
