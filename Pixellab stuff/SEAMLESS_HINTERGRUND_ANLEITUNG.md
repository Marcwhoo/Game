# Seamless 128x128 Hintergrund – was wirklich funktioniert

Prozedurales Noise und Cut-Swap liefern bei dir kein brauchbares Ergebnis. Zwei Wege, die zuverlaessig gehen:

---

## 1. GIMP: Make Seamless (mit deinem eigenen Motiv)

Du hast schon einen Innenbereich, der dir gefaellt (z.B. aus `ui_frame_medieval_20260130_092711.png`).

1. **Innenbereich ausschneiden** (z.B. mit `extract_background_from_frame.ps1` → 80x80).
2. In GIMP: **Bild auf 128x128 skalieren** (Bild > Bild skalieren), damit die Kachel 128x128 ist.
3. **Filter > Map > Make Seamless** ausfuehren. GIMP macht die Kanten nahtlos (Offset + Naht entfernen).
4. Exportieren als PNG. Diese Datei an allen 4 Seiten an sich selbst anlegen – das Muster geht seamless weiter.

Damit nutzt du genau deinen Stil und bekommst eine echte nahtlose Kachel.

---

## 2. Fertige tilebare Stein-Textur

Wenn du keinen eigenen Stil brauchst:

- **OpenGameArt:** z.B. "Stone ground tileable texture" oder "Stone Texture 128 x 128" (nach "tileable stone" suchen).
- **CC0-Textures:** stone tiles, seamless.
- Einfach 128x128 (oder passend) herunterladen und im Projekt als TileSet-Texture nutzen.

---

Fuer dein Medieval-UI ist Option 1 (GIMP Make Seamless auf dem extrahierten Frame-Innenbereich) der sinnvollste Weg.
