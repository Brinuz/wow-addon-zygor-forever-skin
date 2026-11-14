-- Chrome: the Blizzard window around Zygor's viewer. Runs after Zygor's own
-- ApplySkin/AlignFrame and keys off the active style, so switching back to
-- Starlight undoes every change here.
local _, ns = ...

local L = ns.L

-- Blizzard's title strip is 21px (the background starts below it); Zygor's
-- title bar is 30px in its XML.
local TITLE_HEIGHT = 22
local ZYGOR_TITLE_HEIGHT = 30

local function SkinData(key)
	return ns.ZGV.UI.SkinData(key)
end

local function GetChrome(frame)
	if not frame.ZFSChrome then
		local chrome = CreateFrame("Frame", nil, frame.Border, "ZygorForeverSkinChromeTemplate")
		-- Same call ProfessionsMixin:OverrideArt makes for the Professions window.
		SetTextureWithAddressModeOptions(chrome.Bg, "Profession-Background-Overview")
		chrome.TitleContainer:SetFrameLevel(chrome:GetFrameLevel() + 10)
		chrome.TitleContainer.TitleText:SetText(L.VIEWER_TITLE)
		-- Blizzard's button, Zygor's behavior: the hidden Zygor button's handler.
		chrome.CloseButton:SetScript("OnClick", function()
			local zygorButton = frame.Controls.CloseButton
			frame.CloseButton_OnClick(zygorButton, "LeftButton")
		end)
		frame.ZFSChrome = chrome
	end
	return frame.ZFSChrome
end

-- ---------------------------------------------------------------- progress bar
-- Zygor grows its fill by resizing a texture, which would squash the cast
-- bar art. Crop the atlas to the filled fraction instead, like a StatusBar.
local function CropFill(bar)
	local atlas = SkinData("ProgressBarCastAtlas")
	local info = atlas and C_Texture.GetAtlasInfo(atlas)
	if not info then return end
	local full = bar.ClipFrame:GetWidth()
	local fraction = full > 0 and Clamp(bar.Texture:GetWidth() / full, 0, 1) or 0
	local right = info.leftTexCoord + (info.rightTexCoord - info.leftTexCoord) * fraction
	bar.Texture:SetTexCoord(info.leftTexCoord, right, info.topTexCoord, info.bottomTexCoord)
end

local function GetCastBar(bar)
	if not bar.ZFSCastBar then
		local cast = CreateFrame("Frame", nil, bar, "ZygorForeverSkinCastBarTemplate")
		-- Fill (ClipFrame) between the background and the frame; text on top.
		cast.BorderFrame:SetFrameLevel(bar.ClipFrame:GetFrameLevel() + 1)
		bar.TextContainer:SetFrameLevel(bar.ClipFrame:GetFrameLevel() + 2)
		hooksecurefunc(bar.Texture, "SetWidth", function()
			CropFill(bar)
		end)
		bar.ZFSCastBar = cast
	end
	return bar.ZFSCastBar
end

-- Zygor sets most of its progress bar up once, when the viewer is created,
-- from whichever style was active then. Re-apply those parts from the
-- current style.
local function StyleProgressBar()
	local bar = ns.ZGV.ProgressBar
	if not bar then return end
	bar:SetBackdrop(SkinData("ProgressBarBackdrop"))
	bar:SetBackdropColor(unpack(SkinData("ProgressBarBackdropColor")))
	bar:SetBackdropBorderColor(unpack(SkinData("ProgressBarBackdropBorderColor")))
	bar:SetHeight(SkinData("ProgressBarHeight"))
	bar.Texture:SetTexCoord(unpack(SkinData("ProgressBarTextureFileOffset")))
	bar.CapLeft:SetVertexColor(unpack(SkinData("ProgressBarCapsColor")))
	bar.CapRight:SetVertexColor(unpack(SkinData("ProgressBarCapsColor")))

	local castBar = SkinData("ProgressBarCastAtlas") ~= nil
	if castBar then
		GetCastBar(bar):Show()
		CropFill(bar)
	elseif bar.ZFSCastBar then
		bar.ZFSCastBar:Hide()
	end
end

-- ---------------------------------------------------------------- hooks
local function OnApplySkin(frame)
	local on = ns:IsActive()
	local zygorClose = frame.Controls.CloseButton
	if on then
		local chrome = GetChrome(frame)
		-- With the title bar at the bottom there is no title strip on top:
		-- fill the whole frame and put the close button on Zygor's bar.
		local upsideDown = ns.ZGV.db.profile.resizeup
		chrome.Bg:SetPoint("TOPLEFT", 2, upsideDown and -2 or -21)
		chrome.TitleContainer:SetShown(not upsideDown)
		if upsideDown then
			chrome.CloseButton:ClearAllPoints()
			chrome.CloseButton:SetPoint("RIGHT", frame.Controls.TitleBar, "RIGHT", 0, 0)
		else
			chrome.CloseButton:OnLoad() -- UIPanelCloseButtonDefaultAnchorsMixin: size and place
		end
		chrome:Show()
	elseif frame.ZFSChrome then
		frame.ZFSChrome:Hide()
	end

	zygorClose:SetShown(not on)
	frame.Controls.Logo:SetShown(not on)
	StyleProgressBar()
	-- Zygor re-skins these from SKIN_UPDATED through handlers it registered
	-- before our hooks existed, so follow up here on every skin change.
	ns:StyleActionBar()
	ns:StyleTabs()
	ns:StyleSteps(frame)
end

local function OnAlignFrame(frame)
	local on = ns:IsActive()
	local controls = frame.Controls
	controls.TitleBar:SetHeight(on and TITLE_HEIGHT or ZYGOR_TITLE_HEIGHT)
	-- Zygor places the step list at a fixed offset sized for its 30px title
	-- bar; follow the toolbar instead so the shorter title leaves no gap.
	if on and not ns.ZGV.db.profile.resizeup then
		controls.Scroll:SetPoint("TOPLEFT", controls.Toolbar, "BOTTOMLEFT", 0, -2)
	end
end

-- Zygor mixes ApplySkin/AlignFrame into the viewer frame itself, so hook the
-- instance. Called whenever Zygor (re)skins; hooks only once.
function ns:HookFrame(frame)
	if not frame or frame.ZFSHooked then return end
	frame.ZFSHooked = true
	hooksecurefunc(frame, "ApplySkin", OnApplySkin)
	hooksecurefunc(frame, "AlignFrame", OnAlignFrame)
	ns:HookSteps(frame)
end
