local _, ns = ...

-- Default rules per class. Names are the 3.3.5a spell names (checked against the client data).
--   ability  the spell on the button (a macro counts when its #showtooltip spell is this one)
--   trigger  aura    = a buff on you (buff, stacks)
--            debuff  = a debuff of yours on the target (buff)
--            nodebuff = your debuff (buff) is missing on the target or fades in under `remaining` seconds
--            health  = the target's health is below `threshold` percent
--            power   = your rage / energy / mana / runic power is above `threshold`
--            avoided = you blocked, dodged or parried in the last 5 seconds (Revenge, in any stance)
--            dodged  = your target dodged in the last 5 seconds (Overpower, in any stance)
--            usable  = the game says the spell is usable right now (Overpower, Revenge, Victory Rush, Kill Shot ...)
--   glow     none, border, pixel, shine, button, proc
ns.DefaultRules = {
	WARRIOR = {
		{ id = "WAR_EXE_SD",  ability = "Execute",       trigger = "aura",   buff = "Sudden Death",    glow = "proc" },
		{ id = "WAR_EXE_HP",  ability = "Execute",       trigger = "health", threshold = 20,           glow = "button" },
		{ id = "WAR_OP",      ability = "Overpower",     trigger = "dodged",                           glow = "proc" },
		{ id = "WAR_OP_TFB",  ability = "Overpower",     trigger = "aura",   buff = "Taste for Blood", glow = "proc" },
		{ id = "WAR_REV",     ability = "Revenge",       trigger = "avoided",                          glow = "proc" },
		{ id = "WAR_VR",      ability = "Victory Rush",  trigger = "usable",                           glow = "proc" },
		{ id = "WAR_SLAM",    ability = "Slam",          trigger = "aura",   buff = "Slam!",           glow = "proc" },
		{ id = "WAR_SS",      ability = "Shield Slam",   trigger = "aura",   buff = "Sword and Board", glow = "proc" },
		{ id = "WAR_HS",      ability = "Heroic Strike", trigger = "power",  threshold = 50,           glow = "button" },
		{ id = "WAR_CLV",     ability = "Cleave",        trigger = "power",  threshold = 50,           glow = "button", enabled = false },
	},
	PALADIN = {
		{ id = "PAL_HOW",     ability = "Hammer of Wrath", trigger = "usable",                         glow = "button" },
		{ id = "PAL_EXO",     ability = "Exorcism",      trigger = "aura",   buff = "The Art of War",  glow = "proc" },
	},
	HUNTER = {
		{ id = "HUN_KS",      ability = "Kill Shot",     trigger = "usable",                           glow = "button" },
		{ id = "HUN_ES",      ability = "Explosive Shot", trigger = "aura",  buff = "Lock and Load",   glow = "proc" },
		{ id = "HUN_AS",      ability = "Arcane Shot",   trigger = "aura",   buff = "Lock and Load",   glow = "proc" },
		{ id = "HUN_MB",      ability = "Mongoose Bite", trigger = "usable",                           glow = "proc" },
		{ id = "HUN_CA",      ability = "Counterattack", trigger = "usable",                           glow = "proc" },
	},
	ROGUE = {
		{ id = "ROG_RIP",     ability = "Riposte",       trigger = "usable",                           glow = "proc" },
	},
	PRIEST = {
		{ id = "PRI_FH",      ability = "Flash Heal",    trigger = "aura",   buff = "Surge of Light",  glow = "proc" },
		{ id = "PRI_SWD",     ability = "Shadow Word: Death", trigger = "health", threshold = 35,      glow = "button", enabled = false },
	},
	MAGE = {
		{ id = "MAG_PYRO",    ability = "Pyroblast",     trigger = "aura",   buff = "Hot Streak",      glow = "proc" },
		{ id = "MAG_AM",      ability = "Arcane Missiles", trigger = "aura", buff = "Missile Barrage", glow = "proc" },
		{ id = "MAG_FB",      ability = "Fireball",      trigger = "aura",   buff = "Brain Freeze",    glow = "proc" },
		{ id = "MAG_FFB",     ability = "Frostfire Bolt", trigger = "aura",  buff = "Brain Freeze",    glow = "proc" },
		{ id = "MAG_DF",      ability = "Deep Freeze",   trigger = "aura",   buff = "Fingers of Frost", glow = "proc" },
		{ id = "MAG_IL",      ability = "Ice Lance",     trigger = "aura",   buff = "Fingers of Frost", glow = "proc" },
	},
	WARLOCK = {
		{ id = "WLK_SB",      ability = "Shadow Bolt",   trigger = "aura",   buff = "Shadow Trance",   glow = "proc" },
		{ id = "WLK_SB_BL",   ability = "Shadow Bolt",   trigger = "aura",   buff = "Backlash",        glow = "proc" },
		{ id = "WLK_INC_BL",  ability = "Incinerate",    trigger = "aura",   buff = "Backlash",        glow = "proc" },
		{ id = "WLK_SF",      ability = "Soul Fire",     trigger = "aura",   buff = "Decimation",      glow = "proc" },
		{ id = "WLK_INC",     ability = "Incinerate",    trigger = "aura",   buff = "Molten Core",     glow = "proc" },
		{ id = "WLK_DS",      ability = "Drain Soul",    trigger = "health", threshold = 25,           glow = "button" },
	},
	DRUID = {
		{ id = "DRU_SF",      ability = "Starfire",      trigger = "aura",   buff = "Eclipse (Lunar)", glow = "proc" },
		{ id = "DRU_WR",      ability = "Wrath",         trigger = "aura",   buff = "Eclipse (Solar)", glow = "proc" },
		{ id = "DRU_HT",      ability = "Healing Touch", trigger = "aura",   buff = "Predator's Swiftness", glow = "proc" },
		{ id = "DRU_RG",      ability = "Regrowth",      trigger = "aura",   buff = "Predator's Swiftness", glow = "proc" },
		{ id = "DRU_NO",      ability = "Nourish",       trigger = "aura",   buff = "Predator's Swiftness", glow = "proc" },
	},
	SHAMAN = {
		{ id = "SHA_LB",      ability = "Lightning Bolt", trigger = "aura",  buff = "Maelstrom Weapon", stacks = 5, glow = "proc" },
		{ id = "SHA_CL",      ability = "Chain Lightning", trigger = "aura", buff = "Maelstrom Weapon", stacks = 5, glow = "proc" },
		{ id = "SHA_HW",      ability = "Healing Wave",  trigger = "aura",   buff = "Maelstrom Weapon", stacks = 5, glow = "proc" },
		{ id = "SHA_LHW",     ability = "Lesser Healing Wave", trigger = "aura", buff = "Maelstrom Weapon", stacks = 5, glow = "proc" },
		{ id = "SHA_CH",      ability = "Chain Heal",    trigger = "aura",   buff = "Maelstrom Weapon", stacks = 5, glow = "proc" },
		{ id = "SHA_HEX",     ability = "Hex",           trigger = "aura",   buff = "Maelstrom Weapon", stacks = 5, glow = "proc" },
		{ id = "SHA_LVB",     ability = "Lava Burst",    trigger = "debuff", buff = "Flame Shock",     glow = "proc" },
	},
	DEATHKNIGHT = {
		{ id = "DK_HB",       ability = "Howling Blast", trigger = "aura",   buff = "Rime",            glow = "proc" },
		{ id = "DK_OBL",      ability = "Obliterate",    trigger = "aura",   buff = "Killing Machine", glow = "proc" },
		{ id = "DK_FS",       ability = "Frost Strike",  trigger = "aura",   buff = "Killing Machine", glow = "proc" },
		{ id = "DK_DC",       ability = "Death Coil",    trigger = "aura",   buff = "Sudden Doom",     glow = "proc" },
	},
}
