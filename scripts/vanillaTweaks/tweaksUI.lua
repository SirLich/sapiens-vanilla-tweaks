--- VanillaTweaks: tweaksUI.lua 
--- GameView which will be used to display the tweak UI.
--- @author SirLich

local tweaksUI = {
	name = "Tweaks UI",
	view = nil,
	parent = nil,
	icon = "icon_configure",
}

-- Hammerstone
local saveState = mjrequire "hammerstone/state/saveState"

-- Base
local model = mjrequire "common/model"
local gameConstants = mjrequire "common/gameConstants"
local timer = mjrequire "common/timer"

-- UI
local uiSlider = mjrequire "mainThread/ui/uiCommon/uiSlider"
local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiSelectionLayout = mjrequire "mainThread/ui/uiCommon/uiSelectionLayout"
local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"

-- Math
local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2

-- Globals
local backgroundWidth = 1140
local backgroundHeight = 640
local backgroundSize = vec2(backgroundWidth, backgroundHeight)

local buttonBoxWidth = 80
local buttonBoxHeight = backgroundHeight - 80.0
local buttonBoxSize = vec2(buttonBoxWidth, buttonBoxHeight)

local buttonWidth = 180
local buttonHeight = 40
local buttonSize = vec2(buttonWidth, buttonHeight)

local elementControlX = backgroundWidth * 0.5
local elementYOffsetStart = -20
local elementYOffset = elementYOffsetStart
local yOffsetBetweenElements = buttonHeight
local elementTitleX = - backgroundWidth * 0.5 - 10

-- ============================================================================
-- Copied from optionsView.lua
-- ============================================================================

local function addTitleHeader(parentView, title)
	if elementYOffset ~= elementYOffsetStart then
		elementYOffset = elementYOffset - 20
	end

	local textView = TextView.new(parentView)
	textView.font = Font(uiCommon.fontName, 16)
	textView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
	textView.baseOffset = vec3(0,elementYOffset - 4, 0)
	textView.text = title

	elementYOffset = elementYOffset - yOffsetBetweenElements
	return textView
end

local function addSlider(parentView, sliderTitle, min, max, value, changedFunction, continuousFunctionOrNil)
	local textView = TextView.new(parentView)
	textView.font = Font(uiCommon.fontName, 16)
	textView.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionTop)
	textView.baseOffset = vec3(elementTitleX,elementYOffset - 4, 0)
	textView.text = sliderTitle

	local options = nil
	local baseFunction = changedFunction
	if continuousFunctionOrNil then
		options = {
			continuous = true,
			releasedFunction = changedFunction
		}
		baseFunction = continuousFunctionOrNil
	end
	
	local sliderView = uiSlider:create(parentView, vec2(200, 20), min, max, value, options, baseFunction)
	sliderView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
	sliderView.baseOffset = vec3(elementControlX, elementYOffset - 6, 0)

	elementYOffset = elementYOffset - yOffsetBetweenElements
	uiSelectionLayout:addView(parentView, sliderView)
	return sliderView
end

-- ============================================================================
-- End of copied from optionsView.lua
-- ============================================================================

function tweaksUI:init(manageUI)
	--- Called when the UI is ready to be generated
	--- @param manageUI UI The UI that is your parent.

	-- Main View
	tweaksUI.view = View.new(manageUI.view)
	tweaksUI.view.size = backgroundSize
	tweaksUI.view.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
	tweaksUI.view.hidden = true

	-- Background View
	local backgroundView = ModelView.new(tweaksUI.view )
	backgroundView:setModel(model:modelIndexForName("ui_bg_lg_16x9"))
	local scaleToUse = backgroundSize.x * 0.5
	backgroundView.scale3D = vec3(scaleToUse,scaleToUse,scaleToUse)
	backgroundView.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
	backgroundView.size = backgroundSize

	-- Close Button
	local closeButton = uiStandardButton:create(backgroundView, vec2(50,50), uiStandardButton.types.markerLike)
	closeButton.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionAbove)
	closeButton.baseOffset = vec3(30, -20, 0)
	uiStandardButton:setIconModel(closeButton, "icon_cross")
	uiStandardButton:setClickFunction(closeButton, function()
		tweaksUI.view.hidden = true
	end)

	addTitleHeader(backgroundView, "Tweaks (remember to restart!)")

	-- Sliders
	addSlider(backgroundView, "Play Speed" .. ":", 0.1, 10, 2, function(newValue)
		-- gameConstants.playSpeed = newValue
		-- saveState:setValueClient("vt.playSpeed", newValue)
	end)
end

-- Called every frame
function tweaksUI:update(gameUI)
	-- Do nothing
end

return tweaksUI

