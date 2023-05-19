--- VanillaTweaks: tweaksUI.lua 
--- GameView which will be used to display the tweak UI.
--- @author SirLich

local tweaksUI = {
	name = "Vanilla Tweaks",
	view = nil,
	parent = nil,
	icon = "icon_edit",

	-- Constants
	skill = nil,
	gameConstants = nil,
	sapienConstants = nil,

	-- The setting slots (renderd conditionally based on the current selection)
	settingSlots = {},

	-- Local State
	world = nil
}

function tweaksUI:setWorld(world)
	tweaksUI.world = world
end

--- Import Setup
local gameConstants = mjrequire "common/gameConstants"
local skill = mjrequire "common/skill"
local sapienConstants = mjrequire "common/sapienConstants"

tweaksUI.skill = skill
tweaksUI.gameConstants = gameConstants
tweaksUI.sapienConstants = sapienConstants

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

local function addToggleButton(parentView, toggleButtonTitle, settingName, changedFunction)
	local settingName = "vt." .. settingName
	local initialValue = saveState:getValue(settingName, {default = false})

	local toggleButton = uiStandardButton:create(parentView, vec2(26,26), uiStandardButton.types.toggle)
	toggleButton.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
	toggleButton.baseOffset = vec3(elementControlX, elementYOffset, 0)
	uiStandardButton:setToggleState(toggleButton, initialValue)
	
	local textView = TextView.new(parentView)
	textView.font = Font(uiCommon.fontName, 16)
	textView.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionTop)
	textView.baseOffset = vec3(elementTitleX,elementYOffset - 4, 0)
	textView.text = toggleButtonTitle

	uiStandardButton:setClickFunction(toggleButton, function()
		changedFunction(uiStandardButton:getToggleState(toggleButton))
	end)

	-- Adjust the changed function to also include the slider value view
	local super_changedFunction = changedFunction
	changedFunction = function(newValue)
		super_changedFunction(newValue)
		saveState:setValue(settingName, newValue)
	end

	-- TODO: Come up with a better solution than this
	local MEANINGLESS_DELAY = 5
	timer:addCallbackTimer(MEANINGLESS_DELAY, function()
		-- Initial trigger to set the time values and text
		-- done after a delay to let other systems catch up
		changedFunction(initialValue)
	end)

	elementYOffset = elementYOffset - yOffsetBetweenElements
	
	return toggleButton
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
	local resetButton = nil
	
	-- Adjust the changed function to also include the slider value view
	local super_changedFunction = changedFunction
	changedFunction = function(newValue)
		local floatValue = newValue / floatDivisor
		if floatValue == defaultValue then
			resetButton.hidden = true
		else
			resetButton.hidden = false
		end

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
	resetButton = uiStandardButton:create(parentView, resetButtonSize)
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
	local current = saveState:getValue("vt." .. speedKey)
	if current == nil then
		current = gameConstants[speedKey] * ratio
	else
		current = current * ratio
	end

	return current
end

local function setConstantFromTable(paramTable)
	--- This function sets a game constant on both the client thread
	--- and the server thread.

	-- Client
	tweaksUI[paramTable.tableName][paramTable.constantName] = paramTable.value

	-- Server
	logicInterface:callServerFunction("setConstantServer", paramTable)
end

local function setSpeedConstantAndReload(constantName, newValue)
	local paramTable = {
		tableName = "gameConstants",
		constantName = constantName,
		value = newValue
	}

	gameConstants[constantName] = newValue
	saveState:setValue("vt." .. constantName, newValue)

	logicInterface:callServerFunction("setConstantServer", paramTable)

	-- Representing current speed value
	local speedMultiplierIndex = tweaksUI.world:getSpeedMultiplierIndex()

	-- Annoying logic, but we need to switch speeds to trigger a rebuild
	-- of the time. This just ensures we always end up where we started.
	if speedMultiplierIndex == 0 then
		logicInterface:callServerFunction("setPaused", true)
	elseif speedMultiplierIndex == 1 then
		logicInterface:callServerFunction("setPaused", false)
		logicInterface:callServerFunction("setFastForward", false)
		logicInterface:callServerFunction("setSlowMotion", false)
	elseif speedMultiplierIndex == 2 then
		logicInterface:callServerFunction("setFastForward", true)

	end
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

	addSlider(timeSlot, "Ultra Speed: ", 1, 2000, getCurrentSpeedValue("ultraSpeed", 10), 64, 10, function(newValue)
		setSpeedConstantAndReload("ultraSpeed", newValue)
	end)

	addSlider(timeSlot, "Slow Motion Speed:", 1, 20, getCurrentSpeedValue("slowMotionSpeed", 10), 0.1, 10, function(newValue)
		setSpeedConstantAndReload("slowMotionSpeed", newValue)
	end)

	return timeSlot
end

