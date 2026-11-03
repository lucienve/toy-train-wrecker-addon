---
trigger: model_decision
description:
  Apply this when maintaining or modifying the Train Wrecker World of Warcraft
  addon.
---

# Train Wrecker Maintenance & Development Directives

You must strictly adhere to these architectural patterns, coding standards,
testing procedures, and release guidelines when maintaining or contributing to
the **Train Wrecker** (`TrainWrecker`) World of Warcraft addon codebase.

Train Wrecker is a standalone World of Warcraft addon supporting both Retail
(`120100`) and Mists of Pandaria Classic (`50504`) that detects nearby Toy Train
Sets and prompts the player to silence them with the Wind-Up Train Wrecker.

---

## 1. Codebase Architecture & Structure

Understand the modular structure, event lifecycles, and combat lockdown
safeguards before modifying the codebase:

- **`TrainWrecker.toc`:** Multi-flavor TOC manifest specifying interface
  versions for Retail (`120100`) and Mists of Pandaria Classic (`50504`),
  metadata, SavedVariables (`TrainWreckerDB`), and CurseForge packaging tags.
- **`main.xml`:** Root FrameXML manifest loading scripts in topological order:
  1. `locales/locales.xml`
  2. `core/init.lua`
  3. `core/detector.lua`
  4. `ui/dialog.lua`
- **`locales/`:** Zero-dependency localization tables:
  - `locales/locales.xml`: XML loader for locale files.
  - `locales/enUS.lua`: Default English localization dictionary with fallback
    metatable.
- **`core/init.lua`:** Addon lifecycle, SavedVariables initialization on
  `ADDON_LOADED`, and slash command registrations (`/trainwrecker`, `/tw`).
- **`core/detector.lua`:** Event frame monitoring `UNIT_SPELLCAST_SUCCEEDED`,
  `UNIT_AURA`, `PLAYER_ENTERING_WORLD`, `TOYS_UPDATED`, and
  `BAG_UPDATE_DELAYED`. Handles spell deduplication, secret value guards,
  toy/bag ownership verification, culprit tracking, and automatic Dialog channel
  sound muting and restoration.
- **`ui/dialog.lua`:** The "Silence the train" dialog UI, wrapping a
  `SecureActionButtonTemplate` button with a `CooldownFrameTemplate` swipe
  overlay, combat lockdown queues, and dragging safeguards.
- **`types.lua`:** EmmyLua `---@meta` annotations for static type checking.
- **`scripts/setup_types.sh`:** Offline type definition installer for LuaLS.
- **`tests/test_train_wrecker.lua`:** Standalone Lua 5.1 test suite verifying
  detection, dedup, cooldown calculations, and combat transitions with mocked
  WoW engine APIs.

---

## 2. Formatting & Development Rules

### Indentation and Formatting

- **Use Tabs:** Indent Lua and XML code using tabs (`\t`).
- **Prose Wrapping:** Wrap all Markdown documentation and comments at 80
  characters.
- **Calm Tone:** Maintain a professional and calm tone in all code comments and
  messages. Avoid exclamation marks or dramatic phrasing.

### Spells, Items, and Asset Grounding

All IDs are grounded in Blizzard engine definitions:

- **Toy Train Set:** Item ID `44606`, Placement Spell ID `61031`, Periodic Pulse
  Spell ID `61551`.
- **Wind-Up Train Wrecker:** Item ID `45057`, Summon Spell ID `62943`.
- **Icon Texture:** Numeric FileDataID `134152`
  (`inv_misc_head_clockworkgnome_01`). Always document with the inline comment:
  `134152 -- FileDataID: inv_misc_head_clockworkgnome_01`.

### Execution Taint & Combat Lockdown Boundaries

Because the dialog contains a `SecureActionButtonTemplate` child frame:

1. **No Forbidden Mutations During Combat:** Never call `:Show()`, `:Hide()`,
   `:SetPoint()`, or `:SetAttribute()` on the dialog or action button while
   `InCombatLockdown()` returns true.
2. **State Transition Queuing:**
   - Queue show requests via `pendingShow = true`.
   - Queue hide requests via `pendingHide = true`.
   - Queue ownership/cooldown refreshes via `pendingRefresh = true`.
   - Flush all queued transitions on `PLAYER_REGEN_ENABLED`.
3. **Movable Frame Protection:**
   - Check `InCombatLockdown()` before initiating or ending frame dragging in
     `OnDragStart` and `OnDragStop`.
   - Stop movement immediately on `PLAYER_REGEN_DISABLED` if the frame is
     currently being dragged.
4. **No `UISpecialFrames` Registration:** Do not register the dialog in
   `UISpecialFrames` to avoid taint errors when the user presses `Escape` during
   combat.
5. **Secret Value Guard:** Check `issecretvalue` on `spellID`, `castGUID`,
   `unitTarget`, and `sourceName` before processing to remain safe during
   restricted encounters in modern clients.

### Automatic Dialog Sound Muting & Restoration

1. **State Preservation:** Only set `TrainWreckerDB.soundMuted = true` if
   `Sound_EnableDialog` was originally `"1"`. Never override or unmute the
   channel if the user already had it disabled.
2. **Placement Grace Period:** Enforce a 15-second grace window after placement
   (`61031`) or pulse (`61551`) casts so unrelated player aura changes do not
   prematurely unmute before periodic pulses land.
3. **Session Recovery:** Always check `TrainWreckerDB.soundMuted` on
   `PLAYER_ENTERING_WORLD` to restore audio if a previous session closed while
   muted.
4. **Encounter Safety:** Never mute Dialog sound while
   `C_InstanceEncounter.IsEncounterInProgress()` returns true.

---

## 3. Testing and Verification

Always validate changes through the three-pillar quality gate prior to staging:

1. **Pillar 1: Static Type Checking (LuaLS):**

   ```bash
   bash scripts/setup_types.sh
   lua-language-server --check . --checklevel=Warning
   ```

2. **Pillar 2: WoW Domain & Taint Linting (`wow_lua_lint`):** Run `wow_lua_lint`
   on all touched runtime `.lua` files for both supported client flavors:
   - Retail: `flavor: "mainline"`
   - MoP Classic: `flavor: "mists"` Pass
     `knownGlobals: ["TrainWreckerDB", "SLASH_TRAINWRECKER1", "SLASH_TRAINWRECKER2"]`.
3. **Pillar 3: Manifest, XML & Unit Testing:**
   - Run `wow_toc_validate` on `TrainWrecker.toc`.
   - Run `wow_xml_validate` on `main.xml` and `locales/locales.xml`.
   - Run bytecode syntax checks:
     `luac -p locales/*.lua core/*.lua ui/*.lua types.lua tests/test_train_wrecker.lua`.
   - Run unit test suite: `lua tests/test_train_wrecker.lua`.
