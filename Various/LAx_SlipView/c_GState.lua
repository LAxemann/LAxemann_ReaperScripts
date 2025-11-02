-- @noindex
----------------------------------------------------------------------------------------
-- Requirements
local extState = require("LAx_Shared_ExtState")
local tables = require("LAx_Shared_Tables")
local utility = require("LAx_Shared_Utility")

----------------------------------------------------------------------------------------
-- Declaration + Constructor
GState = {}
GState.__index = GState

function GState.new()
    local instance = setmetatable({}, GState)
    return instance
end

function GState:init(ghostItems, ghostTracks)
    -- Objects
    self.ghostItems = ghostItems
    self.ghostTracks = ghostTracks

    -- Settings & keybinds
    self.settings = {}
    self.settings.primaryKey = extState.getExtStateValue(LAx_ProductData.name, "PrimaryKey", 18)                    -- Default: ALT (18)
    self.settings.modifierKey = extState.getExtStateValue(LAx_ProductData.name, "ModifierKey", nil)                 -- Default: nil (no modifier)
    self.settings.createGhostTrack = extState.getExtStateValueBool(LAx_ProductData.name, "CreateGhostTrack", false) -- Default: 0
    self.settings.snapToTransients = extState.getExtStateValueBool(LAx_ProductData.name, "SnapToTransients", false)
    self.settings.showTransientGuides = extState.getExtStateValueBool(LAx_ProductData.name, "ShowTransientGuides", false)
    self.settings.dontDisableAutoCF = extState.getExtStateValueBool(LAx_ProductData.name, "DontDisableAutoCF", false)
    self.settings.restrictToNeighbors = extState.getExtStateValueBool(LAx_ProductData.name, "RestrictToNeighbors", true)
    self.settings.showTakeMarkers = extState.getExtStateValueBool(LAx_ProductData.name, "ShowTakeMarkers", true)

    -- Main variables
    self.delayTimeElapsed = 0
    self.lastTime = reaper.time_precise()
    self.selectionChangeTimer = 0
    self.originalTakePseudoHash = 0
    self.originalSelectionCount = 0
    self.keyWasPressed = false
    self.actionWasTriggered = false
    self.hasGhostTracks = false
    self.nextSettingsUpdateCheck = 0

    -- ArrangeView
    self.arrangeView = {}
    self.arrangeView.allowUpdate = true

    -- Transient detection
    self.previousMousePosX = -1
    self.previousMouseMovementDirectionX = 0
    self.gotNextTransient = false
    self.transientGhostItemObject = nil
    self.noTransientInCurrentDirection = false

    -- Arrays
    self.originalSelectedItems = {}
    self.firstTrackItems = {}
    self.processedTracks = {}

    -- Default strings
    self.ghostItemName = "--SV--TEMP--"
    self.ghostTrackName = "--SV--TEMP--"

    -- Cleanup
    self.lastCleanUp = reaper.time_precise()
    self.cleanUpInterval = 0.75
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
	mainRoute: Main routine
--]]
function GState:mainRoutine()
    -- Check for settings update
    if reaper.time_precise() >= self.nextSettingsUpdateCheck then
        if extState.getExtStateValue(LAx_ProductData.name, "LastSettingsUpdate", 0) > 0  then
            self:updateSettings()
            reaper.SetExtState(LAx_ProductData.name, "LastSettingsUpdate", "0", false)
        end

        self.nextSettingsUpdateCheck = reaper.time_precise() + 0.75
    end

    -- Update GhostItemStartPos if neccessary
    if self.actionWasTriggered then
        self.ghostItems:updateAllItemValues()
    end

    -- Transient Snap
    if self.actionWasTriggered and self.settings.snapToTransients and self:isMouseClickOverSelectedItem(true) then
        self:handleTransientSnap()
    elseif self.gotNextTransient then
        self:resetTransientSnapVariables()
    end

    -- If the action is alrady running but the selection has changed, "refresh" by simulating a new press
    if self.actionWasTriggered and self:hasSelectionChanged() then
        self:simulateNewKeyPress()
    else
        -- Otherwise proceed to check for keyboard inputs
        local keyDown = self:isKeyDown() -- Check if key input matches criteria

        if keyDown and not self.keyWasPressed then
            -- Check if delay is set and if so, track elapsed time
            local delay = extState.getExtStateValue(LAx_ProductData.name, "Delay", 0) -- Default: 0

            -- If a delay is set, activate the timer before the action is shown
            if (delay > 0) then
                if self.delayTimeElapsed == 0 then
                    self.lastTime = reaper.time_precise()
                end

                self.delayTimeElapsed = reaper.time_precise() - self.lastTime
            end

            -- Allow execution of the main function if delay time has passed
            if self.delayTimeElapsed >= delay and self:isMouseInArrangeView() then
                -- Key is pressed, and it wasn't pressed before
                reaper.PreventUIRefresh(1)
                self:onKeyPress()
                reaper.PreventUIRefresh(-1)
            end
        elseif not keyDown and self.keyWasPressed then
            -- Key is released, and it was previously pressed
            reaper.PreventUIRefresh(1)
            self:onKeyRelease()
            reaper.PreventUIRefresh(-1)
        end

        self:cleanUp()
    end
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
	simulateNewKeyPress: Simulates releasing and re-pressing the shortcut.
        Basically a refresh.
