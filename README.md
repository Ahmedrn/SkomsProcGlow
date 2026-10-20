# SkomsProcGlow 0.1.2 (WoW 3.3.5a)

Glows your action buttons when a spell is worth pressing, for every class. Works on the Blizzard bars, **Bartender4** and most bar addons. A macro counts through its `#showtooltip` spell.

## Triggers
- **A buff on you** (a proc): Sudden Death, Taste for Blood, Slam!, Sword and Board, Hot Streak, Missile Barrage, Brain Freeze, Fingers of Frost, Shadow Trance, Decimation, Molten Core, Backlash, Eclipse, Maelstrom Weapon (5 stacks), Rime, Killing Machine, Sudden Doom, The Art of War, Lock and Load, Surge of Light, Predator's Swiftness ...
- **The target's health is low:** Execute (below 20%), Drain Soul (below 25%).
- **Your rage / energy / mana is high:** Heroic Strike above 50 rage (Cleave too, switched off by default).
- **The spell becomes usable:** Overpower, Revenge, Victory Rush, Hammer of Wrath, Kill Shot, Mongoose Bite, Counterattack, Riposte.
- **A debuff of yours on the target:** Lava Burst with Flame Shock.

48 default rules for the 10 classes; the names are checked against the 3.3.5a client data. Each one can be switched off, given another glow style or colour, and have its buff, stacks or health threshold changed. You can add rules for any spell on your bars.

## Glow styles
Border, pixel glow, autocast shine, action button glow, proc glow (the styles of WeakAuras, from LibCustomGlow-1.0). Without WeakAuras a border is used. `/spg test` shows each style on your first bar.

## Commands
`/spg` options, `/spg test`.

## Install
Put the `SkomsProcGlow` folder in `Interface\AddOns`.

## Credits
- Glow styles: **LibCustomGlow-1.0** (used if present).
- Settings with **Ace3**.
- Idea: the spell activation glow of later versions of the game.
