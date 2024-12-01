-- @description Allows it to display the full waveform of one or multiple selected items when pressing a (bindable) key.
-- @author Leon 'LAxemann' Beilmann
-- @version 1.14
-- @about
--   # About
--   SlipView allows it to display the full waveform of one or multiple selected items when pressing a (bindable) key.
--   This was meant with Slip Editing (using ALT to move the contents of an item without moving the item itself) in mind, 
--   Key features:
--   - Shows the full waveform of a selected media item when pressing a (bindable) key or key combination.
--   - The waveform preview will be created relative to the media item for quick orientation within the waveform.
--   - It can be set so that the preview will either stop at neighboring items or ignore them.
--   - If things get too cluttered, the preview can be created on an entirely new track.
--   - If the timeline or a neighboring item is in the way in either direction, it'll compensate towards the other direction.
--   - Supports multiple items VERTICALLY: The first selected item of each track will have its preview shown.
--   - Supports multiple takes on one item. The selected take will have its preview shown.
--   - An activation delay can be set; Only if the keys are pressed longer than the delay the waveform preview will show up.
--   - The previews will automatically update if the selected items or takes change.
--
--  # Requirements
--  JS_ReaScriptAPI, SWS Extension
--@links
--  Website https://www.youtube.com/@LAxemann
-- @provides 
--   [main] LAx_SlipView - Settings.lua
--   [main] LAx_SlipView - Toggle On New Track.lua
--   [main] LAx_SlipView - Toggle Restrict To Neighbors.lua
--   [nomain] ReadMe.txt
--   [nomain] Changelog.txt
--   [data] Toolbar_Icons/**/*.png
--@changelog
--	 1.14: - Tweaked: Now works properly even if "Trim content behind media items when editing" is enabled
--         - Toggle states should now update once the main routine starts
--         - Lowered cleanup interval from 2 to 1s
--	 1.13: - Added toolbar icons
--	 1.12: - Preview will stay if the mouse cursor leaves the arrange window
--	 1.11: - Added toggle state to main function
--	 1.10: - Preview will only be shown if the cursor is within the arrange view
--         - Preview will now carry over custom colors of items
--         - Removed unused function
--         - Fixed a small bug in settings
--         - Trivial tidying-up of code 
--   1.03: Updated ReadMe for release
--   1.02: Updated credits for release
--   1.01: Tweaked settings names
--   1.00: Initial version  


-- Get ExtState and Reaper settings
local primaryKey = tonumber(reaper.GetExtState("LAx_SlipView", "PrimaryKey")) or 18 -- Default: ALT (18)
local modifierKey = tonumber(reaper.GetExtState("LAx_SlipView", "ModifierKey")) -- Default: nil (no modifier)
local createGhostTrack = false
local delayTimeElapsed = 0
local lastTime = reaper.time_precise()
local selectionChangeTimer = 0
local originalTakePseudoHash = 0
local originalSelectionCount = 0

-- Variables to manage state
local key_was_pressed = false -- Tracks if key was previously pressed
local action_triggered = false -- Ensures actions run only once per cycle

local originalSelectedItems = {}
local firstTrackItems = {}
local processedTracks = {}
local ghostItems = {}
local ghostTracks = {}
local hasGhostTracks = false
local ghostItemName = "--SV--TEMP--"
local ghostTrackName = "--SV--TEMP--"

local lastCleanUp = reaper.time_precise()
local cleanUpInterval = 1


----------------------------------------------------------------------------------------
-- Check the state of the required keys
function is_key_down()
    local keyboardState = reaper.JS_VKeys_GetState(0) -- Get the keyboard state
	local primaryKeyDown = keyboardState:byte(primaryKey) & 1 ~= 0
	local modifierKeyDown = not modifierKey or (keyboardState:byte(modifierKey) & 1 ~= 0)
	
	local onlyOnDrag = (tonumber(reaper.GetExtState("LAx_SlipView", "ShowOnlyOnDrag")) or 0) ~= 0 -- Default: 0 
	local dragGate = not onlyOnDrag or isMouseClickOverSelectedItem()
	
    return ((primaryKeyDown and modifierKeyDown) and dragGate)
