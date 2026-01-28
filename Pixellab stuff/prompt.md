# PixelLab Asset Generation Guide - Spielspezifikationen

## WICHTIG: Diese Datei ist eine Anleitung fuer LLMs

Wenn du als LLM Assets fuer dieses Spiel erstellen sollst, verwende diese Datei als Referenz, um die richtigen PixelLab-Prompts zu generieren.

---

## Spielspezifikationen

gesamte docs von der api: https://api.pixellab.ai/mcp/docs

### Perspektive und Ansicht
- **Perspektive:** Top-Down / Isometric (wie Overlooting)
- **Referenz-Spiel:** Overlooting (3rd-person perspective, Top-Down/Isometric Ansicht)
- **NICHT verwenden:** Sidescroller-Tilesets (Side-View Platformer)

### Asset-Groessen
- **Alle Assets:** 32x32 Pixel
- **Tilesets:** 32x32 Pixel pro Tile
- **Konsistenz:** Alle Assets muessen die gleiche Groesse haben

### Art-Style
- **Referenz:** Aehnlich wie Overlooting
- **Stil:** Pixel Art
- **Genre:** Roguelike, Fantasy, Medieval
- **Farbpalette:** Sollte zu Overlooting passen (Pixel Graphics, mittelalterlicher Stil)

---

## Welche PixelLab Tools verwenden?

### Fuer Tilesets (Karten/Terrain):
- **`create_topdown_tileset`** - Fuer Top-Down Karten mit Wang-Tiles (Autotiling)
- **`create_isometric_tile`** - Fuer einzelne Isometric Tiles (wenn Isometric-Perspektive)

### Fuer andere Assets:
- **`create_map_object`** - Fuer Objekte mit transparentem Hintergrund
- **`create_character`** - Fuer Charaktere (wenn benoetigt)

### Gegner (z.B. Baer, gleicher Art-Style wie Held):
- **Humanoid:** POST `/create-character-with-8-directions` – 8 Richtungen, Job async, dann GET `/characters/{id}`. Achtung: Liefert humanoiden Stil (steht wie Mensch).
- **Vierbeiner (Baer, Wolf etc.):** Character-API/animate-character braucht character_id von create-character (Humanoid-Template) -> ungeeignet. Stattdessen: POST `/generate-image-v2` nur mit Text, 4x mit Richtung im Prompt (south/north/east/west). Kein Stil-Bild = wenig Tokens, 4 echte Richtungen ohne Doppelte. Skript: `create_enemy_bear_quadruped.ps1`.

### NICHT verwenden:
- **`create_sidescroller_tileset`** - Nur fuer Side-View Platformer, NICHT fuer dieses Spiel

---

## Top-Down Tileset Prompting (create_topdown_tileset)

### Was ist ein Top-Down Tileset?
- Fuer Top-Down Kartenansicht (von oben)
- Wang-Tiles System (16 oder 23 Tiles je nach transition_size)
- Autotiling basierend auf 4 Ecken pro Tile
- Nahtlose Terrain-Uebergaenge

### Erforderliche Parameter:

**MUSS angegeben werden:**
- `lower_description`: Unteres Terrain (z.B. "dirt", "stone floor", "wooden planks")
- `upper_description`: Oberes/erhoehtes Terrain (z.B. "grass", "cobblestone", "sand")

**WICHTIG fuer dieses Spiel:**
- `tile_size`: **IMMER** `{width: 32, height: 32}` (Spielspezifikation)
- `view`: "high top-down" oder "low top-down" (Standard: "high top-down")

### Optionale aber wichtige Parameter:

- `transition_size`: 0.0, 0.25, 0.5, oder 1.0
  - 0.0 = keine Transition
  - 0.25-0.5 = leichte/mittlere Transition
  - 1.0 = volle Tile-Transition (gibt 23 statt 16 Tiles)
- `transition_description`: Nur benoetigt wenn transition_size > 0
  - Beschreibt die Mischung zwischen lower und upper (z.B. "wet sand with foam", "dirt with grass patches")
- `outline`: "single color outline", "selective outline", "lineless"
- `shading`: "flat shading", "basic shading", "medium shading", "detailed shading", "highly detailed shading"
- `detail`: "low detail", "medium detail", "highly detailed"
- `tile_strength`: 0.1-2.0 (Pattern-Konsistenz, Standard: 1)
- `text_guidance_scale`: 1-20 (Prompt-Adherence, Standard: 8)

**Fuer verbundene Tilesets:**
- `lower_base_tile_id`: ID eines existierenden Tiles als Referenz fuer unteres Terrain
- `upper_base_tile_id`: ID eines existierenden Tiles als Referenz fuer oberes Terrain

---

## Beispiel-Prompts fuer dieses Spiel

### Erstes Tileset (Basis-Terrain, aehnlich Overlooting):

```
Tool: create_topdown_tileset
lower_description: "medieval stone floor tiles"
upper_description: "medieval cobblestone path with individual stones"
tile_size: {width: 32, height: 32}
view: "high top-down"
transition_size: 0.0
shading: "detailed shading"
detail: "highly detailed"
outline: "selective outline"
text_guidance_scale: 12
```

