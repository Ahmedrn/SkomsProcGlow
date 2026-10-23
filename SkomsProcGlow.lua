local addonName, ns = ...

-- SkomsProcGlow: glows action buttons (Blizzard bars, Bartender4, ...) when a spell is worth pressing:
-- a proc buff on you, an execute range on the target, a spell that just became usable, a debuff of yours on the target.
-- Rules are data (rules.lua) and editable in the options. Macros count through their #showtooltip spell.
-- The glow styles are the ones of LibCustomGlow-1.0 (it comes with WeakAuras); without it a border is used.

local pairs, ipairs, type, select, tostring, tonumber = pairs, ipairs, type, select, tostring, tonumber
local wipe = wipe

local LCG
local function GetLCG()
	LCG = LCG or LibStub("LibCustomGlow-1.0", true)
	return LCG
end

local defaults = {
	profile = {
		enabled = true,
		requireReady = true,   -- only glow while the spell is off cooldown
		stanceHint = true,     -- another color when the spell needs another stance
		stanceColor = { 0.25, 0.55, 1 },
		overrides = {},        -- [ruleId] = { enabled, glow, color, buff, stacks, threshold }
		custom = {},           -- user rules
		nextCustom = 1,
	}
}
local P, db
local playerClass

-- ---------------------------------------------------------------------------------------------------------
-- rules
-- ---------------------------------------------------------------------------------------------------------
local nameRules = {}   -- [ability name] = { rule, ... }
local nameList = {}

local function Merge(rule)
	local o = P.overrides[rule.id]
	if not o then return rule end
	local m = {}
	for k, v in pairs(rule) do m[k] = v end
	for k, v in pairs(o) do m[k] = v end
	return m
end