end


----------------------------------------------------------------------------------------
--[[ 
    isMouseInArrangeView: Check if mouse cursor is in arrange view. (Thanks to X-Raym!)
    Return1: True if cursor is in arrange view (bool)
--]]
function isMouseInArrangeView()
	local window = reaper.BR_GetMouseCursorContext()
	
	return (window == "arrange")
end


----------------------------------------------------------------------------------------
-- Action to perform when key is pressed
function on_key_press()
	gatherSelectedItemInfo()
	createMainItems()
end


----------------------------------------------------------------------------------------
--[[ 
    createGhostItem: Creates the ghostItem and sets its properties
    @arg1: item [Media item]
    @arg2: itemTrack [Track]
    @arg3: restrictToNeighbors [Bool]
    @arg4: createGhostTrack [Bool]
    Return1: ghostItem [Media item]
--]]
function createGhostItem(currentItem, itemTrack, restrictToNeighbors, createGhostTrack)
	if not currentItem then
		return nil
	end 
	
	local itemPos = reaper.GetMediaItemInfo_Value(currentItem, "D_POSITION")
	local ghostItemStartOffset, ghostItemTargetPos, ghostItemLength, ghostItemPlayRate = calculateGhostItemValues(currentItem, itemPos, itemTrack, restrictToNeighbors, createGhostTrack)

	 -- Create the ghost item and set values accordingly
	local ghostItem = reaper.AddMediaItemToTrack(itemTrack)
	reaper.SetMediaItemInfo_Value(ghostItem, "D_POSITION", ghostItemTargetPos)
	reaper.SetMediaItemInfo_Value(ghostItem, "D_LENGTH", ghostItemLength)
	reaper.SetMediaItemInfo_Value(ghostItem, "D_VOL", reaper.GetMediaItemInfo_Value(currentItem, "D_VOL"))
	reaper.SetMediaItemInfo_Value(ghostItem, "I_CUSTOMCOLOR", reaper.GetMediaItemInfo_Value(currentItem, "I_CUSTOMCOLOR"))
	reaper.SetMediaItemInfo_Value(ghostItem, "B_MUTE", 1)
	reaper.SetMediaItemInfo_Value(ghostItem, "B_LOOPSRC", 1)

	-- Apply the original take
	local take = reaper.GetActiveTake(currentItem)
	local takeNumber = (createGhostTrack and 0) or reaper.GetMediaItemTakeInfo_Value(take, "IP_TAKENUMBER")
	local takeCount = (createGhostTrack and 1) or reaper.GetMediaItemNumTakes(currentItem)
	local ghostTake
	
	for i = 0, takeCount - 1 do
		if (i == takeNumber) then
			ghostTake = reaper.AddTakeToMediaItem(ghostItem)
			reaper.SetActiveTake(ghostTake)
		else
			reaper.AddTakeToMediaItem(ghostItem)
		end
	end
	
	if ghostTake then
		reaper.SetMediaItemTake_Source(ghostTake, reaper.GetMediaItemTake_Source(take))
		reaper.SetMediaItemTakeInfo_Value(ghostTake, "D_STARTOFFS", ghostItemStartOffset)
		reaper.SetMediaItemTakeInfo_Value(ghostTake, "D_PLAYRATE", ghostItemPlayRate)
		reaper.SetMediaItemTakeInfo_Value(ghostTake, "D_VOL", reaper.GetMediaItemTakeInfo_Value(take, "D_VOL"))
		reaper.SetMediaItemTakeInfo_Value(ghostTake, "I_CHANMODE", reaper.GetMediaItemTakeInfo_Value(take, "I_CHANMODE"))
		reaper.SetMediaItemTakeInfo_Value(ghostTake, "I_CUSTOMCOLOR", reaper.GetMediaItemTakeInfo_Value(take, "I_CUSTOMCOLOR"))
		reaper.GetSetMediaItemTakeInfo_String(ghostTake, "P_NAME", ghostItemName, true)
	end
	
	originalTakePseudoHash = originalTakePseudoHash + takeNumber
	
	return ghostItem