function tweaksUI:generateMovementSlot(parentView)
	local movementSlot = View.new(parentView)
	elementYOffset = elementYOffsetStart
	movementSlot.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
	movementSlot.size = backgroundSize
	
	addTitleHeader(movementSlot, "Movement Tweaks")


	-- parentView, toggleButtonTitle, toggleValue, changedFunction
	addToggleButton(movementSlot, "Unlock Player Height", "unlockPlayerHeight", function(newValue)
		local localPlayer = mjrequire "mainThread/localPlayer"

		if newValue then
			localPlayer:setMaxPlayerHeight(mj:mToP(10000000.0))
			localPlayer:setSpeedIncreaseFactorAtMaxHeight(400000.0)
		else
			localPlayer:setMaxPlayerHeight(mj:mToP(30.0))
			localPlayer:setSpeedIncreaseFactorAtMaxHeight(500000.0)
		end
	end)

	addToggleButton(movementSlot, "Remove Movement Bounds", "removeMovementBounds", function(newValue)
		local localPlayer = mjrequire "mainThread/localPlayer"

		if newValue then
			localPlayer:setMaxDistanceFromClosestSapien(mj:mToP(1000.0))
		else
			localPlayer:setMaxDistanceFromClosestSapien(mj:mToP(1000000.0))
		end
	end)

	return movementSlot
end

