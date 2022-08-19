--- VanillaTweaks: tweaksUI.lua 
--- GameView which will be used to display the tweak UI.
--- @author SirLich

local tweaksUI = {
	name = "Vanilla Tweeks",
	view = nil,
	parent = nil,
	icon = "icon_edit",

	-- The setting slots (renderd conditionally based on the current selection)
	settingSlots = {},
}

-- Hammerstone
local saveState = mjrequire "hammerstone/state/saveState"

-- Base
local model = mjrequire "common/model"
local logicInterface = mjrequire "mainThread/logicInterface"
local gameConstants = mjrequire "common/gameConstants"
local timer = mjrequire "common/timer"
local skill = mjrequire "common/skill"

-- UI
local uiSlider = mjrequire "mainThread/ui/uiCommon/uiSlider"
local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
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

local function addSlider(parentView, sliderTitle, min, max, currentValue, defaultValue, floatDivisor, changedFunction)
	--- Adds a slider, which allows you to manipulate a settings value
	--- using form-control inputs.
	--- @param parentView View The view to add the slider to.
	--- @param sliderTitle Text The title of the slider.
	--- @param min Int The minimum value of the slider.
	--- @param max Int The maximum value of the slider.
	--- @param currentValue Int The current value of the slider.
	--- @param defaultValue Int The default value of the slider.
	--- @param floatDivisor Int The divisor to use when converting the slider value to a float.
	--- @param changedFunction Function The function to call when the slider value changes.

	local sliderTitleView = TextView.new(parentView)
	sliderTitleView.font = Font(uiCommon.fontName, 16)
	sliderTitleView.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionTop)
	sliderTitleView.baseOffset = vec3(elementTitleX,elementYOffset - 4, 0)
	sliderTitleView.text = sliderTitle
	
	local sliderValueView = nil

	-- Adjust the changed function to also include the slider value view
	local super_changedFunction = changedFunction
	changedFunction = function(newValue)
		local floatValue = newValue / floatDivisor
		super_changedFunction(floatValue)
		sliderValueView.text = string.format("%.1f", floatValue)
	end

	local sliderView = uiSlider:create(parentView, vec2(300, 20), min, max, currentValue, nil, changedFunction)
	sliderView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
	sliderView.baseOffset = vec3(elementControlX, elementYOffset - 6, 0)
	
	sliderValueView = TextView.new(parentView)
	sliderValueView.font = Font(uiCommon.fontName, 16)
	sliderValueView.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
	sliderValueView.relativeView = sliderView
	sliderValueView.baseOffset = vec3(2,0, 0)

	local resetButtonSize = vec2(80, 20)
	local resetButton = uiStandardButton:create(parentView, resetButtonSize)
	resetButton.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
	resetButton.relativeView = sliderValueView
	resetButton.baseOffset = vec3(25, 0, 0)

	-- Reset Button
	uiStandardButton:setText(resetButton, "Reset")
	uiStandardButton:setClickFunction(resetButton, function()
		local sliderValue = defaultValue * floatDivisor
		changedFunction(sliderValue)
		uiSlider:setValue(sliderView, sliderValue)
	end)

	-- TODO: Come up with a better solution than this
	local MEANINGLESS_DELAY = 5
	timer:addCallbackTimer(MEANINGLESS_DELAY, function()
		-- Initial trigger to set the time values and text
		-- done after a delay to let other systems catch up
		changedFunction(currentValue)
	end)



	
	uiSlider:setValue(sliderView, currentValue)

	elementYOffset = elementYOffset - yOffsetBetweenElements
	return sliderView
end

-- ============================================================================
-- End of copied from optionsView.lua
-- ============================================================================

local function getCurrentSpeedValue(speedKey, ratio)
	local current = saveState:getValueClient("vt." .. speedKey)
	if current == nil then
		current = gameConstants[speedKey]
	else
		current = current * ratio
	end

	return current
end

local function getCurrentValue(key, ratio, default)
	return saveState:getValueClient("vt." .. key, default) * ratio