end


----------------------------------------------------------------------------------------
--[[ 
    calculateGhostItemValues: Calculates offset, position and length of the GhostItem.
    @arg1: selectedItem [Media Item]
    @arg2: itemPos [Float]
    @arg3: itemTrack [Track]
    @arg4: restrictToNeighbors [Bool]
    @arg5: createGhostTrack [Bool]
    Return1: ghostItemStartOffset [Float]
    Return2: ghostItemTargetPos [Float]
    Return3: itemTakeSourceLength [Float]
    Return4: playRate [Float]
--]]
function calculateGhostItemValues(selectedItem, itemPos, itemTrack, restrictToNeighbors, createGhostTrack)
	local take = reaper.GetActiveTake(selectedItem)
	local takeOffset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS") -- Basically how much the item would need to shift left
	local playRate = reaper.GetMediaItemTakeInfo_Value(take,"D_PLAYRATE")
	local playRateFactor = (1/playRate)
	local takeOffsetCompensated = takeOffset * playRateFactor
	local itemTakeSource = reaper.GetMediaItemTake_Source(take)
	local itemTakeSourceLength = reaper.GetMediaSourceLength(itemTakeSource) * playRateFactor

	-- Get neighbor item positions. We do it before inserting the ghost item to avoid having to deal with changed indices
	local rightNeighborStartPos = 0
	local leftNeighborEndPos = 0
	
	if (restrictToNeighbors and (not createGhostTrack)) then
		local selectedItemIndex = reaper.GetMediaItemInfo_Value(selectedItem, "IP_ITEMNUMBER")
		local rightNeighborItem = getNonClippingRightNeighbor(selectedItemIndex, itemTrack, reaper.GetMediaItemInfo_Value(selectedItem, "D_POSITION") + reaper.GetMediaItemInfo_Value(selectedItem, "D_LENGTH"))
		
		if rightNeighborItem then
			rightNeighborStartPos = reaper.GetMediaItemInfo_Value(rightNeighborItem, "D_POSITION")
		end
		
		local leftNeighborItem = reaper.GetTrackMediaItem(itemTrack, selectedItemIndex - 1)
		
		if leftNeighborItem then
			local leftNeighborStartPos = reaper.GetMediaItemInfo_Value(leftNeighborItem, "D_POSITION")
			local leftNeighborLength = reaper.GetMediaItemInfo_Value(leftNeighborItem, "D_LENGTH")
			leftNeighborEndPos = leftNeighborStartPos + leftNeighborLength
		end
	end

	-- Calculate start offset if GhostItem collides with a left neighbor.
	-- If no neighbor, the timeline start (0) is considered our neighbor.
	local ghostItemStartOffset = 0
	local ghostItemTargetPos = leftNeighborEndPos -- Set GhostItem position to end of left neighbor/timeline start by default
	
	local spaceToLeft = itemPos - leftNeighborEndPos
	local isClippingLeft = takeOffsetCompensated > spaceToLeft -- Would offsetting the GhostItem clip into an item/the timeline start to the left?
	
	if isClippingLeft then
		ghostItemStartOffset = (takeOffsetCompensated - spaceToLeft) / playRateFactor
	else
		ghostItemTargetPos = itemPos - takeOffsetCompensated -- Allow full expansion if not clipping by shifting to full offSet length
	end
	
	-- Check if GhostItem clips into the right neighbor. If so, look for available space to the left to fill
	if ((restrictToNeighbors) and (rightNeighborStartPos > 0) and (not createGhostTrack)) then
		local distToRightItem = rightNeighborStartPos - ghostItemTargetPos

		if (itemTakeSourceLength > distToRightItem) then
			local clipRightDistance = itemTakeSourceLength - distToRightItem
			
			if (not isClippingLeft) then
				local maxPossibleAdjustment = math.min(ghostItemTargetPos - leftNeighborEndPos,clipRightDistance)
				ghostItemTargetPos = ghostItemTargetPos - maxPossibleAdjustment
				ghostItemStartOffset = (ghostItemStartOffset - maxPossibleAdjustment) / playRateFactor
				distToRightItem = rightNeighborStartPos - ghostItemTargetPos
			end
			
			itemTakeSourceLength = distToRightItem
		end
	end
	
	-- Return
	return ghostItemStartOffset, ghostItemTargetPos, itemTakeSourceLength, playRate
