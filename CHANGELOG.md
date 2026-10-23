# Changelog

## Unreleased

- Revenge glows for 5 seconds after you block, dodge or parry, in any stance (the game only marks it usable in Defensive Stance). Overpower the same way after your target dodges. New triggers for your own rules.
- Warriors: Overpower, Revenge and Execute glow in another color (blue by default) while you are in a stance that cannot cast them, so you know to switch stance first. Can be switched off; the color can be changed.

## 1.1.0 (2026-10-22)

- An About tab in the options: how to get help (GitHub issues, Warperia, Discord) and the other addons by Skom, with what is installed. ArenaLFG is marked as Warmane only.
- `/spg` opens the addon's own settings window (it used to open only the Interface > AddOns list).

## 1.0.0 (2026-10-21)

First release.
- Glows action buttons when a spell is worth pressing, for every class. Works on the Blizzard bars, Bartender4, and ElvUI / Dominos buttons. A macro counts through its `#showtooltip` spell.
- Four triggers: a buff on you (a proc), the target's health below a threshold (execute range), your rage / energy / mana above a number, and a spell that has just become usable. A fifth, a debuff of yours on the target, covers Lava Burst with Flame Shock.
- 48 default rules for the 10 classes. The spell and buff names were checked against the 3.3.5a client data.
- Every rule can be switched off, given another glow style or colour, and have its buff, stacks or threshold changed. You can add rules for any spell on your bars.
- Glow styles: border, pixel glow, autocast shine, action button glow, proc glow (LibCustomGlow-1.0, which comes with WeakAuras; without it a border is used).
- By default a glow only shows while the spell is off cooldown (an option).
- `/spg` opens the options, `/spg test` shows each glow style on your first bar. The options also have a test button.
