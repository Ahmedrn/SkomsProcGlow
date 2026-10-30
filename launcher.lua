-- Skom's launcher (the same file is in every addon by Skom): with two or more of them loaded, one minimap
-- button opens a grid with all of them. The newest copy of this file does the work.
local ADDON = ...
local VERSION = 1

-- folder, name, slash command that opens it, slash command for its options (right-click)
local ADDONS = {
	{ "ArenaLFG", "ArenaLFG", "/alfg", "/alfg options" },
	{ "SkomsArenaStats", "Skom's Arena Stats", "/as", "/as options" },
	{ "SkomsPlateBuffs", "Skom's Plate Buffs", "/spb" },
	{ "SkomsProcGlow", "Skom's Proc Glow", "/spg" },
	{ "SkomsHealerCC", "Skom's Healer CC", "/shcc" },
	{ "SkomsAdvancedInterfaceOptions", "Skom's Advanced Interface Options", "/saio" },
	{ "SkomsProfileSync", "Skom's Profile Sync", "/sps" },
	{ "SkomsChatShield", "Skom's Chat Shield", "/scs" },
}

-- every copy says it is there (its icon exists); an older copy leaves the work to the newer one
local old = _G.SkomsLauncher
if old then old.registered[ADDON] = true end

-- one frame after the login, the newest copy starts: the addons have made their own buttons by then
local starter = CreateFrame("Frame")
starter:RegisterEvent("PLAYER_LOGIN")
starter:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_LOGIN")
	self:SetScript("OnUpdate", function(s)
		s:SetScript("OnUpdate", nil)
		_G.SkomsLauncher.Start()
	end)
end)

if old and old.version >= VERSION then return end

local L = { version = VERSION, registered = old and old.registered or {} }
L.registered[ADDON] = true
_G.SkomsLauncher = L

local RADIUS = 80
local COLS, SIZE, GAP = 4, 32, 6
local db, button, grid

local function Print(m) print("|cff33ff99Skom's|r: " .. m) end

local function Loaded()
	local list = {}
	for _, e in ipairs(ADDONS) do
		if IsAddOnLoaded(e[1]) then list[#list + 1] = e end
	end
	return list
end

-- runs a slash command as if it was typed ("/as options")
local function RunSlash(text)
	local cmd, rest = text:match("^(%S+)%s*(.*)$")
	cmd = cmd:lower()
	for key, fn in pairs(SlashCmdList) do
		local i = 1
		while _G["SLASH_" .. key .. i] do
			if _G["SLASH_" .. key .. i]:lower() == cmd then
				fn(rest)
				return
			end
			i = i + 1
		end
	end
end

local function BuildGrid()
	grid = CreateFrame("Frame", "SkomsLauncherGrid", UIParent)
	grid:SetFrameStrata("DIALOG")
	grid:SetClampedToScreen(true)
	grid:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
	grid:SetBackdropColor(0.05, 0.08, 0.18, 0.95)
	grid:SetBackdropBorderColor(0.83, 0.65, 0.26)
	grid:Hide()
	tinsert(UISpecialFrames, "SkomsLauncherGrid")   -- Escape closes it
	local list = Loaded()
	local cols, rows = math.min(COLS, #list), math.ceil(#list / COLS)
	grid:SetWidth(cols * SIZE + (cols - 1) * GAP + 20)
	grid:SetHeight(rows * SIZE + (rows - 1) * GAP + 20)
	for i, e in ipairs(list) do
		local b = CreateFrame("Button", nil, grid)
		b:SetWidth(SIZE); b:SetHeight(SIZE)
		b:SetPoint("TOPLEFT", 10 + ((i - 1) % COLS) * (SIZE + GAP), -10 - math.floor((i - 1) / COLS) * (SIZE + GAP))
		local icon = b:CreateTexture(nil, "ARTWORK")
		icon:SetAllPoints()
		-- an addon from before this file has no icon yet
		icon:SetTexture(L.registered[e[1]] and ("Interface\\AddOns\\" .. e[1] .. "\\icon") or "Interface\\Icons\\INV_Misc_QuestionMark")
		local hl = b:CreateTexture(nil, "HIGHLIGHT")
		hl:SetAllPoints()
		hl:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
		hl:SetBlendMode("ADD")
		b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		b:SetScript("OnClick", function(_, mouse)
			grid:Hide()
			RunSlash(mouse == "RightButton" and e[4] or e[3])
		end)
		b:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			local v = GetAddOnMetadata(e[1], "Version")
			GameTooltip:AddDoubleLine(e[2], v and ("v" .. v) or "", 1, 0.82, 0, 0.6, 0.6, 0.6)
			GameTooltip:AddLine("Click: open", 1, 1, 1)
			if e[4] then GameTooltip:AddLine("Right-click: options", 1, 1, 1) end
			GameTooltip:Show()
		end)
		b:SetScript("OnLeave", function() GameTooltip:Hide() end)
	end
end

-- opens next to the button, toward the middle of the screen
local function ToggleGrid()
	if not grid then BuildGrid() end
	if grid:IsShown() then grid:Hide() return end
	grid:ClearAllPoints()
	if button and button:IsVisible() then
		local x, y = button:GetCenter()
		local s = button:GetEffectiveScale() / UIParent:GetEffectiveScale()
		x, y = x * s, y * s
		local cx, cy = UIParent:GetCenter()
		local v, h = y > cy and "TOP" or "BOTTOM", x > cx and "RIGHT" or "LEFT"
		grid:SetPoint(v .. h, button, (y > cy and "BOTTOM" or "TOP") .. (x > cx and "LEFT" or "RIGHT"))
	else
		grid:SetPoint("CENTER")
	end
	grid:Show()
end

local function UpdatePosition()
	local a = math.rad(db.angle)
	button:ClearAllPoints()
	button:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * RADIUS, math.sin(a) * RADIUS)