--]]
function GState:simulateNewKeyPress()
    reaper.PreventUIRefresh(1)
    self:onKeyRelease()
    self:onKeyPress()
    reaper.PreventUIRefresh(-1)
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
	handleTransientSnap: Handles transient snapping.
    @return1: Did a snap happen [Bool]
--]]
function GState:handleTransientSnap()
    -- Check which direction the mouse is moving. Skip if it's the first frame of mouse movement,
    -- we need to get movement data first.
    local mouseMovementDirectionX, firstFrameMoving, directionChange = self:handleMouseMovement()
    if firstFrameMoving or mouseMovementDirectionX == 0 then
        return false
    end

    if not directionChange and State.noTransientInCurrentDirection then
        return false
    elseif directionChange and not self.gotNextTransient then
        self:resetTransientSnapVariables()
        self.gotNextTransient = self.ghostItems:getNextTransientInDirection(mouseMovementDirectionX)
        return false
    else
        if self.noTransientInCurrentDirection or not self.ghostItems.transientTakeMarkerGhostItemObject then
            return false
        end

        local ghostItem = self.ghostItems.transientTakeMarkerGhostItemObject.item
        local take = reaper.GetActiveTake(ghostItem)
        local originalItemStartPosRelative = self.ghostItems.transientTakeMarkerGhostItemObject
            .originalItemStartPosRelative
        local _, posOut = reaper.GetTakeStretchMarker(take, 0)
        local distance = originalItemStartPosRelative - posOut *
            self.ghostItems.transientTakeMarkerGhostItemObject.playRateFactor

        -- Debug
        --[[
        reaper.ClearConsole()
        msg("OStartPosRelative: " .. originalItemStartPosRelative .. "\nPosOut: " .. posOut .. "\nDistance: " ..
                distance .. "\n\n")
        --]]

        -- A distance of exactly 0 means we started on a transient, so we look for the next one to prevent a "lock".
        if distance == 0 then
            self:resetTransientSnapVariables()
            self.gotNextTransient = self.ghostItems:getNextTransientInDirection(mouseMovementDirectionX)
            return false
        end

        -- Get a new transient if the user "overshot" the previously detected one
        if mouseMovementDirectionX ~= 0 then
            if (mouseMovementDirectionX == 1 and distance < 0) or (mouseMovementDirectionX == -1 and distance > 0) then
                self:resetTransientSnapVariables()
                self.gotNextTransient = self.ghostItems:getNextTransientInDirection(mouseMovementDirectionX)
                return false
            end
        end

        -- Perform the snap if distance to transient is close enough (may the gods forgive this unholy equation)
        local zoomLevel = reaper.GetHZoomLevel()
        local snapDistanceAdjusted = 0.25 - 0.23 * utility.interpolate(zoomLevel, 20, 4000, 0, 1) ^ 0.25 - 0.017 *
            utility.interpolate(zoomLevel, 4000, 100000, 0, 1) ^ 0.40

        if math.abs(distance) <= snapDistanceAdjusted then
            -- We simulate the user lifting the left mouse button to prevent further dragging after snap.
            utility.simulateActionInMainHWND("WM_LBUTTONUP")
            self.ghostItems:snapToTransient(distance)
            self:simulateNewKeyPress()

            return true
        end
    end

    return false
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
	resetTransientSnapVariables: Resets variables related to transient snapping.
--]]
function GState:resetTransientSnapVariables()
    self.gotNextTransient = false
    self.ghostItems:refreshValues()
    self.transientGhostItemObject = nil
    self.arrangeView.allowUpdate = true
    self.noTransientInCurrentDirection = false
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
	resetMouseDirectionTrackingVariables: Resets variables related to mouse direction tracking.
--]]
function GState:resetMouseDirectionTrackingVariables()
    self.previousMousePosX = -1
    self.previousMouseMovementDirectionX = 0
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
	onKeyPress: Executes when all required keys are pressed and other prerequisites are met.
