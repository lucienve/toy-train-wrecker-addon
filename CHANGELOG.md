# Changelog

## v0.9.1

- Fixed an issue where walking up to an already-active Toy Train Set muted the
  dialog audio but did not open the "Silence the train" window.
- Fixed an issue where audio restoration could occasionally fail to re-enable
  your Dialog sound settings after the train effect expired.
- Added in-game chat confirmation notices when a Toy Train Set is placed,
  pulsed, or detected on your character.
- Added in-game chat messages confirming when dialog audio is muted and
  subsequently re-enabled.

## v0.9.0

- Added automatic Dialog sound muting while a Toy Train Set is active nearby,
  silencing the forced train emote vocalizations.
- Added automatic restoration of your original Dialog audio settings once the
  train effect expires, when the train is destroyed with the Wind-Up Train
  Wrecker, or upon login if a session ended while muted.
- Added boss encounter safety to suspend sound muting during active dungeon and
  raid encounters so vital combat voice callouts are never missed.

## v0.8.0

- Initial release of Train Wrecker (`TrainWrecker`).
- Added automatic detection for nearby Toy Train Set placements and pulses, with
  culprit player attribution.
- Added movable "Silence the train" dialog with a one-click button to summon the
  Wind-Up Train Wrecker toy and a live cooldown swipe overlay.
- Added vendor directions to Jepetto Joybuzz in Dalaran when the toy is unowned.
- Added combat lockdown safeguards and state queueing to prevent UI errors.
- Added `/trainwrecker` and `/tw` slash commands.
- Added multi-flavor support for Retail (`120100`) and Mists of Pandaria Classic
  (`50504`).
