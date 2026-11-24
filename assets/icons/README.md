# Original AETHER desktop icons

The desktop distribution `AETHER_Build/Web/assets/icons/` contains **32 original RGBA icons (224×224 each)**.

Use `tools/export_desktop_icons.py` with your own `AETHER_Build(1).zip` to extract
all source PNGs and generate an **8×4 atlas (1792×896)** without resampling.

```sh
python -m pip install Pillow
python tools/export_desktop_icons.py "AETHER_Build(1).zip" assets/icons
```

**Using the icons in Roblox:** Publish `AETHER_original_icons_atlas.png` as an
image asset in Roblox Studio / Creator Dashboard and enter its **numeric asset ID**
into **Dashboard → AETHER icon atlas Roblox asset ID**. The UI then uses
`ImageRectOffset` and `ImageRectSize=224×224` for the navigation icons.

GitHub raw PNG URLs cannot be directly set as Roblox `ImageLabel.Image`.
The original binary PNGs are intentionally *not* embedded in Luau source, and
no Roblox asset ID is bundled or invented.

Atlas order, in row-major sequence (8 columns):
```
Home Dashboard HUD Fonts Themes World_FX Indicators Simulator
Workshop Downloads Plugins Extensions AI_Assistant Music Media Games
Console Logs Settings Profile Health Performance Update About
Tests Debug Bridge Launch Files Assets Cloud Favorites
```
