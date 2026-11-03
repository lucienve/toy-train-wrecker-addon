# Changelog

## 1.1.0

- Added automatic Dialog sound channel muting while a Toy Train Set is present
  (on placement cast `61031`, periodic pulses `61551`, and player buff `61551`).
- Added automatic restoration of Dialog sound settings when the train effect
  expires, when the train is wrecked, or upon login if the session ended while
  muted.
- Added active encounter safeguards
  (`C_InstanceEncounter.IsEncounterInProgress`) to prevent muting during boss
  encounters.

## 1.0.0

- Initial release of Train Wrecker (`TrainWrecker`).
- Added automatic detection for Toy Train Set placement (`61031`) and pulses
  (`61551`).
- Added movable "Silence the train" dialog with culprit player attribution.
- Added `SecureActionButtonTemplate` button with cooldown swipe overlay for the
  Wind-Up Train Wrecker (`45057`).
- Added Dalaran vendor directions when the toy is unowned.
- Added robust combat lockdown queueing and dragging guards.
- Added `/trainwrecker` and `/tw` slash commands.
- Added multi-flavor support for Retail (`120100`) and Mists of Pandaria Classic
  (`50504`).