--]]
function GState:onKeyPress()
    self.keyWasPressed = true
    self.actionWasTriggered = true

    self:updateSettings()
    self:gatherSelectedItemInfo()

    if self.originalSelectionCount == 0 then
        return
    end

    self:createMainItems()

    -- Create transient guides (only for Ghost Items)
    if self.settings.snapToTransients and self.settings.showTransientGuides then
        for item, v in pairs(self.originalSelectedItems) do
            reaper.SetMediaItemSelected(item, false)
        end

        reaper.Main_OnCommand(42028, 0) -- Calculate transient guides

        for item, v in pairs(self.originalSelectedItems) do
            reaper.SetMediaItemSelected(item, true)
        end
    end
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
	onKeyRelease: Executes when the required keys are released
--]]
function GState:onKeyRelease()
    self.keyWasPressed = false
    self.actionWasTriggered = false

    -- Exit if no Ghost Items and Ghost Tracks are stored
    if tables.getMapElementCount(self.ghostItems.allGhostItems) == 0 and not self.hasGhostTracks then
        return
    end

    -- If ghostTracks are present, delete them (which will delete all items with them).
    -- Otherwise delete GhostItems within the existing tracks.
    if (self.hasGhostTracks) then
        for ghostTrack, v in pairs(self.ghostTracks.allGhostTracks) do
            if reaper.ValidatePtr(ghostTrack, 'MediaTrack*') then
                reaper.DeleteTrack(ghostTrack)
            end
        end
    else
        for ghostItem, v in pairs(self.ghostItems.allGhostItems) do
            if reaper.ValidatePtr(ghostItem, 'MediaItem*') then
                local ghostItemTrack = reaper.GetMediaItemTrack(ghostItem)
                reaper.DeleteTrackMediaItem(ghostItemTrack, ghostItem)
            end
        end
    end

    -- Clear arrays, update variables, arrangement view and playlist
    self.ghostItems:clear()
    self.ghostTracks:clear()
    self.hasGhostTracks = false

    self.lastTime = reaper.time_precise()
    self.delayTimeElapsed = 0

    self:resetTransientSnapVariables()
    self:resetMouseDirectionTrackingVariables()

    reaper.TrackList_AdjustWindows(false)
    reaper.UpdateArrange()
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
	isKeyDown: Checks whether the SlipView shortcuts have been pressed
	@return1: Whether shortcuts are pressed and additional conditions are met [Bool]
--]]
function GState:isKeyDown()
    local keyboardState = reaper.JS_VKeys_GetState(0) -- Get the keyboard state
    local primaryKeyDown = keyboardState:byte(self.settings.primaryKey) & 1 ~= 0
    local modifierKeyDown = not self.settings.modifierKey or (keyboardState:byte(self.settings.modifierKey) & 1 ~= 0)

    local onlyOnDrag = extState.getExtStateValueBool(LAx_ProductData.name, "ShowOnlyOnDrag", false)
    local dragGate = not onlyOnDrag or self:isMouseClickOverSelectedItem()

    return ((primaryKeyDown and modifierKeyDown) and dragGate)
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
	isMouseClickOverSelectedItem: Checks if the mouse click happened over a selected item
    @arg1: Whether to check even if items were already created [Bool] (Optional)
	@return1: Whether the mouse was clicked over a selected item [Bool]
--]]
function GState:isMouseClickOverSelectedItem(checkDespiteActive)
    -- If the items are already created, we don't care about what's under the cursor anymore
    if self.actionWasTriggered and not checkDespiteActive then
        return true
    end

    -- Check if mouse is clicked, return if not
    if not utility.isMouseClicked() then
        return false
    end

    -- Check if an item is under cursor, exit if not
    reaper.BR_GetMouseCursorContext()
    local itemUnderCursor = reaper.BR_GetMouseCursorContext_Item()

    if not itemUnderCursor then
        return false
    end

    -- Check if items are selected, exit if not
    local selectedItemsCount = reaper.CountSelectedMediaItems(0)

    if selectedItemsCount == 0 and not checkDespiteActive then
        return false
    end

    -- Loop through all selected items, fill arrays/tables, make sure only the first per track
    local isSelectedItemUnderCursor = false

    for i = 0, selectedItemsCount - 1 do
        if reaper.GetSelectedMediaItem(0, i) == itemUnderCursor then
            return true
        end
    end

    if checkDespiteActive then
        for ghostItem, v in pairs(self.ghostItems.allGhostItems) do
            if ghostItem == itemUnderCursor then
                return true
            end
        end
    end

    return false
end

