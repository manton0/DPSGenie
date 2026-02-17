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

1. Download the newest version under **Code > Download ZIP** [Download](https://github.com/manton0/DPSGenie/archive/refs/heads/main.zip)
2. Extract the ZIP content into your `Interface/AddOns` folder
3. Make sure the folder is called `DPSGenie`
4. Start your client and enjoy

## Usage

- Use the **Rota** button on top of your screen to open the Rotation Editor
- Create a new rotation or pick a default one and click **Use** to activate it
- The suggestion buttons will appear during combat (configurable in settings)
- Use **Copy** to duplicate a default rotation and customize it

## Author

**mazer** (Discord: the_mazer)
