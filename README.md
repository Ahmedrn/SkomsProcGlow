<p align="center"><img src="logo.png" alt="SkomsProcGlow" width="120"></p>

# SkomsProcGlow 1.0.0 (WoW 3.3.5a)

Glows your action buttons when a spell is worth pressing, for every class. Works on the Blizzard bars, **Bartender4** and most bar addons. A macro counts through its `#showtooltip` spell.

![Execute and other buttons glowing](screenshot.png)

## Triggers
- **A buff on you** (a proc): Sudden Death, Taste for Blood, Slam!, Sword and Board, Hot Streak, Missile Barrage, Brain Freeze, Fingers of Frost, Shadow Trance, Decimation, Molten Core, Backlash, Eclipse, Maelstrom Weapon (5 stacks), Rime, Killing Machine, Sudden Doom, The Art of War, Lock and Load, Surge of Light, Predator's Swiftness ...
- **The target's health is low:** Execute (below 20%), Drain Soul (below 25%).
- **Your rage / energy / mana is high:** Heroic Strike above 50 rage (Cleave too, switched off by default).
- **The spell becomes usable:** Overpower, Revenge, Victory Rush, Hammer of Wrath, Kill Shot, Mongoose Bite, Counterattack, Riposte.
- **A debuff of yours on the target:** Lava Burst with Flame Shock.

48 default rules for the 10 classes; the names are checked against the 3.3.5a client data. Each one can be switched off, given another glow style or colour, and have its buff, stacks or threshold changed. You can add rules for any spell on your bars.

## Glow styles
Border, pixel glow, autocast shine, action button glow, proc glow (the styles of WeakAuras, from LibCustomGlow-1.0). Without WeakAuras a border is used. `/spg test` (or the Test button in the options) shows each style on your first bar.

By default a glow only shows while the spell is off cooldown; this can be turned off in the options.

## Commands
`/spg` options, `/spg test`.

## Install
Put the `SkomsProcGlow` folder in `Interface\AddOns`.

## Help, missing rules and feedback
The default rules cover the 10 classes, but I cannot test every spec. If a rule is missing or wrong for your class or spec (a proc that does not glow, a wrong buff name, a glow that stays on), tell me the **class, spec and spell** and I will fix or add it:
- **GitHub issues:** https://github.com/Ahmedrn/SkomsProcGlow/issues
- **A comment on the Warperia page**
- **Discord:** `skomzx`

You can also add the rule yourself in `/spg` > *Your own rules*.

## Credits
- Glow styles: **LibCustomGlow-1.0** (used if present).
- Settings with **Ace3**.
- Idea: the spell activation glow of later versions of the game.