----------------------------------------------------------------------------------------
-- Gathers the data about selected items
function GState:gatherSelectedItemInfo()
    -- Reset variables
    self.firstTrackItems = {}
    self.originalSelectionCount = 0
    self.originalTakePseudoHash = 0
    self.originalSelectedItems = {}
    local processedTracks = {}

    -- Exit if no items are selected
    local selectedItemsCount = reaper.CountSelectedMediaItems(0)
    if selectedItemsCount == 0 then
        return
    end

    -- Loop through all selected items, fill arrays/tables, make sure only the first per track
    for i = 0, selectedItemsCount - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local track = reaper.GetMediaItemTrack(item)
        local take = reaper.GetActiveTake(item)

        if not processedTracks[track] and take then
            self.firstTrackItems[item] = true
            processedTracks[track] = true
        end

        if take then
            self.originalSelectedItems[item] = true
        end

        self.originalSelectionCount = self.originalSelectionCount + 1
    end
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
	hasSelectionChanged: Checks whether or not the selection has changed.
	@return1: Whether the selection has changed [Bool]
--]]
function GState:hasSelectionChanged()
    self.selectionChangeTimer = reaper.time_precise() - self.selectionChangeTimer

    if self.selectionChangeTimer < 0.1 then
        return false
    end

    self.selectionChangeTimer = 0

    local currentTakePseudoHash = 0

    for item, v in pairs(self.firstTrackItems) do
        if reaper.ValidatePtr(item, 'MediaItem*') then
            local take = reaper.GetActiveTake(item)

            if take then
                local takeNumber = reaper.GetMediaItemTakeInfo_Value(take, "IP_TAKENUMBER")
                currentTakePseudoHash = currentTakePseudoHash + takeNumber
            else
                currentTakePseudoHash = currentTakePseudoHash + 0.5 -- In case the item has no take
            end
        end
    end

    local totalSelectionCount = self.originalSelectionCount + tables.getMapElementCount(self.ghostItems.allGhostItems)

    --[[
    -- DEBUG
    reaper.ClearConsole()
    msg(
        "Takes\nCurrent: " .. tostring(currentTakePseudoHash) .. "\nOriginal: " .. tostring(self.originalTakePseudoHash) ..
            "\n\nSelection\nCurrent:" .. tostring(totalSelectionCount) .. "\nReaperCount: " .. tostring(reaper.CountSelectedMediaItems(0)) .. "\nOriginal: " ..
            tostring(self.originalSelectionCount))
    --]]

    return ((reaper.CountSelectedMediaItems(0) ~= totalSelectionCount) or
        (currentTakePseudoHash ~= self.originalTakePseudoHash))
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
	isMouseInArrangeView: Checks whether or not the mouse is in the arrange view.
	@return1: Mouse is in arrange view [Bool]
--]]
function GState:isMouseInArrangeView()
    local window = reaper.BR_GetMouseCursorContext()

    return (window == "arrange")
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
	createMainItems: Creates the Ghost Items and Ghost Tracks based on the gathered data
--]]
function GState:createMainItems()
    -- Check if auto-crossfade and overlap trimming is enabled, disable temporarily if so
    local isAutoCrossfadeEnabled = reaper.GetToggleCommandState(40041)
    local isOverlapTrimmingEnabled = reaper.GetToggleCommandState(41117)

    if isAutoCrossfadeEnabled == 1 and not self.settings.dontDisableAutoCF then
        reaper.Main_OnCommand(41119, 0) -- Disable Auto Crossfade
    end

    if isOverlapTrimmingEnabled == 1 then
        reaper.Main_OnCommand(41121, 0)
    end

    -- Loop through selected items, do the main magic
    reaper.PreventUIRefresh(1)
    local didCreateItems = false
    for item, v in pairs(self.firstTrackItems) do
        local currentItem = item

        if not currentItem then
            return
        end

        local itemTrack = reaper.GetMediaItemTrack(currentItem)

        -- Create the Ghost Items, Also create a Ghost Track if specified in the settings
        if self.settings.createGhostTrack then
            local ghostTrack = self.ghostTracks:createGhostTrack(itemTrack)

            local success = self.ghostItems:createGhostItem(currentItem, ghostTrack)

            if success then
                didCreateItems = true
                self.hasGhostTracks = true
            end
        else
            local ghostItem = self.ghostItems:createGhostItem(currentItem, itemTrack)

            didCreateItems = true
        end
    end

    -- Re-enable crossfade and trimming if applicable
    if isAutoCrossfadeEnabled == 1 and not self.settings.dontDisableAutoCF then
        reaper.Main_OnCommand(41118, 0)
    end

    if isOverlapTrimmingEnabled == 1 then
        reaper.Main_OnCommand(41120, 0)
    end

    -- Restore selection of originally selected items and select all created Ghost Items
    for item, v in pairs(self.originalSelectedItems) do
        reaper.SetMediaItemSelected(item, true)
    end

    for item, v in pairs(self.ghostItems.allGhostItems) do
        reaper.SetMediaItemSelected(item, true)
    end

    -- Update tracklist and arrange window
    reaper.TrackList_AdjustWindows(false)
    reaper.UpdateArrange()
    reaper.PreventUIRefresh(-1)

    return didCreateItems
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
	handleMouseMovement: Gets the movement direction of the mouse in the x axis
    @return1: MouseMovementDirection [Integer] (-1 = Left, 0 = None, 1 = Right)
    @return2: Is first frame of movement [Bool]
    @return3: Did the direction change from left<->right [Bool]
