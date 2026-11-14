-- Tabs: Zygor's guide tabs as flat headers, like the steps and the professions
-- recipe list: the active tab gets the list's selected-row highlight, others
-- its hover highlight, and a divider runs under the row. Zygor's own tab tints
-- come from the style and are transparent in ours.
local _, ns = ...

local ZGV = ns.ZGV

local SELECTED = "Professions_Recipe_Active"
local HOVER = "Professions_Recipe_Hover"
local DIVIDER = "RecipeList-Divider"

local function CreateArt(tab)
	local button = tab.Button
	tab.ZFSSelected = button:CreateTexture(nil, "BACKGROUND", nil, 5)
	tab.ZFSSelected:SetAtlas(SELECTED)
	tab.ZFSSelected:SetAllPoints()
	-- Like the recipe list's HighlightOverlay: half alpha, shown on mouseover.
	tab.ZFSHover = button:CreateTexture(nil, "HIGHLIGHT")
	tab.ZFSHover:SetAtlas(HOVER)
	tab.ZFSHover:SetAlpha(0.5)
	tab.ZFSHover:SetAllPoints()
end

local function StyleTab(tab, on)
	if on then
		if not tab.ZFSSelected then CreateArt(tab) end
		tab.Button:SetHeight(ZGV.UI.SkinData("TabsHeight"))
		tab.ZFSSelected:SetShown(tab.isActive and true or false)
		tab.ZFSHover:SetShown(not tab.isActive)
		-- White text when selected, gold otherwise. Keep Zygor's green for a
		-- background tab whose step is done (CheckForStepCompletion).
		local step = tab.guide and tab.guide.steps and tab.guide.steps[tab.step]
		if tab.isActive then
			tab.Text:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
		elseif step and step:IsComplete() then
			tab.Text:SetTextColor(GREEN_FONT_COLOR:GetRGB())
		else
			tab.Text:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
		end
	elseif tab.ZFSSelected then
		tab.ZFSSelected:Hide()
		tab.ZFSHover:Hide()
	end
end

-- The recipe list divider along the bottom of the tab row.
local function StyleDivider(on)
	local container = ZGV.Frame and ZGV.Frame.Border.TabContainer
	if not container then return end
	if on and not container.ZFSDivider then
		local divider = container:CreateTexture(nil, "OVERLAY")
		divider:SetAtlas(DIVIDER)
		divider:SetHeight(3)
		divider:SetPoint("BOTTOMLEFT")
		divider:SetPoint("BOTTOMRIGHT")
		container.ZFSDivider = divider
	end
	if container.ZFSDivider then
		container.ZFSDivider:SetShown(on)
	end
end

function ns:StyleTabs()
	local tabs = ZGV.Tabs
	if not (tabs and tabs.Pool) then return end
	local on = ns:IsActive()
	for _, tab in ipairs(tabs.Pool) do
		StyleTab(tab, on)
	end
	StyleDivider(on)
end

function ns:HookTabs()
	local tabs = ZGV.Tabs
	if not tabs then return end
	-- Tabs call these as tab:Method() through their metatable, so hooking the
	-- Tabs table reaches every tab. CreateTab is followed by SetAsCurrent or
	-- ReanchorTabs, which restyle the new tab.
	hooksecurefunc(tabs, "ApplySkin", function() ns:StyleTabs() end)
	hooksecurefunc(tabs, "SetAsCurrent", function() ns:StyleTabs() end)
	hooksecurefunc(tabs, "ReanchorTabs", function() ns:StyleTabs() end)
	-- Zygor recolors background tabs' text when their step completes.
	hooksecurefunc(tabs, "CheckForStepCompletion", function() ns:StyleTabs() end)
	ns:StyleTabs()
end