end


----------------------------------------------------------------------------------------
-- Gathers the data about selected items
function gatherSelectedItemInfo()
	-- Update delay time
	delay = tonumber(reaper.GetExtState("LAx_SlipView", "Delay")) or 0 -- Default: 0
	
	-- Reset variables
	firstTrackItems = {}
	originalSelectionCount = 0
	originalTakePseudoHash = 0
	local processedTracks = {}
	originalSelectedItems = {}
	local selectedItemsCount = reaper.CountSelectedMediaItems(0)
	
	-- Exit if no items are selected
	if selectedItemsCount == 0 then
		return
	end
	
	-- Loop through all selected items, fill arrays/tables, make sure only the first per track
	for i = 0, selectedItemsCount - 1 do
		local item = reaper.GetSelectedMediaItem(0, i)
		local track = reaper.GetMediaItemTrack(item)
		
		if not processedTracks[track] then
			table.insert(firstTrackItems, item)
			processedTracks[track] = true
		end
		
		table.insert(originalSelectedItems, item)
		originalSelectionCount = originalSelectionCount + 1
	end
end


----------------------------------------------------------------------------------------
-- Creates the Ghost Items and Ghost Tracks based on the gathered data
function createMainItems()
	-- Check if auto-crossfade and overlap trimming is enabled, disable temporarily if so
	local isAutoCrossfadeEnabled = reaper.GetToggleCommandState(40041)
	local isOverlapTrimmingEnabled = reaper.GetToggleCommandState(41117)
	
	if isAutoCrossfadeEnabled == 1 then
		reaper.Main_OnCommand(41119, 0)
	end
	
	if isOverlapTrimmingEnabled == 1 then
		reaper.Main_OnCommand(41121, 0)
	end
	
	-- Check for settings
	local createGhostTrack = (tonumber(reaper.GetExtState("LAx_SlipView", "createGhostTrack")) or 0) ~= 0 -- Default: 0 
	local restrictToNeighbors = (tonumber(reaper.GetExtState("LAx_SlipView", "RestrictToNeighbors")) or 0) ~= 0 -- Default: 0 

	-- Loop through selected items, do the main magic
	for i, item in ipairs(firstTrackItems) do	
		local currentItem = item 
		
		if not currentItem then
			return
		end

		local itemTrack = reaper.GetMediaItemTrack(currentItem)
		
		-- Create the Ghost Items, Also create a Ghost Track if specified in the settings
		if createGhostTrack then
			local itemTrackHeight = reaper.GetMediaTrackInfo_Value(itemTrack, "I_TCPH")
			local itemTrackColor = reaper.GetMediaTrackInfo_Value(itemTrack, "I_CUSTOMCOLOR")
			local itemTrackIndex = reaper.GetMediaTrackInfo_Value(itemTrack, "IP_TRACKNUMBER")
			reaper.InsertTrackAtIndex(itemTrackIndex, true) -- Insert a new track below the original track
			ghostTrack = reaper.GetTrack(0, itemTrackIndex) -- Get the newly created track
			reaper.GetSetMediaTrackInfo_String(ghostTrack, "P_NAME", ghostTrackName, true)
			reaper.SetMediaTrackInfo_Value(ghostTrack, "I_HEIGHTOVERRIDE", itemTrackHeight)
			reaper.SetMediaTrackInfo_Value(ghostTrack, "I_CUSTOMCOLOR", itemTrackColor)
			table.insert(ghostTracks,ghostTrack)
			
			local ghostItem = createGhostItem(currentItem, ghostTrack, restrictToNeighbors, createGhostTrack)
			table.insert(ghostItems, ghostItem)
			
			hasGhostTracks = true
		else
			local ghostItem = createGhostItem(currentItem, itemTrack, restrictToNeighbors, createGhostTrack)
			table.insert(ghostItems, ghostItem)
		end

		-- Re-enable crossfade and trimming if applicable
		if isAutoCrossfadeEnabled == 1 then
			reaper.Main_OnCommand(41118, 0)
		end
		
		if isOverlapTrimmingEnabled == 1 then
			reaper.Main_OnCommand(41120, 0)
		end
	end
	
	-- Restore selection of originally selected items and select all created Ghost Items
	for i, item in ipairs(originalSelectedItems) do
		reaper.SetMediaItemSelected(item, true)
	end
	
	for i, item in ipairs(ghostItems) do
		reaper.SetMediaItemSelected(item, true)
	end

	-- Update tracklist and arrange window
	reaper.TrackList_AdjustWindows(false)
	reaper.UpdateArrange()
