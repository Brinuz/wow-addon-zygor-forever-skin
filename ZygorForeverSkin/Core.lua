-- Core: the shared table, saved settings, event routing, switching Zygor to
-- our style, and the slash command.
local addonName, ns = ...

ns.TITLE = "Zygor Forever Skin"
ns.SLASH = "/zfs"

-- Zygor's addon table. A hard dependency in the .toc, so it is always here.
ns.ZGV = ZygorGuidesViewer

ns.L = {
	VIEWER_TITLE = "Zygor Guides",
	ENABLED = "Blizzard style",
	ENABLED_TOOLTIP = "Draw the Zygor guide viewer with Blizzard's window frame, fonts and colors.",
	ENABLED_ON = "Blizzard style on.",
	ENABLED_OFF = "Blizzard style off: Zygor's own skin is back.",
	NO_ZYGOR = "Zygor's skin system was not found; nothing to restyle.",
}

local DEFAULTS = {
	enabled = true,
}

-- ---------------------------------------------------------------- events
-- Files subscribe with ns:On(event, fn); one frame dispatches them all.
local handlers = {}
local eventFrame = CreateFrame("Frame")

function ns:On(event, fn)
	if not handlers[event] then
		handlers[event] = {}
		eventFrame:RegisterEvent(event)
	end
	table.insert(handlers[event], fn)
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
	for _, fn in ipairs(handlers[event]) do
		fn(...)
	end
end)

function ns:Print(msg)
	print(NORMAL_FONT_COLOR:WrapTextInColorCode(ns.TITLE .. ":") .. " " .. msg)
end

function ns:IsEnabled()
	-- Zygor skins itself before our saved variables exist; default to on.
	return not ns.db or ns.db.enabled
end

-- Whether Zygor is drawing with our style right now. Every restyle keys off
-- this, so switching back to Starlight undoes them all.
function ns:IsActive()
	return ns.style ~= nil and ns.ZGV.CurrentSkinStyle == ns.style
end

-- ---------------------------------------------------------------- skin switch
-- Zygor's saved style stays "starlight": we only swap the live style table
-- after Zygor picks its own. Disabling this addon then leaves Zygor exactly
-- as it was, with no unknown style id in its settings.
local hooked = false

local function SwapStyle()
	local ZGV = ns.ZGV
	if not ns:IsEnabled() or not ns.style then return end
	if ZGV.CurrentSkin ~= ns.style.skin or ZGV.CurrentSkinStyle == ns.style then return end

	ZGV.CurrentSkinStyle = ns.style
	-- Same steps as ZGV:SetSkin after it picks a style. ZGV.StyleDir keeps
	-- Starlight's folder, which our inherited texture paths point into.
	ZGV.IconSets:Create()
	ZGV.ButtonSets:Create()
	ZGV:SendMessage("SKIN_UPDATED")
	ZGV.CurrentSkin:CreateFrame()
end

local function InstallHooks()
	if hooked then return end
	hooked = true
	local ZGV = ns.ZGV
	hooksecurefunc(ZGV, "SetSkin", function()
		ns:HookFrame(ZGV.Frame)
		SwapStyle()
	end)
	-- The viewer usually exists already: Zygor skins it on its own ADDON_LOADED.
	if ZGV.Frame then
		ns:HookFrame(ZGV.Frame)
		SwapStyle()
	end
	ns:HookActionBar()
	ns:HookTabs()
end

-- Re-run Zygor's own skin selection; our hook then applies ours if enabled.
function ns:Refresh()
	local ZGV = ns.ZGV
	if ZGV.db and ZGV.Frame then
		ZGV:SetSkin(ZGV.db.profile.skin, ZGV.db.profile.skinstyle)
	end
end

-- Saved variables exist only from ADDON_LOADED on. Fill missing defaults.
ns:On("ADDON_LOADED", function(name)
	if name ~= addonName then return end
	ZygorForeverSkinDB = ZygorForeverSkinDB or {}
	for k, v in pairs(DEFAULTS) do
		if ZygorForeverSkinDB[k] == nil then
			ZygorForeverSkinDB[k] = v
		end
	end
	ns.db = ZygorForeverSkinDB

	if not (ns.ZGV and ns.ZGV.Skins and ns.style) then
		ns:Print(ns.L.NO_ZYGOR)
		return
	end
	InstallHooks()
end)

-- ---------------------------------------------------------------- slash
local function Debug()
	local ZGV = ns.ZGV
	local frame = ZGV and ZGV.Frame
	ns:Print("debug")
	print("  enabled:", ns:IsEnabled(), " hooks:", hooked)
	print("  skin:", ZGV.CurrentSkin and ZGV.CurrentSkin.id, " style:", ZGV.CurrentSkinStyle and ZGV.CurrentSkinStyle.id,
		" saved style:", ZGV.db and ZGV.db.profile.skinstyle)
	if frame then
		print(("  viewer: %dx%d scale %.2f, upside down: %s"):format(frame:GetWidth(), frame:GetHeight(),
			frame:GetEffectiveScale(), tostring(ZGV.db.profile.resizeup)))
		print("  chrome shown:", frame.ZFSChrome and frame.ZFSChrome:IsShown() or false,
			" title bar height:", frame.Controls.TitleBar:GetHeight())
	else
		print("  viewer: not created yet")
	end
end

SLASH_ZYGORFOREVERSKIN1 = ns.SLASH
SlashCmdList.ZYGORFOREVERSKIN = function(msg)
	msg = strtrim(msg or ""):lower()
	if msg == "debug" then
		Debug()
	elseif msg == "options" then
		ns:OpenSettings()
	else
		ns.db.enabled = not ns.db.enabled
		ns:Refresh()
		ns:Print(ns.db.enabled and ns.L.ENABLED_ON or ns.L.ENABLED_OFF)
	end
end