--]]
function GState:handleMouseMovement()
    -- No previous data available, set to non-moving for first tick
    if self.previousMousePosX == -1 then
        self.previousMousePosX = reaper.GetMousePosition()
        return nil, true, false
    end

    local mousePosX = reaper.GetMousePosition()
    local directionChange = false
    local movementDirection = 0

    if mousePosX < self.previousMousePosX then
        movementDirection = -1
    elseif mousePosX == self.previousMousePosX then
        movementDirection = 0
    else
        movementDirection = 1
    end

    -- Check for direction change
    if movementDirection ~= 0 and self.previousMouseMovementDirectionX ~= movementDirection then
        directionChange = true

        --[[
        -- DEBUG
        msg("Changed direction." .. "\nPrevious: " .. self.previousMouseMovementDirectionX .. "\nNow: " ..
                movementDirection .. "\n\n")
        -]]

        self.previousMouseMovementDirectionX = movementDirection
    end

    self.previousMousePosX = mousePosX

    return movementDirection, false, directionChange
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
	cleanUp: Deletes all existing Ghost Items and Ghost Tracks
--]]
function GState:cleanUp()
    -- Don't delete stuff if Ghost Previews are currently shown
    if self.actionWasTriggered then
        return
    end

    -- Return if it's not yet time for the next cleanup
    if (reaper.time_precise() - self.lastCleanUp) < self.cleanUpInterval then
        return
    end

    self.lastCleanUp = reaper.time_precise()

    -- Loop through each media item, delete if it matches the GhostItem name
    reaper.PreventUIRefresh(1)
    local numItems = reaper.CountMediaItems(0)
    local hasDeleted = false

    for i = 0, numItems - 1 do
        local mediaItem = reaper.GetMediaItem(0, i)

        if mediaItem then
            local take = reaper.GetTake(mediaItem, 0)

            if take then
                local takeName = reaper.GetTakeName(take)

                if (takeName == self.ghostItemName) then
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

            if (trackName == self.ghostTrackName) then
                reaper.DeleteTrack(track)
                hasDeleted = true
            end
        end
    end

    if hasDeleted then
        reaper.TrackList_AdjustWindows(false)
    end

    reaper.PreventUIRefresh(-1)

    --[[
    -- DEBUG
    local elapsedTime = reaper.time_precise() - startTime
    reaper.ShowConsoleMsg("Items:" .. tostring(numItems) .."\n" .. tostring(elapsedTime))
    --]]
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
	updateSettings: Updates the Settings
--]]
function GState:updateSettings()
    self.settings.primaryKey = extState.getExtStateValue(LAx_ProductData.name, "PrimaryKey", 18)    -- Default: ALT (18)
    self.settings.modifierKey = extState.getExtStateValue(LAx_ProductData.name, "ModifierKey", nil) -- Default: nil (no modifier)
    self.settings.createGhostTrack = extState.getExtStateValueBool(LAx_ProductData.name, "CreateGhostTrack", false)                                                                                -- Default: 0
    self.settings.snapToTransients = extState.getExtStateValueBool(LAx_ProductData.name, "SnapToTransients", false)
    self.settings.showTransientGuides = extState.getExtStateValueBool(LAx_ProductData.name, "ShowTransientGuides", false)
    self.settings.dontDisableAutoCF = extState.getExtStateValueBool(LAx_ProductData.name, "DontDisableAutoCF", false)
    self.settings.restrictToNeighbors = extState.getExtStateValueBool(LAx_ProductData.name, "RestrictToNeighbors", true)
    self.settings.showTakeMarkers = extState.getExtStateValueBool(LAx_ProductData.name, "ShowTakeMarkers", true)                                                                                  -- Default: 0
end