end


----------------------------------------------------------------------------------------
-- Check if the mouse is clicked and a selected item is under the cursor
function getNonClippingRightNeighbor(indexStart, track, itemEndPos)
	local nonClippingRightNeighbor = nil
	
	local itemsOnTrackCount = reaper.CountTrackMediaItems(track)

	for i = indexStart + 1, itemsOnTrackCount - 1 do
		local currentItem = reaper.GetTrackMediaItem(track, i)
		local currentItemEnd = reaper.GetMediaItemInfo_Value(currentItem, "D_POSITION") + reaper.GetMediaItemInfo_Value(currentItem, "D_LENGTH")

		-- Check if the current item's start position is greater than the reference item's end position
		if currentItemEnd > itemEndPos then
			nonClippingRightNeighbor = currentItem
			break
		end
	end
	
	return nonClippingRightNeighbor
end


----------------------------------------------------------------------------------------
-- Check if the mouse is clicked and a selected item is under the cursor
function isMouseClickOverSelectedItem()
	-- Check if mouse is clicked, return if not
	local isMouseClicked = reaper.JS_Mouse_GetState(1) == 1
	
	if not isMouseClicked then
		return false
	end
	
	-- If the items are already created, we don't care about what's under the cursor anymore
	if (action_triggered) then
		return true
	end
	
	-- Check if an item is under cursor, exit if not
	reaper.BR_GetMouseCursorContext()
	local itemUnderCursor = reaper.BR_GetMouseCursorContext_Item()
	
	if not itemUnderCursor then
		return nil
	end
	
	-- Check if items are selected, exit if not
	local selectedItemsCount = reaper.CountSelectedMediaItems(0)
	
	if selectedItemsCount == 0 then
		return false
	end
	
	-- Loop through all selected items, fill arrays/tables, make sure only the first per track
	local isSelectedItemUnderCursor = false
	
	for i = 0, selectedItemsCount - 1 do
		if reaper.GetSelectedMediaItem(0, i) == itemUnderCursor then
			isSelectedItemUnderCursor = true
			break 
		end
	end

	return isMouseClicked and isSelectedItemUnderCursor
end