end

-- while dragging: the angle between the minimap center and the cursor
local function OnDragUpdate()
	local mx, my = Minimap:GetCenter()
	local cx, cy = GetCursorPosition()
	local scale = Minimap:GetEffectiveScale()
	db.angle = math.deg(math.atan2(cy / scale - my, cx / scale - mx))
	UpdatePosition()
end

local function BuildButton()
	button = CreateFrame("Button", "SkomsLauncherButton", Minimap)
	button:SetWidth(31); button:SetHeight(31)
	button:SetFrameStrata("MEDIUM")
	button:SetFrameLevel(8)
	button:RegisterForClicks("LeftButtonUp")
	button:RegisterForDrag("LeftButton")
	button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
	local icon = button:CreateTexture(nil, "BACKGROUND")
	icon:SetWidth(20); icon:SetHeight(20)
	icon:SetPoint("TOPLEFT", 7, -5)
	icon:SetTexture("Interface\\AddOns\\" .. ADDON .. "\\skoms")
	local border = button:CreateTexture(nil, "OVERLAY")
	border:SetWidth(53); border:SetHeight(53)
	border:SetPoint("TOPLEFT")
	border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	button:SetScript("OnClick", ToggleGrid)
	button:SetScript("OnDragStart", function(self)
		self:SetScript("OnUpdate", OnDragUpdate)
		GameTooltip:Hide()
	end)
	button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
	button:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:AddLine("Skom's addons", 1, 0.82, 0)
		GameTooltip:AddLine("Click: show your addons", 1, 1, 1)
		GameTooltip:AddLine("Drag: move this button", 1, 1, 1)
		GameTooltip:AddLine("/skoms minimap: hide this button", 0.6, 0.6, 0.6)
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", function() GameTooltip:Hide() end)
	UpdatePosition()
	if db.hide then button:Hide() end
end

-- ArenaLFG and Skom's Arena Stats have their own button: this one replaces them
local function HideOwnButtons()
	if _G.ArenaLFGMinimapButton then _G.ArenaLFGMinimapButton:Hide() end
	local dbicon = LibStub and LibStub("LibDBIcon-1.0", true)
	if dbicon then pcall(dbicon.Hide, dbicon, "SkomsArenaStats") end
end

function L.Start()
	if L.started then return end
	L.started = true
	if #Loaded() < 2 then return end
	L.active = true
	SkomsLauncherDB = SkomsLauncherDB or {}
	db = SkomsLauncherDB
	if db.angle == nil then db.angle = 200 end
	HideOwnButtons()
	BuildButton()
	SLASH_SKOMSLAUNCHER1 = "/skoms"
	SlashCmdList["SKOMSLAUNCHER"] = function(msg)
		if strlower(strtrim(msg or "")) == "minimap" then
			db.hide = not db.hide
			if db.hide then button:Hide() else button:Show() end
			Print("minimap button " .. (db.hide and "hidden: /skoms opens your addons, /skoms minimap shows it again." or "shown."))
		else
			ToggleGrid()
		end
	end
end