function tweaksUI:generateInformationSlot(parentView)
	local infoSlot = View.new(parentView)
	elementYOffset = elementYOffsetStart
	infoSlot.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
	infoSlot.size = backgroundSize

	local textView = TextView.new(infoSlot)
	textView.font = Font(uiCommon.fontName, 16)
	textView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
	textView.baseOffset = vec3( 450,elementYOffset - 4, 0)
	textView.text = "Welcome to Vanilla Tweaks!\n\nThis mod is designed as a replacement for one-off tweak mods,\nwhich adjust something to a static value.\n\nEvery setting here can be set, in-game, to your choice.\n\nI will be adding more settings soon. Topics include:\n - Birthrate\n - Sapien Age\n - Animal Spawns"

	return infoSlot
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
		saveState:setValue("vt." .. constantName, newValue)
		logicInterface:callServerFunction("setConstantServer", paramTable)
		logicInterface:callServerFunction("refreshPlansServer")
	end)

	addSlider(progressionSlot, "Max Roles: ", 0, 50, saveState:getValue("vt.maxRoles", {default = 6}), 6, 1, function(newValue)
		local constantName = "maxRoles"

		local paramTable = {
			tableName = "gameConstants",
			constantName = constantName,
			value = newValue
		}

		skill.maxRoles = newValue
		logicInterface:callServerFunction("setConstantServer", paramTable)
		saveState:setValue("vt." .. constantName, newValue)
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

	local dayLength = 2880.0
	local yearLength = 46080.0

	-- local function addSlider(parentView, sliderTitle, min, max, currentValue, defaultValue, floatDivisor, changedFunction)
	local ratio = 10
	local default = 1
	addSlider(sapienSlot, "Walk Speed Multiplier: ", 0, 100, saveState:getValue("vt.walkSpeedMultiplier", {default = default}) * ratio, default, ratio, function(newValue)
		saveState:setValue("vt.walkSpeedMultiplier", newValue)
	end)

	-- local function addSlider(parentView, sliderTitle, min, max, currentValue, defaultValue, floatDivisor, changedFunction)
	local ratio = 10
	addSlider(sapienSlot, "Hunger Multiplier: ", 0, 50, saveState:getValue("vt.hungerMultiplier", {default = 1}) * ratio, 1, ratio, function(newValue)
		setConstantFromTable({
			tableName = "sapienConstants",
			constantName = "hungerIncrementMultiplier",
			value = newValue
		})
		saveState:setValue("vt.hungerMultiplier", newValue)
	end)

	local ratio = 10
	addSlider(sapienSlot, "Music Need Multiplier: ", 0, 50, saveState:getValue("vt.needMusicMultiplier", {default = 1}) * ratio, 1, ratio, function(newValue)
		setConstantFromTable({
			tableName = "sapienConstants",
			constantName = "musicNeedIncrementMultiplier",
			value = newValue
		})
		saveState:setValue("vt.needMusicMultiplier", newValue)
	end)

	local ratio = 0.01
	local default = dayLength
	addSlider(sapienSlot, "Injury Duration: ", 0, 100, saveState:getValue("vt.injuryDuration", {default = default}) * ratio, default, ratio, function(newValue)
		setConstantFromTable({
			tableName = "sapienConstants",
			constantName = "injuryDuration",
			value = newValue
		})
		saveState:setValue("vt.injuryDuration", newValue)
	end)

	local ratio = 0.01
	local default = dayLength
	addSlider(sapienSlot, "Burn Duration: ", 0, 100, saveState:getValue("vt.burnDuration", {default = default}) * ratio, default, ratio, function(newValue)
		setConstantFromTable({
			tableName = "sapienConstants",
			constantName = "burnDuration",
			value = newValue
		})
		saveState:setValue("vt.burnDuration", newValue)
	end)

	local ratio = 10
	local default = 0.4
	addSlider(sapienSlot, "Virus from Nomad Chance", 0, 100, saveState:getValue("vt.virusInNomadTribeChance", {default = default}) * ratio, default, ratio, function(newValue)
		setConstantFromTable({
			tableName = "sapienConstants",
			constantName = "virusInNomadTribeChance",
			value = newValue
		})
		saveState:setValue("vt.virusInNomadTribeChance", newValue)
	end)
	
	local ratio = 1
	local default = 15
	addSlider(sapienSlot, "Min Pop for Virus", 0, 100, saveState:getValue("vt.minPopulationForVirusIntroduction", {default = default}) * ratio, default, ratio, function(newValue)
		setConstantFromTable({
			tableName = "sapienConstants",
			constantName = "minPopulationForVirusIntroduction",
			value = newValue
		})
		saveState:setValue("vt.minPopulationForVirusIntroduction", newValue)
	end)


	local ratio = 0.01
	local default = dayLength
	addSlider(sapienSlot, "Food Poison Duration: ", 0, 100, saveState:getValue("vt.foodPoisoningDuration", {default = default}) * ratio, default, ratio, function(newValue)
		setConstantFromTable({
			tableName = "sapienConstants",
			constantName = "foodPoisoningDuration",
			value = newValue
		})
		saveState:setValue("vt.foodPoisoningDuration", newValue)
	end)

	local ratio = 0.1
	local default = dayLength * 2
	addSlider(sapienSlot, "Virus Duration: ", 0, 100, saveState:getValue("vt.virusDuration", {default = default}) * ratio, default, ratio, function(newValue)
		setConstantFromTable({
			tableName = "sapienConstants",
			constantName = "virusDuration",
			value = newValue
		})
		saveState:setValue("vt.virusDuration", newValue)
	end)

	local ratio = 1
	local default = 10
	addSlider(sapienSlot, "Time to become Wet: ", 0, 100, saveState:getValue("vt.wetDuration", {default = default}) * ratio, default, ratio, function(newValue)
		setConstantFromTable({
			tableName = "sapienConstants",
			constantName = "wetDuration",
			value = newValue
		})
		saveState:setValue("vt.wetDuration", newValue)
	end)

	local ratio = 1
	local default = 30
	addSlider(sapienSlot, "Time to become Dry: ", 0, 100, saveState:getValue("vt.dryDuration", {default = default}) * ratio, default, ratio, function(newValue)
		setConstantFromTable({
			tableName = "sapienConstants",
			constantName = "dryDuration",
			value = newValue
		})
		saveState:setValue("vt.dryDuration", newValue)
	end)

	return sapienSlot
end

function tweaksUI:generatePopulationSlot(parentView)
	local populationSlot = View.new(parentView)
	elementYOffset = elementYOffsetStart
	populationSlot.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
	populationSlot.size = backgroundSize

	addTitleHeader(populationSlot, "Population Tweaks")

	-- local function addSlider(parentView, sliderTitle, min, max, currentValue, defaultValue, floatDivisor, changedFunction)
	local ratio = 10
	local default = 1
	addSlider(populationSlot, "Pregnancy Duration: ", 0, 50, saveState:getValue("vt.pregnancyDurationDays", {default = default}) * ratio, default, ratio, function(newValue)
		setConstantFromTable({
			tableName = "sapienConstants",
			constantName = "pregnancyDurationDays",
			value = newValue
		})
		saveState:setValue("vt.pregnancyDurationDays", newValue)
	end)

	-- local function addSlider(parentView, sliderTitle, min, max, currentValue, defaultValue, floatDivisor, changedFunction)
	local ratio = 10
	local default = 1
	addSlider(populationSlot, "Infant Duration: ", 0, 50, saveState:getValue("vt.infantDurationDays", {default = default}) * ratio, default, ratio, function(newValue)
		setConstantFromTable({
			tableName = "sapienConstants",
			constantName = "infantDurationDays",
			value = newValue
		})
		saveState:setValue("vt.infantDurationDays", newValue)
	end)

	-- local function addSlider(parentView, sliderTitle, min, max, currentValue, defaultValue, floatDivisor, changedFunction)
	local ratio = 10
	local default = 3
	addSlider(populationSlot, "Time between Pregnancies: ", 0, 100, saveState:getValue("vt.minTimeBetweenPregnancyDays", {default = default}) * ratio, default, ratio, function(newValue)
		setConstantFromTable({
			tableName = "sapienConstants",
			constantName = "minTimeBetweenPregnancyDays",
			value = newValue
		})
		saveState:setValue("vt.minTimeBetweenPregnancyDays", newValue)
	end)

	return populationSlot
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

	self:addSettingSlot(tabView, "Mod Information", self:generateInformationSlot(self.view))
	currentButtonSlotOffset =  currentButtonSlotOffset + (buttonSlotOffset / 2) -- Provide some padding

	self:addSettingSlot(tabView, "Time", self:generateTimeSlot(self.view))
	self:addSettingSlot(tabView, "Progression", self:generateProgressionSlot(self.view))
	self:addSettingSlot(tabView, "Movement", self:generateMovementSlot(self.view))
	self:addSettingSlot(tabView, "Sapiens", self:generateSapienSlot(self.view))
	self:addSettingSlot(tabView, "Population", self:generatePopulationSlot(self.view))

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

