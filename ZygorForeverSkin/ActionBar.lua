-- ActionBar: Zygor's floating bar of guide actions (talk, kill, use item...)
-- with Blizzard action button art. Zygor's secure buttons take the clicks;
-- the overlays drawn on top of them are what we restyle, so nothing
-- protected is touched.
local _, ns = ...

local ZGV = ns.ZGV

-- Zygor draws its own glyphs for actions that have no game icon. Use game
-- icons instead, so they sit in Blizzard's button frames like any spell.
local ICONS = {
	TALK = {file = "Interface\\Icons\\UI_Chat"},
	KILL = {file = "Interface\\Icons\\Ability_DualWield"},
	EMOTE = {file = "Interface\\Icons\\Ability_Warrior_BattleShout"},
	SCRIPT = {file = "Interface\\Icons\\INV_Misc_ScrollUnrolled01"},
	-- Destroys grey items: Blizzard's trash can (the housing UI's delete
	-- button), a small glyph centered in the slot; a bag icon if missing.
	TRASH = {atlas = "common-icon-delete", glyph = true, file = "Interface\\Icons\\INV_Misc_Bag_08"},
}

-- A glyph fills this much of the button, centered on the slot background.
local GLYPH_SCALE = 0.65

-- ActionButtonTemplate's frame art is 46x45 around a 45x45 icon.
local BORDER_WIDTH_RATIO = 46 / 45

local pendingCombat = false

-- Overlays are pooled and reused for any action, so always reset the icon's
-- size: full button for icons, smaller and centered for a glyph.
local function SetIcon(overlay, icon)
	local texture = overlay.icon
	texture:ClearAllPoints()
	if icon and icon.atlas and C_Texture.GetAtlasInfo(icon.atlas) then
		texture:SetAtlas(icon.atlas)
		if icon.glyph then
			local w, h = overlay:GetSize()
			texture:SetPoint("CENTER")
			texture:SetSize(w * GLYPH_SCALE, h * GLYPH_SCALE)
			return
		end
	elseif icon then
		texture:SetTexture(icon.file)
		texture:SetTexCoord(0, 1, 0, 1)
	end
	texture:SetAllPoints()
end

