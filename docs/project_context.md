# Train Wrecker (`TrainWrecker`) — Project Context

## Project Overview

Train Wrecker is a standalone World of Warcraft addon supporting Retail
(`120100`) and Mists of Pandaria Classic (`50504`). It listens for nearby Toy
Train Sets and prompts the player to summon the Wind-Up Train Wrecker toy to
destroy the train.

## Architectural Decisions

1. **Multi-Flavor Interface Support:**
   - Declared `## Interface: 120100, 50504` in
     [TrainWrecker.toc](../TrainWrecker.toc), supported by both modern game
     clients and `BigWigsMods/packager@v2`.
   - Avoids separate TOC files and simplifies CI/CD release flows.

2. **Declarative FrameXML Button Template:**
   - Defined `TrainWreckerActionButtonTemplate` in [main.xml](../main.xml)
     inheriting `SecureActionButtonTemplate, UIPanelButtonTemplate`.
   - Creating secure action buttons via a named FrameXML template prevents
     execution taint and satisfies `wow_lua_lint` domain checks with zero
     warnings.

3. **Combat Lockdown Safeguards:**
   - The dialog contains a secure button, making UI mutations (show, hide,
     re-anchor, set attributes) protected during combat.
   - All state transitions (`pendingShow`, `pendingHide`, `pendingRefresh`) are
     deferred if `InCombatLockdown()` is true and flushed cleanly on
     `PLAYER_REGEN_ENABLED`.
   - Dragging is guarded by `InCombatLockdown()` and movement is stopped on
     `PLAYER_REGEN_DISABLED`.
   - The dialog is intentionally omitted from `UISpecialFrames` so pressing
     `Escape` during combat does not trigger taint errors.

4. **Secret Value Protection:**
   - Checked `issecretvalue` on `spellID`, `castGUID`, `unitTarget`, and
     `sourceName` in `UNIT_SPELLCAST_SUCCEEDED` to ensure safety during
     restricted encounters in Retail 12.0+ and Classic.

5. **Culprit Attribution & Deduplication:**
   - Deduplicates spellcasts within a 3-second window using `GetTime()` and
     `castGUID`.
   - When a placement cast (`61031`) provides a player name, it is displayed.
     Subsequent periodic pulses (`61551`) preserve the previously identified
     culprit name rather than overwriting it with a generic notice.

6. **Ownership & Mid-Session Learning:**
   - Checks `PlayerHasToy(45057)` and `C_Item.GetItemCount(45057)`.
   - Listens to `TOYS_UPDATED` and `BAG_UPDATE_DELAYED` to automatically update
     the dialog if the player purchases or learns the toy while the window is
     open.

7. **Cooldown Spiral Integration:**
   - Uses `C_Container.GetItemCooldown(45057)` to display a
     `CooldownFrameTemplate` swipe overlay on the button icon.
   - The button remains enabled and clickable at all times.

8. **CurseForge Packaging & Bundle Exclusions:**
   - Configured CurseForge Project ID `1779465` in
     [TrainWrecker.toc](../TrainWrecker.toc).
   - Configured [.pkgmeta](../.pkgmeta) `ignore:` rules to exclude all
     development, linting, CI/CD, test, and documentation files so only runtime
     addon files (`TrainWrecker.toc`, `main.xml`, `locales/`, `core/`, `ui/`),
     `CHANGELOG.md`, and `LICENSE` are bundled into the release archive.

## Completed Tasks

- [x] Initial repository structure and Git configuration
- [x] CurseForge `.pkgmeta` configuration
- [x] Maintenance rules in
      [.agents/rules/train_wrecker_maintenance_rules.md](../.agents/rules/train_wrecker_maintenance_rules.md)
- [x] Type definitions and setup script in
      [scripts/setup_types.sh](../scripts/setup_types.sh)
- [x] EmmyLua type metadata in [types.lua](../types.lua)
- [x] Multi-flavor manifest in [TrainWrecker.toc](../TrainWrecker.toc)
- [x] FrameXML script and template manifests in [main.xml](../main.xml) and
      [locales/locales.xml](../locales/locales.xml)
- [x] Localization dictionary in [locales/enUS.lua](../locales/enUS.lua)
- [x] Core lifecycle and slash commands in [core/init.lua](../core/init.lua)
- [x] Spell detection, dedup, and ownership checking in
      [core/detector.lua](../core/detector.lua)
- [x] UI dialog, secure action button, and combat queueing in
      [ui/dialog.lua](../ui/dialog.lua)
- [x] Standalone Lua 5.1 unit test suite in
      [tests/test_train_wrecker.lua](../tests/test_train_wrecker.lua)
- [x] CI/CD workflows in
      [.github/workflows/typecheck.yml](../.github/workflows/typecheck.yml) and
      [.github/workflows/release.yml](../.github/workflows/release.yml)
- [x] User documentation in [README.md](../README.md) and
      [CHANGELOG.md](../CHANGELOG.md)