**WICHTIG:** 
- Verwende spezifische Material-Beschreibungen mit "medieval" Kontext
- transition_size: 0.0 fuer klare Trennung ohne Dirt-Patches
- "detailed shading" und "highly detailed" MUSS verwendet werden
- text_guidance_scale: 12-15 fuer staerkere Prompt-Adherence

### Gras-Terrain:

```
Tool: create_topdown_tileset
lower_description: "dirt"
upper_description: "grass"
tile_size: {width: 32, height: 32}
view: "high top-down"
transition_size: 0.5
transition_description: "dirt with grass patches"
shading: "medium shading"
detail: "medium detail"
outline: "selective outline"
```

### Stein-Boden:

```
Tool: create_topdown_tileset
lower_description: "stone floor"
upper_description: "cobblestone"
tile_size: {width: 32, height: 32}
view: "high top-down"
transition_size: 0.0
shading: "detailed shading"
detail: "highly detailed"
outline: "selective outline"
```

### Sand/Duene:

```
Tool: create_topdown_tileset
lower_description: "dirt"
upper_description: "sand"
tile_size: {width: 32, height: 32}
view: "high top-down"
transition_size: 0.25
transition_description: "dirt with sand patches"
shading: "basic shading"
detail: "medium detail"
outline: "selective outline"
```

---

## Best Practices fuer LLMs

### 1. IMMER diese Parameter setzen:
- `tile_size: {width: 32, height: 32}` - MUSS bei jedem Tileset sein
- `view: "high top-down"` - Standard fuer Top-Down Ansicht

### 2. Material-Beschreibungen:
- Sei spezifisch: "stone brick" statt nur "stone"
- Verwende passende Materialien fuer Fantasy/Medieval Setting
- Beispiele: "cobblestone", "stone floor", "wooden planks", "dirt path", "grass", "sand"

### 3. Art-Style Konsistenz:
- `shading: "detailed shading"` oder `"highly detailed shading"` - WICHTIG fuer Overlooting-Style
- `detail: "highly detailed"` - MUSS verwendet werden fuer Overlooting-aehnlichen Stil
- `outline: "selective outline"` - typisch fuer Pixel Art
- **WICHTIG:** "medium shading" und "medium detail" sind zu einfach - verwende immer "detailed" oder "highly detailed"

### 4. Transition-Size:
- 0.0 = harte Grenze zwischen Terrains
- 0.25-0.5 = weiche Uebergaenge (empfohlen)
- 1.0 = volle Transition (mehr Tiles, komplexer)

### 5. Verbundene Tilesets:
- Erstelle erstes Tileset und warte auf Completion
- Hole base_tile_id mit `get_topdown_tileset`
- Verwende `lower_base_tile_id` oder `upper_base_tile_id` beim naechsten Tileset
- Beispiel-Workflow:
  1. Tileset 1: dirt → grass → hole grass base_tile_id
  2. Tileset 2: grass (mit base_tile_id) → stone → hole stone base_tile_id
  3. Tileset 3: stone (mit base_tile_id) → sand

---

## Workflow fuer LLMs

### Wenn der Benutzer ein Tileset anfragt:

1. **Pruefe Spielspezifikationen:**
   - Perspektive: Top-Down/Isometric? → `create_topdown_tileset`
   - Groesse: 32x32? → `tile_size: {width: 32, height: 32}`
   - Art-Style: Aehnlich Overlooting? → medium/detailed shading, selective outline

2. **Erstelle Prompt:**
   - Verwende `create_topdown_tileset` Tool
   - Setze `lower_description` und `upper_description` basierend auf Benutzer-Anfrage
   - Setze IMMER `tile_size: {width: 32, height: 32}`
   - Setze `view: "high top-down"`
   - Waehle passende `shading`, `detail`, `outline` Werte
   - Setze `transition_size` und optional `transition_description`

3. **Warte auf Completion:**
   - Tool gibt sofort eine tileset_id zurueck
   - Verwende `get_topdown_tileset` um Status zu pruefen
   - Generierungszeit: ~100 Sekunden

4. **Fuer weitere Tilesets:**
   - Hole base_tile_id vom vorherigen Tileset
   - Verwende base_tile_id fuer nahtlose Verbindung

---

## Wichtige Hinweise

- **NIE** `create_sidescroller_tileset` verwenden - das ist nur fuer Side-View Platformer
- **IMMER** `tile_size: {width: 32, height: 32}` setzen
- **IMMER** `view: "high top-down"` fuer Top-Down Ansicht
- Art-Style sollte zu Overlooting passen (Pixel Art, Medieval/Fantasy)
- Alle Assets muessen konsistent sein (gleiche Groesse, aehnlicher Stil)

---

## Naechste Schritte

Als erstes wird ein Basis-Tileset benoetigt, das aehnlich wie Overlooting aussieht:
- Top-Down Perspektive
- 32x32 Pixel
- Stone/Cobblestone oder aehnliches Medieval Terrain
- Medium-Detailed Pixel Art Style