local function StyleOverlay(overlay, on)
	local w, h = overlay:GetSize()
	if on then
		if not overlay.ZFSBorder then
			overlay.ZFSSlot = overlay:CreateTexture(nil, "BACKGROUND", nil, -1)
			overlay.ZFSSlot:SetAtlas("UI-HUD-ActionBar-IconFrame-Background")
			overlay.ZFSSlot:SetAllPoints()

			overlay.ZFSMask = overlay:CreateMaskTexture()
			overlay.ZFSMask:SetAtlas("UI-HUD-ActionBar-IconFrame-Mask", false, nil, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
			overlay.ZFSMask:SetAllPoints()

			overlay.ZFSBorder = overlay:CreateTexture(nil, "OVERLAY")
			overlay.ZFSBorder:SetAtlas("UI-HUD-ActionBar-IconFrame")
			overlay.ZFSBorder:SetPoint("TOPLEFT")
		end
		overlay.ZFSBorder:SetSize(w * BORDER_WIDTH_RATIO, h)
		overlay.ZFSSlot:Show()
		overlay.ZFSBorder:Show()
		if not overlay.ZFSMasked then
			overlay.icon:AddMaskTexture(overlay.ZFSMask)
			overlay.ZFSMasked = true
		end

		overlay:SetHighlightAtlas("UI-HUD-ActionBar-IconFrame-Mouseover")
		local highlight = overlay:GetHighlightTexture()
		highlight:ClearAllPoints()
		highlight:SetPoint("TOPLEFT")
		highlight:SetSize(w * BORDER_WIDTH_RATIO, h)

		SetIcon(overlay, overlay.ZFSIconKey and ICONS[overlay.ZFSIconKey])
	else
		if not overlay.ZFSBorder then return end
		overlay.ZFSSlot:Hide()
		overlay.ZFSBorder:Hide()
		if overlay.ZFSMasked then
			overlay.icon:RemoveMaskTexture(overlay.ZFSMask)
			overlay.ZFSMasked = false
		end
		-- Zygor's own highlight and glyph, as its pool init and Setup set them.
		overlay:SetHighlightTexture("Interface/Buttons/ButtonHilight-Square")
		overlay:GetHighlightTexture():SetAllPoints()
		SetIcon(overlay, nil)
		if overlay.ZFSIconKey then
			ZGV.IconSets.ActionBarIcons[overlay.ZFSIconKey]:AssignToTexture(overlay.icon)
		end
	end
end

-- Zygor's close button is one of its title buttons; swap in Blizzard's.
local function StyleClose(bar, on)
	if on and not bar.ZFSClose then
		local close = CreateFrame("Button", nil, bar, "UIPanelCloseButtonNoScripts")
		close:SetSize(20, 20)
		-- Follow Zygor's hidden button, which ActionBar:PositionX moves to the
		-- left or right end depending on the bar's direction.
		close:SetPoint("CENTER", bar.close, "CENTER")
		-- The bar itself is LOW; Zygor's buttons are MEDIUM. Stay above them.
		close:SetFrameStrata("MEDIUM")
		close:SetFrameLevel(bar:GetFrameLevel() + 20)
		close:SetScript("OnClick", function()
			bar.close:GetScript("OnClick")(bar.close, "LeftButton")
		end)
		bar.ZFSClose = close
	end
	if bar.ZFSClose then
		bar.ZFSClose:SetShown(on)
	end
	bar.close:SetShown(not on)
end

function ns:StyleActionBar()
	local actionBar = ZGV.ActionBar
	local bar = actionBar and actionBar.Frame
	if not bar then return end
	-- The bar is a secure state frame; restyle it out of combat only.
	if InCombatLockdown() then
		pendingCombat = true
		return
	end
	local on = ns:IsActive()

	-- Same as ActionBar:ApplySkin, from the current style. Ours is transparent:
	-- Blizzard's own action bars have no background behind the buttons.
	local SkinData = ZGV.UI.SkinData
	local opacity = SkinData("UseOpacity") and ZGV.db.profile.opacity or 1
	local r, g, b, a = unpack(SkinData("ActionBarBackdropColor"))
	bar:SetBackdrop(SkinData("ActionBarBackdrop"))
	bar:SetBackdropColor(r, g, b, a * opacity)
	r, g, b, a = unpack(SkinData("ActionBarBackdropBorderColor"))
	bar:SetBackdropBorderColor(r, g, b, a * opacity)

	StyleClose(bar, on)
	if actionBar.ButtonOverlayPool then
		for overlay in actionBar.ButtonOverlayPool:EnumerateActive() do
			StyleOverlay(overlay, on)
		end
	end
end

ns:On("PLAYER_REGEN_ENABLED", function()
	if pendingCombat then
		pendingCombat = false
		ns:StyleActionBar()
	end
end)

function ns:HookActionBar()
	local actionBar = ZGV.ActionBar
	if not actionBar then return end
	hooksecurefunc(actionBar, "CreateFrame", function() ns:StyleActionBar() end)
	hooksecurefunc(actionBar, "ApplySkin", function() ns:StyleActionBar() end)
	hooksecurefunc(actionBar, "ReanchorButtons", function() ns:StyleActionBar() end)
	-- Overlays copy the mixin when created; hook it before Zygor creates any,
	-- to learn which Zygor glyph a button asked for.
	if ZygorActionButtonOverlay_Mixin then
		hooksecurefunc(ZygorActionButtonOverlay_Mixin, "Setup", function(overlay, _, iconsetkey)
			overlay.ZFSIconKey = iconsetkey
			StyleOverlay(overlay, ns:IsActive())
		end)
	end
	ns:StyleActionBar()
end
