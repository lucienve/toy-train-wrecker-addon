# Train Wrecker (`TrainWrecker`)

Train Wrecker is a lightweight World of Warcraft addon supporting both Retail
(`120100`) and Mists of Pandaria Classic (`50504`) that detects when a Toy Train
Set is placed nearby and prompts you to deploy the Wind-Up Train Wrecker.

## Features

- **Automatic Detection:** Listens for Toy Train Set placement casts (Spell ID
  `61031`) and periodic pulses (Spell ID `61551`), extracting the culprit player
  name when available.
- **Silence Dialog:** Presents a movable dialog titled **"Silence the train"**:
  - **Owned Toy:** Displays a secure action button with a cooldown swipe overlay
    allowing one-click deployment of the Wind-Up Train Wrecker (Item ID
    `45057`). The button is always accessible, even while on cooldown.
  - **Unowned Toy:** Informs the player where to acquire the toy from Jepetto
    Joybuzz at the Wonderworks toy shop in Dalaran for 250 gold.
- **Combat Lockdown Safety:** Deferred queueing ensures dialog visibility and
  secure attribute changes never trigger UI errors or execution taint during
  combat encounters.
- **Auto-Dismiss:** Automatically closes the dialog as soon as you successfully
  summon the Wind-Up Train Wrecker.
- **Automatic Sound Muting:** Automatically mutes the Dialog sound channel
  whenever a Toy Train Set is placed nearby, pulses, or applies the Train buff
  to your character, silencing forced train emotes. Your original setting is
  automatically restored once the train effect ends or upon login if you logged
  out while muted. Sound muting is safely suspended during active dungeon and
  raid boss encounters.

## Commands

- `/trainwrecker` or `/tw`: Opens the dialog on demand for testing or manual use
  (outside combat).

## Supported Clients

- **Retail:** Interface `120100` (The War Within / Midnight)
- **Classic:** Interface `50504` (Mists of Pandaria Classic)

## License

This project is licensed under the terms of the MIT License. See
[LICENSE](./LICENSE) for details.
