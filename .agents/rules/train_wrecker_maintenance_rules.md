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

---

## 4. Release Process & CurseForge Deployment

The addon uses `BigWigsMods/packager@v2` triggered by pushing annotated Git tags
to GitHub, which packages the release and publishes it to CurseForge (Project ID
`1779465`).

### 1. Proactive Release Suggestions

After completing a major feature, significant enhancement, or notable bug fix,
proactively ask the operator if they would like to prepare a new release.

### 2. Semantic Version Incrementing

Inspect the latest Git tags using `git tag -l` and recommend an appropriate
semantic version tag (`vX.Y.Z`):

- **Major (`vX.0.0`):** Breaking changes, massive architectural overhauls, or
  major milestones.
- **Minor (`vX.Y.0` / `v0.Y.0`):** New gameplay features, significant
  enhancements (e.g., automatic Dialog sound muting), or new UI modules.
- **Patch (`vX.Y.Z`):** Bug fixes, localization updates, or WoW client
  `## Interface:` bumps for patch releases.

### 3. Player-Friendly Changelog (`CHANGELOG.md`)

- Add a new section at the top of `CHANGELOG.md` matching the target version tag
  (e.g., `## v0.9.0`).
- Write clear, concise, player-friendly bullet points focusing on gameplay
  impact and user experience rather than internal function names or spell IDs.
- Wrap all Markdown prose at 80 characters.
- Stage `CHANGELOG.md` (`git add CHANGELOG.md` with `BypassSandbox: true`) and
  pause for operator review and commit.

### 4. Tagging and Publishing Flow

Because `BigWigsMods/packager` packages the exact commit pointed to by the tag,
the tag must never be created until after the changelog commit is completed:

1. **Commit Verification:** Confirm with the operator that all changes and
   `CHANGELOG.md` updates have been committed to `main`.
2. **Create Annotated Tag:** Create an annotated Git tag matching the release
   version on `HEAD`:

   ```bash
   git tag -a vX.Y.Z -m "Release vX.Y.Z"
   ```

3. **Push to GitHub:** Push both the branch commit and the new tag to GitHub:

   ```bash
   git push origin main
   git push origin vX.Y.Z
   ```

4. **Automated CI/CD:** GitHub Actions triggers `.github/workflows/release.yml`,
   runs the test suite, replaces `@project-version@` in `TrainWrecker.toc`, and
   uploads the release archive and changelog to CurseForge.
