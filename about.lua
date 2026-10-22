-- About tab (the same file is in every addon by Skom): how to get help, and the other addons.
local ADDON, ns = ...

local DISCORD = "skomzx"
local OWNER = "Ahmedrn"

-- name, what it does, optional note shown in orange
local ADDONS = {
	{ "SkomsPlateBuffs", "Enemy nameplate auras in rows around the plate: crowd control, immunities, cooldowns and your own debuffs, with glow and a spells tab." },
	{ "SkomsProcGlow", "Glows your action buttons when a spell is worth pressing: procs, execute range, usable-now spells. Works with Bartender4." },
	{ "SkomsHealerCC", "A big alert with a countdown and a sound when an enemy crowd control lands on your healer." },
	{ "SkomsAdvancedInterfaceOptions", "The hidden game settings (camera, nameplates, combat, chat, sound ...) in one window, kept at every login." },
	{ "SkomsProfileSync", "Set up one character, then copy its bars, keybinds, macros, BindPad and addon profiles to your other characters." },
	{ "SkomsChatShield", "Hides spam in every chat channel: editable phrases, blocked players, repeat and copy-paste detection." },
	{ "ArenaLFG", "2v2, 3v3 and DuoQ arena partner finder with synced listings.", "Warmane only: made for the Warmane server." },
}

local function Installed(name)
	if name == ADDON then return true end
	local ok, _, title = pcall(GetAddOnInfo, name)
	return ok and title ~= nil
end

function ns.AboutGroup(order)
	local g = { type = "group", name = "About", order = order or 99, args = {} }
	local a = g.args

	a.title = { type = "description", order = 1, fontSize = "large",
		name = function() return ("%s %s"):format(ADDON, GetAddOnMetadata(ADDON, "Version") or "") end }
	a.by = { type = "description", order = 2, fontSize = "medium", name = "by Skom" }
	a.notes = { type = "description", order = 3, fontSize = "medium",
		name = function() return "\n" .. (GetAddOnMetadata(ADDON, "Notes") or "") end }

	a.helpHeader = { type = "header", order = 10, name = "Help and feedback" }
	a.help = { type = "description", order = 11, fontSize = "medium",
		name = "A bug, something missing, or an idea? Tell me:\n"
			.. "- GitHub issues (the address below)\n"
			.. "- a comment on the Warperia page\n"
			.. "- Discord: |cffffd100" .. DISCORD .. "|r (direct message)\n"
			.. "If you can, say which class and spec you play and what you did before it went wrong." }
	a.issues = { type = "input", order = 12, width = "full", name = "GitHub issues (select the text and copy it)",
		get = function() return ("https://github.com/%s/%s/issues"):format(OWNER, ADDON) end, set = function() end }

	a.othersHeader = { type = "header", order = 20, name = "My other addons" }
	a.others = { type = "description", order = 21, fontSize = "medium",
		name = function()
			local lines = {}
			for _, e in ipairs(ADDONS) do
				if e[1] ~= ADDON then
					local state = Installed(e[1]) and "|cff55ff55installed|r" or "|cff999999not installed|r"
					local line = ("|cffffd100%s|r (%s)\n%s"):format(e[1], state, e[2])
					if e[3] then line = line .. " |cffff8800" .. e[3] .. "|r" end
					lines[#lines + 1] = line
				end
			end
			return table.concat(lines, "\n\n")
		end }
	a.links = { type = "input", order = 22, width = "full", multiline = 9, name = "Project pages (select the text and copy it)",
		get = function()
			local lines = {}
			for _, e in ipairs(ADDONS) do
				if e[1] ~= ADDON then lines[#lines + 1] = ("%s: https://github.com/%s/%s"):format(e[1], OWNER, e[1]) end
			end
			return table.concat(lines, "\n")
		end, set = function() end }
	return g
end