----------------------------------------------------------------------------------------
-- Upon releasing key
function on_key_release()
	-- Count created ghostItems and exit if none are stored
	local itemCount = #ghostItems
	
	if (itemCount == 0) then
		return
	end
	
	-- Go through ghost items and delete them
	for i, ghostItem in ipairs(ghostItems) do
		if reaper.ValidatePtr(ghostItem, 'MediaItem*') then
			local ghostItemTrack = reaper.GetMediaItemTrack(ghostItem)
			reaper.DeleteTrackMediaItem(ghostItemTrack, ghostItem)
		end
		
		if (hasGhostTracks) then
			local ghostTrack = ghostTracks[i]
			if reaper.ValidatePtr(ghostTrack, 'MediaTrack*') then
				reaper.DeleteTrack(ghostTrack)
			end
		end
	end
	
	-- Clear arrays, update arrangement view and playlist
	ghostItems = {}
	ghostTracks = {}
	hasGhostTracks = false
	
	lastTime = reaper.time_precise()
	delayTimeElapsed = 0
	
	reaper.TrackList_AdjustWindows(false)
	reaper.UpdateArrange()
end


----------------------------------------------------------------------------------------
--[[ 
    cleanUp: Goes through all items + tracks and deletes temp ones
	(Yes, some redundant code in here... call the cops! :D)
--]]
function cleanUp()
	-- Don't delete stuff if Ghost Previews are currently shown
	if action_triggered then
		return
	end
	
	-- Return if it's not yet time for the next cleanup
	if (reaper.time_precise() - lastCleanUp) < cleanUpInterval then
		return
	end
	
	--local startTime = reaper.time_precise()
	
	lastCleanUp = reaper.time_precise()
	
	-- Loop through each media item, delete if it matches the GhostItem name
	local numItems = reaper.CountMediaItems(0)
	local hasDeleted = false

	for i = 0, numItems - 1 do
		local mediaItem = reaper.GetMediaItem(0, i)
		
		if mediaItem then
			local take = reaper.GetTake(mediaItem, 0)
			
			if take then
				local takeName = reaper.GetTakeName(take)
				
				if (takeName == ghostItemName) then
					reaper.DeleteTrackMediaItem(reaper.GetMediaItemTrack(mediaItem), mediaItem)
					hasDeleted = true
				end
			end
		end
	end
	
	if (hasDeleted) then
		reaper.UpdateArrange()
	end
	
	-- Loop through each track, delete if it matches the GhostTrack name
	local numTracks = reaper.CountTracks(0)
	hasDeleted = false
	
	for i = 0, numTracks - 1 do
		local track = reaper.GetTrack(0, i)
		
		if track then
			local _, trackName = reaper.GetTrackName(track)
			
			if (trackName == ghostTrackName) then
				reaper.DeleteTrack(track)
				hasDeleted = true
			end
		end
	end
	
	if hasDeleted then
		reaper.TrackList_AdjustWindows(false)
	end
	
	--local elapsedTime = reaper.time_precise() - startTime
	--reaper.ShowConsoleMsg("Items:" .. tostring(numItems) .."\n" .. tostring(elapsedTime))
end


----------------------------------------------------------------------------------------
--[[ 
    hasSelectionChanged: Checks whether or not the selected items have changed (by comparing their numbers)
    Return1: bool
--]]
function hasSelectionChanged()
	selectionChangeTimer = reaper.time_precise() - selectionChangeTimer
	
	if selectionChangeTimer < 0.1 then
		return false
	end
	
	selectionChangeTimer = 0
	
	local currentTakePseudoHash = 0
	
	for i, item in ipairs(firstTrackItems) do	
		if reaper.ValidatePtr(item, 'MediaItem*') then
			local take = reaper.GetActiveTake(item)
			local takeNumber = (createGhostTrack and 0) or reaper.GetMediaItemTakeInfo_Value(take, "IP_TAKENUMBER")
			currentTakePseudoHash = currentTakePseudoHash + takeNumber
		end
	end
	
	local totalSelectionCount = originalSelectionCount + #ghostItems
	return ((reaper.CountSelectedMediaItems(0) ~= totalSelectionCount) or (currentTakePseudoHash ~= originalTakePseudoHash))
end


