-- Steps: guide steps as quest log rows, as in the professions recipe list.
-- Zygor's separator between steps gets the list's divider art, and its
-- current-step outline frame gets the list's selected-row highlight.
local _, ns = ...

local DIVIDER = "RecipeList-Divider"
local SELECTED = "Professions_Recipe_Active"
-- Zygor's separator texture template (ZGV_DefaultSkin_StickySeparator_Template).
local ZYGOR_SEPARATOR = "Interface\\Buttons\\white8x8"

-- Zygor shows step.border only on the current step (ShowBorderIfCurrent),
-- and only when all steps are listed. Draw the highlight behind the step's
-- lines whenever that outline is shown.
local function UpdateHighlight(step)
	step.ZFSSelected:SetShown(ns:IsActive() and step.border:IsShown())
end

local function StyleStep(step)
	if not step.ZFSSelected then
		step.ZFSSelected = step:CreateTexture(nil, "BACKGROUND", nil, -1)
		step.ZFSSelected:SetAtlas(SELECTED)
		step.ZFSSelected:SetAllPoints()
		hooksecurefunc(step.border, "SetShown", function() UpdateHighlight(step) end)
		hooksecurefunc(step.border, "Show", function() UpdateHighlight(step) end)
		hooksecurefunc(step.border, "Hide", function() UpdateHighlight(step) end)
	end
	UpdateHighlight(step)
end

-- Pooled textures keep whatever was set on them, so set the art (or Zygor's
-- plain texture back) on every active one each time.
local function StyleDividers(frame)
	local on = ns:IsActive()
	for texture in frame.stickySepPool:EnumerateActive() do
		if on then
			texture:SetAtlas(DIVIDER)
		else
			texture:SetTexture(ZYGOR_SEPARATOR)
		end
	end
end

function ns:StyleSteps(frame)
	if not frame.stepFramePools then return end
	for _, pool in pairs(frame.stepFramePools) do
		for step in pool:EnumerateActive() do
			StyleStep(step)
		end
	end
	StyleDividers(frame)
end

-- AddStep places, renders and outlines one step, then the next call adds the
-- next one; restyle what it just added.
function ns:HookSteps(frame)
	hooksecurefunc(frame, "AddStep", function(self)
		local step = self.stepframes[#self.stepframes]
		if step then
			StyleStep(step)
		end
		StyleDividers(self)
	end)
end
