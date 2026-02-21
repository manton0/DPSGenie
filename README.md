# DPSGenie

A rotation helper addon for the **Ascension** private server (WoW 3.3.5). DPSGenie evaluates spell priority lists and suggests the next optimal spell to cast, helping you maximize your DPS or tanking performance.

## Features

- **Spell Suggestion Buttons** — On-screen buttons show the next spell to cast with keybind display and cooldown sweeps
- **SpellFlash** — Highlights the matching button on your action bar (supports default bars, Bartender4, and ElvUI)
- **Rotation Editor** — Full GUI to create, edit, import, and export rotation priority lists
- **Spell & Item Support** — Rotations can include spells and usable items (trinkets, potions, etc.)
- **20+ Condition Types** — Fine-tune when spells should be suggested:
  - Health, Mana, Rage, Energy, Runic Power, Combo Points
  - Buffs & Debuffs (contains, stack count, time remaining)
  - Spell Cooldown, Spell Charges, Spell Known
  - Item Cooldown, Item Equipped
  - Combat state, Stance/Shapeshift Form
  - Target Casting (interruptible check), Target Classification (boss, elite, player)
  - Threat percentage and tanking status
  - Pet active, pet happiness
- **Multi-Unit Conditions** — Conditions can check Player, Target, Focus, Mouseover, or Pet
- **Sub-Groups** — Split rotations into tabbed priority groups (e.g. separate single-target and AoE)
- **Cross-Realm Compatible** — Works on both Classless and Class-bound Ascension realms
- **Import / Export** — Share rotations with other players via compressed strings

## Installation

1. Download the latest release from the [Releases page](https://github.com/manton0/DPSGenie/releases/latest)
2. Extract the ZIP into your `Interface/AddOns` folder
3. Start your client and enjoy

## Usage

- **Minimap Button** — Click the Genie minimap button to access the Rotation Editor, Spell Capture, and Settings from a dropdown menu. Drag the button around the minimap to reposition it.
- `/dps rota` — Open the Rotation Editor directly
- `/dps settings` — Open the Settings panel
- `/dps capture` — Open the Spell Capture window
- `/dps debug` — Toggle the Debug overlay
- Create a new rotation or pick a default one and click **Use** to activate it
- The suggestion buttons will appear during combat (configurable in settings)
- Use **Copy** to duplicate a default rotation and customize it

## Author

**mazer** (Discord: the_mazer)
