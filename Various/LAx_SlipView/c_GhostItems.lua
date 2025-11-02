-- @noindex
----------------------------------------------------------------------------------------
-- Requirements
local tables = require("LAx_Shared_Tables")

----------------------------------------------------------------------------------------
-- Declaration + Constructor
GhostItems = {}
GhostItems.__index = GhostItems

function GhostItems.new()
    local instance = setmetatable({}, GhostItems)
    return instance
end

function GhostItems:init()
    self.allGhostItems = {}
    self.allGhostItemObjects = {}
    self.transientTakeMarkerGhostItemObject = nil
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
	createGhostItem: Creates a new Ghost Item and registers it
    @return1: Successful creation [Bool]
--]]
function GhostItems:createGhostItem(item, track)
    local ghostItemObject = GhostItem:new()
    local createSuccess = ghostItemObject:create(item, track)

    if not createSuccess then
        return false
    end

    self.allGhostItems[ghostItemObject.item] = true
    self.allGhostItemObjects[ghostItemObject] = ghostItemObject.item

    return true
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
	getNextTransientInDirection:
    @return1: New transient found [Bool]
--]]
function GhostItems:getNextTransientInDirection(movementDirection)
    if tables.getMapElementCount(self.allGhostItemObjects) == 0 then
        return false
    end

    local arrangeViewStart, arrangeViewEnd = reaper.GetSet_ArrangeView2(0, false, 0, 0, 0, 0)
    local cursorStartPos = reaper.GetCursorPosition()

    reaper.PreventUIRefresh(1)
    for ghostItemObject, item in pairs(self.allGhostItemObjects) do
        -- With neighborRestriction, we need to bring the ghost item to full length so all transients can get detected.
        local isRestricted = (not State.settings.createGhostTrack) and State.settings.restrictToNeighbors
        if isRestricted then
            reaper.SetMediaItemInfo_Value(ghostItemObject.item, "D_LENGTH", ghostItemObject.length)
        end

        reaper.SetEditCurPos(ghostItemObject.originalItemStartPos, false, false)

        if movementDirection == 1 then
            reaper.Main_OnCommand(40376, 0) -- Cursor to previous transient
        else
            reaper.Main_OnCommand(40375, 0) -- Cursor to next transient
        end

        -- We shrink the ghost item back
        if isRestricted then
            reaper.SetMediaItemInfo_Value(ghostItemObject.item, "D_LENGTH", ghostItemObject.lengthAdjusted)
        end

        local transientPosition = reaper.GetCursorPosition()
        local offset = transientPosition - ghostItemObject.startPos

        State.noTransientInCurrentDirection = math.abs(transientPosition - ghostItemObject.originalItemStartPos) == 0

        --[[
        -- DEBUG
        reaper.ClearConsole()
        msg("Transient position: " .. transientPosition ..
            "\nGhostItemStartPos: " .. ghostItemObject.startPos ..
            "\nOffset: " .. offset .. "\n\n")
        --]]

        -- Create takeStretchMarker on ghostItem
        local take = reaper.GetActiveTake(ghostItemObject.item)
        if not reaper.TakeIsMIDI(take) and not State.noTransientInCurrentDirection then
            ghostItemObject.transientTakeStretchMarkerID = reaper.SetTakeStretchMarker(take, -1, offset *
                ghostItemObject.playRate)

            self.transientTakeMarkerGhostItemObject = ghostItemObject

            reaper.SetEditCurPos(cursorStartPos, false, false)
            reaper.GetSet_ArrangeView2(0, true, 0, 0, arrangeViewStart, arrangeViewEnd) -- Undo the view shift from moving cursor to transient
            reaper.PreventUIRefresh(-1)
            return true
        end
        reaper.SetEditCurPos(cursorStartPos, false, false)
    end
    reaper.PreventUIRefresh(-1)

    return false
end

----------------------------------------------------------------------------------------
--[[
	refreshValues: Forces all registered Ghost Items to refresh their transient detection-related values.
--]]
function GhostItems:refreshValues()
    for ghostItemObject, item in pairs(self.allGhostItemObjects) do
        ghostItemObject:refresh()
    end

    self.transientTakeMarkerGhostItemObject = nil
end

----------------------------------------------------------------------------------------
--[[
	snapToTransient: Executes the snapToTransient function on all ghostItems.
    @arg1: Distance to transient [Float]
--]]
function GhostItems:snapToTransient(distance)
    for ghostItem, v in pairs(self.allGhostItemObjects) do
        ghostItem:snapToTransient(distance)
    end
end

----------------------------------------------------------------------------------------
--[[
	updateAllItemValues:
    @arg1: Distance to transient [Float]
--]]
function GhostItems:updateAllItemValues()
    for ghostItem, v in pairs(self.allGhostItemObjects) do
        ghostItem:checkAndUpdateValues()
    end
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
	clear: Clears the saved Ghost Items
--]]
function GhostItems:clear()
    self.allGhostItems = {}
    self.allGhostItemObjects = {}
end