----------------------------------------------------------------------------------------
--[[ 
    checkStoredValue: Checks a stored ExtState value and returns it, returns a default value if original return was nil
    @arg1: valueID [String]
    @arg2: default [Any]
    Returns: stored value or nil
--]]
function checkStoredValue(valueID, defaultValue)
	local returnValue = tonumber(reaper.GetExtState("LAx_SlipView", valueID))
	
	if returnValue == nil then
		returnValue = defaultValue
	end
	
	return returnValue
end


----------------------------------------------------------------------------------------
-- Sets toggle state of toggle actions if they've been registered
function setToggleFunctionsToggleState()
	local createGhostTrack = (tonumber(reaper.GetExtState("LAx_SlipView", "createGhostTrack")) or 0) -- Default: 0 
	local restrictToNeighbors = (tonumber(reaper.GetExtState("LAx_SlipView", "RestrictToNeighbors")) or 0) -- Default: 0 
	
	local restrictToNeighborsToggleCmdID = checkStoredValue("RestrictToNeighborsToggleCmdID", "")
	local createGhostTrackToggleCmdID = checkStoredValue("CreateGhostTrackToggleCmdID", "")
	
	local commandID = -1
	
	if createGhostTrackToggleCmdID ~= "" then
		commandID = reaper.NamedCommandLookup(createGhostTrackToggleCmdID)
		reaper.SetToggleCommandState(0, commandID, createGhostTrack)
	end
	
	if restrictToNeighborsToggleCmdID ~= "" then
		commandID = reaper.NamedCommandLookup(restrictToNeighborsToggleCmdID)
		reaper.SetToggleCommandState(0, commandID, restrictToNeighbors)
	end
end


----------------------------------------------------------------------------------------
-- Sets a toggle state
function setToggleState(state)
  local _, _, sectionID, cmdID = reaper.get_action_context()
  reaper.SetToggleCommandState(sectionID, cmdID, state or 0)
  reaper.RefreshToolbar2(sectionID, cmdID)
end


----------------------------------------------------------------------------------------
-- Main loop
function main()
	-- If the action is alrady running but the selection has changed, "refresh"
	if action_triggered and hasSelectionChanged() then
		on_key_release()
		key_was_pressed = false
		action_triggered = false
		
		on_key_press()
		key_was_pressed = true
		action_triggered = true
	else
		-- Otherwise proceed as usual and check for keyboard inputs
		local key_down = is_key_down() -- Check if key input matches critearia

		if key_down and not key_was_pressed then
			-- Check if delay is set and if so, track elapsed time
			local delay = tonumber(reaper.GetExtState("LAx_SlipView", "Delay")) or 0 -- Default: 0
			
			-- If a delay is set, activate the timer before the action is shown
			if (delay > 0) then
				if delayTimeElapsed == 0 then
					lastTime = reaper.time_precise()
				end
				
				delayTimeElapsed = reaper.time_precise() - lastTime
			end
			
			-- Allow execution of the main function if delay time has passed
			if delayTimeElapsed >= delay and isMouseInArrangeView() then
				-- Key is pressed, and it wasn't pressed before
				on_key_press()
				key_was_pressed = true
				action_triggered = true
			end
		elseif not key_down and key_was_pressed then
			-- Key is released, and it was previously pressed
			on_key_release()
			key_was_pressed = false
			action_triggered = false
		end
		cleanUp()
	end

    -- Continuously run the script
    reaper.defer(main)
end


----------------------------------------------------------------------------------------
-- Initialization
-- Check for ReaScript API
if not reaper.JS_VKeys_GetState then
    reaper.ShowMessageBox("This script requires the JS ReaScript API extension. Please install it.", "Error", 0)
    return
end

-- Check for SWS
local swsInstalled = reaper.SNM_GetIntConfigVar("swsversion", -1)
if sws_installed == -1 then
    reaper.ShowMessageBox("The SWS extension is not installed.\nPlease install SWS.", "Error", 0)
	return
end

-- Run main routine
setToggleFunctionsToggleState()
setToggleState(1)
main()
reaper.atexit(setToggleState)