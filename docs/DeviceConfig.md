# Device configuration

The optional file backend uses the host's existing read/write capability. No file access is available to an ordinary Roblox LocalScript. The fallback remains the session bank, JSON export/import and the explicitly installed own-place server store.

Two fixed local JSON slots are rotated after each validated write. Startup restores the highest valid sequence. The previous valid slot remains available if a write is interrupted. Configs contain the existing version-1 bank (settings, named profiles and assets), never executable code. Match experiments remain session-only. No device bank is sent to a game server. Rapid edits are coalesced and unload requests a final save; abrupt termination may lose the last fraction of a second of edits.

Profiles → Save now / Reload bank provides manual control. Verify by changing a setting, saving, closing Roblox, relaunching and confirming restoration. A host without persistent file support cannot provide automatic device persistence.