end

local function setSpeedConstantAndReload(constantName, newValue)
	local paramTable = {
		constantName = constantName,
		value = newValue
	}

	gameConstants[constantName] = newValue
	saveState:setValueClient("vt." .. constantName, newValue)

	mj:log("Setting " .. constantName .. " to " .. newValue)

	logicInterface:callServerFunction("setGameConstantServer", paramTable)
	logicInterface:callServerFunction("setFastForward", true)
	logicInterface:callServerFunction("setFastForward", false)
end

-- Positional information for the sidebar buttons
local buttonSlotOffset = -50
local currentButtonSlotOffset = 50

function tweaksUI:addSettingSlot(parentView, buttonName, slot)
	--- Inserts a new 'settings slot'
	--- @param parentView View - The view to add the slot to.
	--- @param buttonName string - The name of the button (left sidebar)
	--- @param slot View The view to render on the right side (contains the settings)

	table.insert(self.settingSlots, slot)
	slot.hidden = true
	
	local button = uiStandardButton:create(parentView, buttonSize)
	button.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
	button.baseOffset = vec3(0, currentButtonSlotOffset, 3)
	currentButtonSlotOffset =  currentButtonSlotOffset + buttonSlotOffset

	uiStandardButton:setText(button, buttonName)
	uiStandardButton:setClickFunction(button, function()
		for _, slot in ipairs(self.settingSlots) do
			slot.hidden = true
		end

		slot.hidden = false
	end)

end


function tweaksUI:generateTimeSlot(parentView)
	--- Creates a settings UI which manages the settings for time related tweaks.

	local timeSlot = View.new(parentView)
	timeSlot.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
	timeSlot.size = backgroundSize

	addTitleHeader(timeSlot, "Time Tweaks")

	addSlider(timeSlot, "Pause Speed: ", 0, 100, getCurrentSpeedValue("pauseSpeed", 100), 0, 100, function(newValue)
		setSpeedConstantAndReload("pauseSpeed", newValue)
	end)

	addSlider(timeSlot, "Play Speed: ", 1, 100, getCurrentSpeedValue("playSpeed", 20), 1, 20, function(newValue)
		setSpeedConstantAndReload("playSpeed", newValue)
	end)

	addSlider(timeSlot, "Fast Speed: ", 1, 300, getCurrentSpeedValue("fastSpeed", 10), 3, 10, function(newValue)
		setSpeedConstantAndReload("fastSpeed", newValue)
	end)

	addSlider(timeSlot, "Ultra Speed: ", 1, 1000, getCurrentSpeedValue("ultraSpeed", 10), 64, 10, function(newValue)
		setSpeedConstantAndReload("ultraSpeed", newValue)
	end)

	addSlider(timeSlot, "Slow Motion Speed:", 1, 20, getCurrentSpeedValue("slowMotionSpeed", 10), 0.1, 10, function(newValue)
		setSpeedConstantAndReload("slowMotionSpeed", newValue)
	end)

	return timeSlot
end

function tweaksUI:generateProgressionSlot(parentView)
	local progressionSlot = View.new(parentView)
	elementYOffset = elementYOffsetStart
	progressionSlot.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
	progressionSlot.size = backgroundSize

	addTitleHeader(progressionSlot, "Progression Tweaks")

	addSlider(progressionSlot, "Max Orders per Follower: ", 0, 100, getCurrentSpeedValue("allowedPlansPerFollower", 1), 5, 1, function(newValue)
		local constantName = "allowedPlansPerFollower"

		local paramTable = {
			tableName = "gameConstants",
			constantName = constantName,
			value = newValue
		}

		gameConstants[constantName] = newValue
		saveState:setValueClient("vt." .. constantName, newValue)
		logicInterface:callServerFunction("setConstantServer", paramTable)
		logicInterface:callServerFunction("refreshPlansServer")
	end)

	addSlider(progressionSlot, "Max Roles: ", 0, 50, saveState:getValueClient("vt.maxRoles", 6), 6, 1, function(newValue)
		local constantName = "maxRoles"

		local paramTable = {
			tableName = "gameConstants",
			constantName = constantName,
			value = newValue
		}

		skill.maxRoles = newValue
		logicInterface:callServerFunction("setConstantServer", paramTable)
		saveState:setValueClient("vt." .. constantName, newValue)
	end)

	-- --- TODO: This doesn't work yet :(

	-- local ratio = 0.1;
	-- local default = 400;
	-- local name = "timeToCompleteSkills"
	-- addSlider(progressionSlot, "Discovery Speed: ", 0, 200, getCurrentValue(name, ratio, default), default, ratio, function(newValue)
	-- 	local paramTable = {
	-- 		constantName = name,
	-- 		value = newValue
	-- 	}

	-- 	skill.maxRoles = newValue
	-- 	logicInterface:callServerFunction("setSkillConstantServer", paramTable)
	-- 	saveState:setValueClient("vt." .. name, newValue)
	-- end)

	return progressionSlot
