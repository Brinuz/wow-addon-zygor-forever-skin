-- Style: a "blizzard" style in Zygor's skin registry. It inherits Starlight,
-- so anything not set here keeps Zygor's look; what is set here uses only
-- Blizzard textures and colors taken from the Professions window.
local _, ns = ...

local ZGV = ns.ZGV
local skin = ZGV and ZGV.Skins and ZGV.Skins:GetSkin("default")
if not (skin and skin.styles.starlight) then return end

local STYLE = skin:AddStyle("blizzard", "Blizzard", "starlight")
STYLE.GUIHidden = true      -- not offered in Zygor's own style dropdown
ns.style = STYLE

------------------- Blizzard textures
-- The player cast bar's fill; Chrome.lua adds its background and frame.
local CAST_FILL = "ui-castingbar-filling-standard"
local castFill = C_Texture.GetAtlasInfo(CAST_FILL)

------------------- Colors
local TRANSPARENT = {0, 0, 0, 0}
local GOLD = {NORMAL_FONT_COLOR:GetRGBA()}
local SHADE = {0, 0, 0, 0.35}           -- toolbar and active tab strip over the rock

------------------- Window
-- Chrome.lua draws the metal frame and rock background; Zygor's own window
-- backdrops go transparent so they show through.
STYLE.WindowBackdropColor = TRANSPARENT
STYLE.WindowBackdropBorderColor = TRANSPARENT
STYLE.WindowBottomBackdropColor = TRANSPARENT
STYLE.WindowBottomBackdropBorderColor = TRANSPARENT
STYLE.UseOpacity = false

-- Keep content clear of the metal edges, like ButtonFrameTemplate's Inset.
STYLE.ViewerMargin = 6

STYLE.SystemBarBackdropColor = SHADE
STYLE.SystemBarBackdropBorderColor = TRANSPARENT

------------------- Tabs
-- Tabs.lua draws them as recipe list headers; Zygor's own tab tints go transparent.
STYLE.TabsHeight = 22
STYLE.TabsDecorWidth = 6 -- text inset
STYLE.TabsBackdropActive = TRANSPARENT
STYLE.TabsBackdropInactive = TRANSPARENT
STYLE.TabsSeparatorColor = TRANSPARENT
STYLE.TabsBorderColor = TRANSPARENT
STYLE.TabsContainerBackdropActive = TRANSPARENT
STYLE.TabsContainerBackdropInactive = TRANSPARENT
STYLE.TabsTextColor = GOLD
STYLE.TabsTextColorOver = {1, 1, 1, 1}

------------------- Action bar: no background, like Blizzard's own bars
STYLE.ActionBarBackdropColor = TRANSPARENT
STYLE.ActionBarBackdropBorderColor = TRANSPARENT

------------------- Steps: quest log rows
-- No box: steps sit on the window background. An empty backdrop makes Zygor
-- clear the step's backdrop (and its tint for completed or skipped steps);
-- the colored goal lines inside a step stay. Steps.lua draws the current
-- step's highlight inside Zygor's current-step outline.
STYLE.StepBackdrop = {}
STYLE.StepBorderBackdrop = {}

-- Zygor's 1px line between every two steps becomes the professions recipe
-- list divider (Steps.lua sets the atlas; the color here keeps it untinted).
STYLE.StepStickySeparatorColor = {1, 1, 1, 1}
STYLE.StepStickyBarHeight = 3
STYLE.StepStickyBarSpace = 2
STYLE.StepPaddingTop = 3
STYLE.StepPaddingBottom = 3
STYLE.StepPaddingWidth = 4

------------------- Progress bar: the player cast bar
-- Zygor's own backdrop and caps go transparent; Chrome.lua draws the cast
-- bar's background and frame and crops the fill like a StatusBar would.
STYLE.ProgressBarBackdropColor = TRANSPARENT
STYLE.ProgressBarBackdropBorderColor = TRANSPARENT
STYLE.ProgressBarCapsColor = TRANSPARENT
STYLE.ProgressBarTextureColor = {1, 1, 1, 1}
STYLE.ProgressBarHeight = 10
STYLE.ProgressBarSpaceHeight = 20
if castFill then
	STYLE.ProgressBarCastAtlas = CAST_FILL
	STYLE.ProgressBarTextureFile = castFill.file
	STYLE.ProgressBarTextureFileOffset = {castFill.leftTexCoord, castFill.rightTexCoord,
		castFill.topTexCoord, castFill.bottomTexCoord}
end

------------------- Accents: Zygor's orange becomes Blizzard gold
STYLE.Accent = GOLD
STYLE.GuideMenuGuideButtonDecorColor = GOLD
STYLE.NotificationBubbleColor = GOLD
STYLE.MessageNotify = GOLD