local function Compile()
	wipe(nameRules)
	local function add(rule)
		if rule.enabled == false or rule.glow == "none" or not rule.ability or rule.ability == "" then return end
		local list = nameRules[rule.ability]
		if not list then
			list = {}
			nameRules[rule.ability] = list
		end
		list[#list + 1] = rule
	end
	for _, rule in ipairs(ns.DefaultRules[playerClass] or {}) do add(Merge(rule)) end
	for _, rule in ipairs(P.custom) do add(rule) end
end

-- ---------------------------------------------------------------------------------------------------------
-- conditions
-- ---------------------------------------------------------------------------------------------------------
local function HasAura(buff, stacks)
	if not buff or buff == "" then return false end
	local name, _, _, count = UnitBuff("player", buff)
	if not name then return false end
	if (count or 0) == 0 then count = 1 end
	return count >= (stacks or 1)
end

local function HasTargetDebuff(debuff)
	if not debuff or debuff == "" or not UnitExists("target") then return false end
	local name, _, _, _, _, _, _, caster = UnitDebuff("target", debuff)
	return name ~= nil and (caster == "player" or caster == "pet")
end

local function TargetHealthBelow(threshold)
	if not UnitExists("target") or not UnitCanAttack("player", "target") or UnitIsDeadOrGhost("target") then return false end
	local max = UnitHealthMax("target")
	if not max or max <= 0 then return false end
	return (UnitHealth("target") / max) * 100 < (threshold or 20)
end

-- Revenge: the game only says it is usable in Defensive Stance, so the window is read from the combat log
-- instead: you blocked, dodged or parried an attack (a partial block counts) in the last 5 seconds
local AVOID_WINDOW = 5
local avoidedUntil = 0
-- Overpower the same way (the game only marks it usable in Battle Stance): your attack was dodged
local dodgedUntil = 0
local AVOIDED = { BLOCK = true, DODGE = true, PARRY = true }

local function OnCombatLog(...)
	local event, sourceGUID, _, _, destGUID = select(2, ...)
	local hit
	local me = UnitGUID("player")
	if sourceGUID == me and ((event == "SWING_MISSED" and select(9, ...) == "DODGE")
		or ((event == "SPELL_MISSED" or event == "RANGE_MISSED") and select(12, ...) == "DODGE")) then
		dodgedUntil = GetTime() + AVOID_WINDOW
		return true
	end
	if destGUID == me then
		if event == "SWING_MISSED" then
			hit = AVOIDED[select(9, ...)]
		elseif event == "SPELL_MISSED" or event == "RANGE_MISSED" then
			hit = AVOIDED[select(12, ...)]
		elseif event == "SWING_DAMAGE" then
			hit = (select(13, ...) or 0) > 0
		elseif event == "SPELL_DAMAGE" or event == "RANGE_DAMAGE" then
			hit = (select(16, ...) or 0) > 0
		end
	elseif event == "SPELL_CAST_SUCCESS" and sourceGUID == me then
		local spell = select(10, ...)
		if spell == "Revenge" then avoidedUntil = 0; return true end   -- used up
		if spell == "Overpower" then dodgedUntil = 0; return true end
	end
	if hit then
		avoidedUntil = GetTime() + AVOID_WINDOW
		return true
	end
end

local function RuleActive(rule, slot)
	local ok
	local t = rule.trigger
	if t == "aura" then
		ok = HasAura(rule.buff, rule.stacks)
	elseif t == "debuff" then
		ok = HasTargetDebuff(rule.buff)
	elseif t == "health" then
		ok = TargetHealthBelow(rule.threshold)
	elseif t == "power" then
		ok = (UnitPower("player") or 0) > (rule.threshold or 50)
	elseif t == "avoided" then
		ok = GetTime() < avoidedUntil
	elseif t == "dodged" then
		ok = GetTime() < dodgedUntil
	elseif t == "usable" then
		local usable, noMana = IsUsableAction(slot)
		ok = usable or noMana   -- a proc does not wait for the resource
	end
	if not ok then return false end
	if P.requireReady then
		local start, duration = GetActionCooldown(slot)
		if start and start > 0 and duration and duration > 1.5 then return false end
	end
	return true
end

-- ---------------------------------------------------------------------------------------------------------
-- what is on a button
-- ---------------------------------------------------------------------------------------------------------
local TIP = "SkomsProcGlowTooltip"
local tooltip
local slotNames = {}   -- spells only: the name does not change

local function TooltipName(slot)
	if not tooltip then
		tooltip = CreateFrame("GameTooltip", TIP, UIParent, "GameTooltipTemplate")
	end
	tooltip:SetOwner(UIParent, "ANCHOR_NONE")
	tooltip:ClearLines()
	tooltip:SetAction(slot)
	local fs = _G[TIP .. "TextLeft1"]
	return fs and fs:GetText() or nil
end

local function SlotName(slot)
	local kind = GetActionInfo(slot)
	if kind == "macro" then
		return TooltipName(slot)   -- the #showtooltip spell; can change with conditionals
	elseif kind == "spell" then
		local n = slotNames[slot]
		if n == nil then
			n = TooltipName(slot) or false
			slotNames[slot] = n
		end
		return n or nil
	end
end

-- ---------------------------------------------------------------------------------------------------------
-- glow on a button
-- ---------------------------------------------------------------------------------------------------------
local LCG_START = { pixel = "PixelGlow_Start", shine = "AutoCastGlow_Start", button = "ButtonGlow_Start", proc = "ProcGlow_Start" }
local LCG_STOP = { pixel = "PixelGlow_Stop", shine = "AutoCastGlow_Stop", button = "ButtonGlow_Stop", proc = "ProcGlow_Stop" }
local KEY = "SPG"
local YELLOW = { 1, 0.85, 0.15 }

local function StopGlow(button)
	local t = button.spgType
	if not t then return end
	button.spgType, button.spgKey = nil, nil
	if t == "border" then
		if button.spgBorder then button.spgBorder:Hide() end
		return
	end
	local stop = LCG and LCG[LCG_STOP[t]]
	if stop then
		if t == "button" then stop(button) else stop(button, KEY) end
	end
end

local function ApplyGlow(button, style, color)
	if not style or style == "none" then
		StopGlow(button)
		return
	end
	if style ~= "border" then
		local lcg = GetLCG()
		if not (lcg and lcg[LCG_START[style]]) then style = "border" end
	end
	local key = style .. (color and (color[1] .. color[2] .. color[3]) or "native")
	if button.spgKey == key then return end
	StopGlow(button)
	button.spgType, button.spgKey = style, key
	if style == "border" then
		if not button.spgBorder then
			local tex = button:CreateTexture(nil, "OVERLAY")
			tex:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
			tex:SetBlendMode("ADD")
			tex:SetPoint("CENTER", button, "CENTER", 0, 0)
			button.spgBorder = tex
		end
		local c = color or YELLOW
		button.spgBorder:SetVertexColor(c[1], c[2], c[3])
		local w = button:GetWidth() or 36
		button.spgBorder:SetWidth(w * 1.8)
		button.spgBorder:SetHeight(w * 1.8)
		button.spgBorder:SetAlpha(0.9)
		button.spgBorder:Show()
		return
	end
	local c = color and { color[1], color[2], color[3], 1 } or nil
	if style == "pixel" then
		LCG.PixelGlow_Start(button, c, nil, nil, nil, 2, 0, 0, false, KEY)
	elseif style == "shine" then
		LCG.AutoCastGlow_Start(button, c, nil, nil, nil, 0, 0, KEY)
	elseif style == "button" then
		LCG.ButtonGlow_Start(button, c)
	elseif style == "proc" then
		LCG.ProcGlow_Start(button, { color = c, startAnim = false, key = KEY })
	end
end

-- ---------------------------------------------------------------------------------------------------------
-- evaluating the buttons
-- ---------------------------------------------------------------------------------------------------------
local buttons = {}   -- every action button we have seen

local testButtons = {}

-- the stances a warrior spell can be cast in (the ones not listed work in any stance)
local STANCES = {
	["Overpower"] = { ["Battle Stance"] = true },
	["Revenge"] = { ["Defensive Stance"] = true },
	["Execute"] = { ["Battle Stance"] = true, ["Berserker Stance"] = true },
}

local function CurrentStance()
	for i = 1, (GetNumShapeshiftForms() or 0) do
		local _, name, active = GetShapeshiftFormInfo(i)
		if active then return name end
	end
end

local function WrongStance(spell)
	local need = playerClass == "WARRIOR" and STANCES[spell]
	if not need then return false end
	local now = CurrentStance()
	return not (now and need[now])
end

local function Evaluate(button)
	if testButtons and testButtons[button] then return end
	local slot = button.action
	local style, color
	if P.enabled and type(slot) == "number" and HasAction(slot) and button:IsVisible() then
		local name = SlotName(slot)
		local rules = name and nameRules[name]
		if rules then
			for i = 1, #rules do
				local r = rules[i]
				if RuleActive(r, slot) then
					style, color = r.glow, r.color
					if P.stanceHint and WrongStance(name) then color = P.stanceColor end
					break
				end
			end
		end
	end
	ApplyGlow(button, style, color)
end

local function EvaluateAll()
	for button in pairs(buttons) do Evaluate(button) end
end

local function Register(button)
	if button and not buttons[button] and button.action ~= nil then
		buttons[button] = true
	end
end

local PREFIXES = {
	{ "ActionButton", 12 }, { "MultiBarBottomLeftButton", 12 }, { "MultiBarBottomRightButton", 12 },
	{ "MultiBarRightButton", 12 }, { "MultiBarLeftButton", 12 }, { "BonusActionButton", 12 },
	{ "BT4Button", 180 }, { "DominosActionButton", 120 },
}

local function Scan()
	for _, p in ipairs(PREFIXES) do
		for i = 1, p[2] do
			local b = _G[p[1] .. i]
			if b then Register(b) end
		end
	end
	for bar = 1, 10 do   -- ElvUI
		for i = 1, 12 do
			local b = _G["ElvUI_Bar" .. bar .. "Button" .. i]
			if b then Register(b) end
		end
	end
end

local dirty, waited = false, 0
local frame = CreateFrame("Frame")
frame:SetScript("OnUpdate", function(self, elapsed)
	waited = waited + elapsed
	if avoidedUntil > 0 and GetTime() >= avoidedUntil then avoidedUntil = 0; dirty = true end
	if dodgedUntil > 0 and GetTime() >= dodgedUntil then dodgedUntil = 0; dirty = true end
	if dirty and waited >= 0.05 then
		dirty, waited = false, 0
		EvaluateAll()
	end
end)

local function Dirty() dirty = true end

-- every bar addon calls this when a button changes
if hooksecurefunc then
	hooksecurefunc("ActionButton_Update", function(self)
		if self and not buttons[self] then Register(self) end
		dirty = true
	end)
end

local function Reset()
	wipe(slotNames)
	Compile()
	for button in pairs(buttons) do ApplyGlow(button, nil) end
	dirty = true
end

-- ---------------------------------------------------------------------------------------------------------
-- options
-- ---------------------------------------------------------------------------------------------------------
local GLOW_VALUES = { none = "No glow", border = "Border", pixel = "Pixel glow", shine = "Autocast shine", button = "Action button glow", proc = "Proc glow" }
local GLOW_SORT = { "none", "border", "pixel", "shine", "button", "proc" }
local TRIGGERS = { aura = "A buff on you", debuff = "A debuff of yours on the target", health = "The target's health is low", usable = "The spell becomes usable", avoided = "You blocked, dodged or parried (5 sec)", dodged = "Your target dodged (5 sec)", power = "Your rage / energy / mana is high" }

local function Describe(rule)
	local t = rule.trigger
	if t == "aura" then
		return "when you have " .. (rule.buff or "?") .. ((rule.stacks and rule.stacks > 1) and (" x" .. rule.stacks) or "")
	elseif t == "debuff" then
		return "when your " .. (rule.buff or "?") .. " is on the target"
	elseif t == "health" then
		return "when the target is below " .. (rule.threshold or 20) .. "%"
	elseif t == "power" then
		return "when your rage / energy / mana is above " .. (rule.threshold or 50)
	elseif t == "avoided" then
		return "for 5 sec after you block, dodge or parry, in any stance"
	elseif t == "dodged" then
		return "for 5 sec after your target dodges, in any stance"
	end
	return "when it becomes usable"
end

local optionsRoot
local rulesGroup, customGroup

local function Notify()
	local reg = LibStub("AceConfigRegistry-3.0", true)
	if reg then reg:NotifyChange("SkomsProcGlow") end
end

-- the editors of one rule; `get`/`set` read and write the merged value
local function RuleEditors(getRule, setField, onReset, onRemove)
	local function show(trigger) return function() return getRule().trigger ~= trigger end end
	local args = {
		enabled = {
			type = "toggle", name = "Enabled", order = 1,
			get = function() return getRule().enabled ~= false end,
			set = function(_, v) setField("enabled", v) end,
		},
		glow = {
			type = "select", name = "Glow", order = 2, values = GLOW_VALUES, sorting = GLOW_SORT,
			get = function() return getRule().glow or "proc" end,
			set = function(_, v) setField("glow", v) end,
		},
		customColor = {
			type = "toggle", name = "Custom color", order = 3,
			desc = "Off: the native look of the glow style (yellow).",
			get = function() return getRule().color ~= nil end,
			set = function(_, v) setField("color", v and { 1, 0.85, 0.15 } or false) end,
		},
		color = {
			type = "color", name = "Color", order = 4,
			disabled = function() return getRule().color == nil end,
			get = function() local c = getRule().color or YELLOW; return c[1], c[2], c[3] end,
			set = function(_, r, g, b) setField("color", { r, g, b }) end,
		},
		buff = {
			type = "input", name = "Buff / debuff name", order = 5, width = "double",
			hidden = function() local t = getRule().trigger; return t ~= "aura" and t ~= "debuff" end,
			get = function() return getRule().buff or "" end,
			set = function(_, v) setField("buff", v) end,
		},
		stacks = {
			type = "range", name = "Stacks needed", order = 6, min = 1, max = 10, step = 1,
			hidden = show("aura"),
			get = function() return getRule().stacks or 1 end,
			set = function(_, v) setField("stacks", v) end,
		},
		threshold = {
			type = "range", name = "Target health below (%)", order = 7, min = 5, max = 100, step = 1,
			hidden = show("health"),
			get = function() return getRule().threshold or 20 end,
			set = function(_, v) setField("threshold", v) end,
		},
		power = {
			type = "range", name = "Rage / energy / mana above", order = 8, min = 1, max = 150, step = 1,
			hidden = show("power"),
			get = function() return getRule().threshold or 50 end,
			set = function(_, v) setField("threshold", v) end,
		},
	}
	if onReset then args.reset = { type = "execute", name = "Reset this rule", order = 20, func = onReset } end
	if onRemove then args.remove = { type = "execute", name = "Remove this rule", order = 21, func = onRemove } end
	return args
end

local function ColorOrNil(v) if v == false then return nil end return v end

local function BuildRules()
	wipe(rulesGroup.args)
	local list = ns.DefaultRules[playerClass] or {}
	if #list == 0 then
		rulesGroup.args.none = { type = "description", name = "No default rules for this class yet. Add your own below.", order = 1 }
	end
	for i, base in ipairs(list) do
		local id = base.id
		local function getRule() return Merge(base) end
		local function setField(k, v)
			local o = P.overrides[id]
			if not o then
				o = {}
				P.overrides[id] = o
			end
			if k == "color" then
				-- false = "back to native": store nil by clearing the override and removing the base colour
				o.color = ColorOrNil(v)
				if v == false then o.color = nil end
			else
				o[k] = v
			end
			Reset()
		end
		rulesGroup.args[id] = {
			type = "group", order = i, inline = false,
			name = function()
				local r = getRule()
				local n = r.ability .. "  |cff999999" .. Describe(r) .. "|r"
				if r.enabled == false then return "|cff808080" .. r.ability .. "|r" end
				return n
			end,
			desc = function() return Describe(getRule()) end,
			args = RuleEditors(getRule, setField, function() P.overrides[id] = nil; Reset(); Notify() end),
		}
	end
end

local addForm = { ability = "", trigger = "aura", buff = "", stacks = 1, threshold = 20, glow = "proc" }

local function BuildCustom()
	for k in pairs(customGroup.args) do
		if k:find("^rule") then customGroup.args[k] = nil end
	end
	for i, rule in ipairs(P.custom) do
		local function getRule() return rule end
		local function setField(k, v)
			if k == "color" then rule.color = (v ~= false) and v or nil else rule[k] = v end
			Reset()
		end
		customGroup.args["rule" .. rule.id] = {
			type = "group", order = 20 + i,
			name = function() return (rule.ability or "?") .. "  |cff999999" .. Describe(rule) .. "|r" end,
			args = (function()
				local a = RuleEditors(getRule, setField, nil, function()
					for j, r in ipairs(P.custom) do if r == rule then table.remove(P.custom, j) break end end
					Reset(); BuildCustom(); Notify()
				end)
				a.ability = { type = "input", name = "Spell on the button", order = 0, get = function() return rule.ability end,
					set = function(_, v) rule.ability = v; Reset() end }
				a.trigger = { type = "select", name = "When", order = 0.5, values = TRIGGERS,
					get = function() return rule.trigger end, set = function(_, v) rule.trigger = v; Reset(); Notify() end }
				return a
			end)(),
		}
	end
end

local function BuildOptions()
	optionsRoot = {
		type = "group", name = "SkomsProcGlow",
		args = {
			enabled = {
				type = "toggle", name = "Enabled", order = 1,
				get = function() return P.enabled end,
				set = function(_, v) P.enabled = v; Reset() end,
			},
			requireReady = {
				type = "toggle", order = 2, width = "full", name = "Only glow while the spell is off cooldown",
				get = function() return P.requireReady end,
				set = function(_, v) P.requireReady = v; Reset() end,
			},
			stanceHint = {
				type = "toggle", order = 2.1, width = "double", name = "Another color when you must change stance first",
				desc = "Warriors: Overpower (Battle Stance), Revenge (Defensive Stance) and Execute (Battle or Berserker Stance) glow in this color while you are in another stance.",
				get = function() return P.stanceHint end,
				set = function(_, v) P.stanceHint = v; Reset() end,
			},
			stanceColor = {
				type = "color", order = 2.2, name = "Stance color",
				disabled = function() return not P.stanceHint end,
				get = function() local c = P.stanceColor; return c[1], c[2], c[3] end,
				set = function(_, r, g, b) P.stanceColor = { r, g, b }; Reset() end,
			},
			info = {
				type = "description", order = 3,
				name = "Glows work on the Blizzard bars, Bartender4 and most bar addons. A macro counts through its #showtooltip spell. "
					.. "Pixel glow, autocast shine, action button glow and proc glow come from LibCustomGlow-1.0 (included with WeakAuras); without it a border is used.",
			},
			test = { type = "execute", order = 4, name = "Test the glow styles", desc = "Shows each style on the first bar's buttons for a few seconds.",
				func = function() ns.Test() end },
			rules = { type = "group", order = 10, name = "Rules for your class", args = {} },
			help = {
				type = "group", order = 30, name = "Help and feedback",
				args = {
					text = { type = "description", fontSize = "medium", order = 1,
						name = "A rule missing for your class or spec, a wrong buff name, a glow that does not show? Tell me which class, spec and spell and I will fix or add it.\n\n"
							.. "- GitHub issues: https://github.com/Ahmedrn/SkomsProcGlow/issues\n"
							.. "- A comment on the Warperia page\n"
							.. "- Discord: skomzx" },
				},
			},
			custom = {
				type = "group", order = 20, name = "Your own rules",
				args = {
					desc = { type = "description", order = 1, name = "Add a rule for any spell on your bars. The spell name is the name on the button (a macro uses its #showtooltip spell)." },
					ability = { type = "input", order = 2, name = "Spell on the button", get = function() return addForm.ability end, set = function(_, v) addForm.ability = v end },
					trigger = { type = "select", order = 3, name = "When", values = TRIGGERS, get = function() return addForm.trigger end, set = function(_, v) addForm.trigger = v end },
					buff = { type = "input", order = 4, name = "Buff / debuff name", hidden = function() return addForm.trigger ~= "aura" and addForm.trigger ~= "debuff" end,
						get = function() return addForm.buff end, set = function(_, v) addForm.buff = v end },
					threshold = { type = "range", order = 5, name = "Target health below (%)", min = 5, max = 100, step = 1, hidden = function() return addForm.trigger ~= "health" end,
						get = function() return addForm.threshold end, set = function(_, v) addForm.threshold = v end },
					power = { type = "range", order = 5.5, name = "Rage / energy / mana above", min = 1, max = 150, step = 1, hidden = function() return addForm.trigger ~= "power" end,
						get = function() return addForm.threshold end, set = function(_, v) addForm.threshold = v end },
					glow = { type = "select", order = 6, name = "Glow", values = GLOW_VALUES, sorting = GLOW_SORT,
						get = function() return addForm.glow end, set = function(_, v) addForm.glow = v end },
					add = { type = "execute", order = 7, name = "Add the rule", func = function()
						if addForm.ability == "" then return end
						local id = "C" .. P.nextCustom
						P.nextCustom = P.nextCustom + 1
						P.custom[#P.custom + 1] = { id = id, ability = addForm.ability, trigger = addForm.trigger, buff = addForm.buff,
							threshold = addForm.threshold, stacks = addForm.stacks, glow = addForm.glow }
						addForm.ability, addForm.buff = "", ""
						Reset(); BuildCustom(); Notify()
					end },
				},
			},
		},
	}
	rulesGroup, customGroup = optionsRoot.args.rules, optionsRoot.args.custom
	BuildRules()
	BuildCustom()
	return optionsRoot
end

-- ---------------------------------------------------------------------------------------------------------
-- test: every style on the first buttons
-- ---------------------------------------------------------------------------------------------------------
-- test: every style on the first buttons (the normal evaluation leaves those buttons alone meanwhile)

function ns.Test()
	-- visible buttons from every bar we know (Blizzard, Bartender4, ...), lowest action slot first
	Scan()
	local list = {}
	for button in pairs(buttons) do
		if type(button.action) == "number" and button:IsVisible() then list[#list + 1] = button end
	end
	table.sort(list, function(a, b) return a.action < b.action end)
	local order = { "border", "pixel", "shine", "button", "proc" }
	if #list == 0 then
		print("|cff33ff99SkomsProcGlow|r: no visible action buttons found.")
		return
	end
	print("|cff33ff99SkomsProcGlow|r: showing border, pixel, shine, button and proc glow on your first " .. math.min(#list, #order) .. " buttons for 6 seconds.")
	local used = {}
	for i, b in ipairs(list) do
		if order[i] then
			testButtons[b] = true
			used[#used + 1] = b
			ApplyGlow(b, order[i])
		end
	end
	local t = CreateFrame("Frame")
	local waited = 0
	t:SetScript("OnUpdate", function(self, e)
		waited = waited + e
		if waited >= 6 then
			self:SetScript("OnUpdate", nil)
			for _, b in ipairs(used) do
				testButtons[b] = nil
				ApplyGlow(b, nil)
			end
			dirty = true
		end
	end)
end

-- ---------------------------------------------------------------------------------------------------------
-- start
-- ---------------------------------------------------------------------------------------------------------
local events = CreateFrame("Frame")
events:SetScript("OnEvent", function(self, event, arg1, ...)
	if event == "PLAYER_LOGIN" then
		playerClass = select(2, UnitClass("player"))
		db = LibStub("AceDB-3.0"):New("SkomsProcGlowDB", defaults, true)
		P = db.profile
		local function profileChanged() P = db.profile; Reset(); BuildRules(); BuildCustom(); Notify() end
		db.RegisterCallback(ns, "OnProfileChanged", profileChanged)
		db.RegisterCallback(ns, "OnProfileCopied", profileChanged)
		db.RegisterCallback(ns, "OnProfileReset", profileChanged)
		Compile()
		local options = BuildOptions()
		if ns.AboutGroup then options.args.about = ns.AboutGroup(99) end   -- about.lua needs a full restart after an update
		LibStub("AceConfig-3.0"):RegisterOptionsTable("SkomsProcGlow", options)
		LibStub("AceConfigDialog-3.0"):AddToBlizOptions("SkomsProcGlow", "SkomsProcGlow")
		LibStub("AceConfig-3.0"):RegisterOptionsTable("SkomsProcGlowProfiles", LibStub("AceDBOptions-3.0"):GetOptionsTable(db))
		LibStub("AceConfigDialog-3.0"):AddToBlizOptions("SkomsProcGlowProfiles", "Profiles", "SkomsProcGlow")
		Scan()
		dirty = true
	elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
		if OnCombatLog(arg1, ...) then dirty = true end
	elseif event == "PLAYER_ENTERING_WORLD" then
		Scan()
		wipe(slotNames)
		dirty = true
	elseif event == "UNIT_AURA" or event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" or event == "UNIT_RAGE" or event == "UNIT_ENERGY"
		or event == "UNIT_MANA" or event == "UNIT_RUNIC_POWER" or event == "UNIT_FOCUS" then
		if arg1 == "player" or arg1 == "target" then dirty = true end
	elseif event == "ACTIONBAR_SLOT_CHANGED" or event == "UPDATE_SHAPESHIFT_FORM" or event == "ACTIONBAR_PAGE_CHANGED"
		or event == "UPDATE_BONUS_ACTIONBAR" or event == "SPELLS_CHANGED" or event == "UPDATE_MACROS" then
		wipe(slotNames)
		dirty = true
	else
		dirty = true
	end
end)
for _, e in ipairs{ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "UNIT_AURA", "UNIT_HEALTH", "UNIT_MAXHEALTH", "PLAYER_TARGET_CHANGED",
                    "UNIT_RAGE", "UNIT_ENERGY", "UNIT_MANA", "UNIT_RUNIC_POWER", "UNIT_FOCUS",
                    "ACTIONBAR_UPDATE_USABLE", "ACTIONBAR_UPDATE_COOLDOWN", "ACTIONBAR_SLOT_CHANGED", "UPDATE_SHAPESHIFT_FORM",
                    "ACTIONBAR_PAGE_CHANGED", "UPDATE_BONUS_ACTIONBAR", "SPELLS_CHANGED", "UPDATE_MACROS", "PLAYER_REGEN_DISABLED",
                    "PLAYER_REGEN_ENABLED", "COMBAT_LOG_EVENT_UNFILTERED" } do
	events:RegisterEvent(e)
end

SLASH_SKOMSPROCGLOW1 = "/spg"
SLASH_SKOMSPROCGLOW2 = "/skomsprocglow"
SlashCmdList["SKOMSPROCGLOW"] = function(msg)
	msg = (msg or ""):lower()
	if msg == "test" then
		ns.Test()
	else
		-- own window: InterfaceOptionsFrame_OpenToCategory often only opens the AddOns list
		local ACD = LibStub("AceConfigDialog-3.0")
		if ACD.OpenFrames["SkomsProcGlow"] then
			ACD:Close("SkomsProcGlow")
		else
			if InterfaceOptionsFrame and InterfaceOptionsFrame:IsShown() then InterfaceOptionsFrame:Hide() end
			ACD:Open("SkomsProcGlow")
		end
	end
end

-- for tests
ns.Evaluate, ns.Compile, ns.Scan, ns.Register, ns.EvaluateAll = Evaluate, Compile, Scan, Register, EvaluateAll
ns.SetClass = function(c) playerClass = c end