end

function tweaksUI:generateSapienSlot(parentView)
	local sapienSlot = View.new(parentView)
	elementYOffset = elementYOffsetStart
	sapienSlot.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
	sapienSlot.size = backgroundSize

	addTitleHeader(sapienSlot, "Sapien Tweaks")

	addSlider(sapienSlot, "Max Orders per Follower: ", 0, 100, getCurrentSpeedValue("allowedPlansPerFollower", 1), 5, 1, function(newValue)
		local constantName = "allowedPlansPerFollower"

		local paramTable = {
			tableName = "gameConstants",
			constantName = constantName,
			value = newValue
		}

		gameConstants[constantName] = newValue
		saveState:setValueClient("vt." .. constantName, newValue)
		logicInterface:callServerFunction("setConstantServer", paramTable)
		logicInterface:callServerFunction("refreshPlansServer")
	end)

	return sapienSlot
end

function tweaksUI:init(manageUI)
	--- Called when the UI is ready to be generated
	--- @param manageUI UI The UI that is your parent.

	-- Main View
	tweaksUI.view = View.new(manageUI.view)
	tweaksUI.view.size = backgroundSize
	tweaksUI.view.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
	tweaksUI.view.hidden = true

	-- Background View
	local backgroundView = ModelView.new(tweaksUI.view)
	backgroundView:setModel(model:modelIndexForName("ui_bg_lg_16x9"))
	local scaleToUse = backgroundSize.x * 0.5
	backgroundView.scale3D = vec3(scaleToUse,scaleToUse,scaleToUse)
	backgroundView.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
	backgroundView.size = backgroundSize

	-- Button Inset
	local tabView = ModelView.new(tweaksUI.view)
	tabView:setModel(model:modelIndexForName("ui_inset_lg_2x3"))
	local sizeToUseX = 150
	local sizeTouseY = 250
	tabView.scale3D = vec3(sizeToUseX,sizeTouseY,sizeToUseX)
	tabView.size = vec2(sizeToUseX,sizeToUseX) * 2.0
	tabView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
	tabView.baseOffset = vec3(20, -100, -2)

	self:addSettingSlot(tabView, "Time", self:generateTimeSlot(self.view))
	self:addSettingSlot(tabView, "Progression", self:generateProgressionSlot(self.view))
	self:addSettingSlot(tabView, "Sapiens", self:generateSapienSlot(self.view))

	-- Make the first setting slot visible
	tweaksUI.settingSlots[1].hidden = false

	-- Close Button
	local closeButton = uiStandardButton:create(backgroundView, vec2(50,50), uiStandardButton.types.markerLike)
	closeButton.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionAbove)
	closeButton.baseOffset = vec3(30, -20, 0)
	uiStandardButton:setIconModel(closeButton, "icon_cross")
	uiStandardButton:setClickFunction(closeButton, function()
		tweaksUI.view.hidden = true
	end)
end

-- Called every frame
function tweaksUI:update(gameUI)
	-- Do nothing
end

return tweaksUI

