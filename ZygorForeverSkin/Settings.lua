-- Settings: the page under Options > AddOns, built with Blizzard's Settings API.
local addonName, ns = ...

local L = ns.L

local function Register()
	local category = Settings.RegisterVerticalLayoutCategory(ns.TITLE)

	local enabled = Settings.RegisterAddOnSetting(category, "ZYGORFOREVERSKIN_ENABLED", "enabled",
		ns.db, Settings.VarType.Boolean, L.ENABLED, true)
	enabled:SetValueChangedCallback(function()
		ns:Refresh()
	end)
	Settings.CreateCheckbox(category, enabled, L.ENABLED_TOOLTIP)

	Settings.RegisterAddOnCategory(category)
	ns.settingsCategory = category
end

function ns:OpenSettings()
	if self.settingsCategory then
		Settings.OpenToCategory(self.settingsCategory:GetID())
	end
end

-- ns.db exists only after ADDON_LOADED, which Core handles first.
ns:On("ADDON_LOADED", function(name)
	if name == addonName and not ns.settingsCategory then
		Register()
	end
end)
