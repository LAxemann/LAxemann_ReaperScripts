-- @noindex
----------------------------------------------------------------------------------------
-- Run Shared
LAx_Shared_Installed = false
local currentFolder = (debug.getinfo(1).source:match("@?(.*[\\|/])"))
currentFolder = currentFolder:gsub("\\", "/")
dofile(currentFolder .. "runShared.lua")
if not LAx_Shared_Installed then
    return
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
-- Requirements
local extState = require("LAx_Shared_ExtState")

-- CONFIG --
RANDOM_OFFSET_MS = extState.getExtStateValue(LAx_ProductData.name, "StretchMarkersToNearestTransients_RandomOffset", 70)    -- Maximum offset the markers will be placed at
OFFSET_MODE = extState.getExtStateValue(LAx_ProductData.name, "StretchMarkersToNearestTransients_Mode", 0)                  -- 1 = Left only, 2 = Right only, 0 = Both directions

-- DO NOT EDIT BELOW HERE (Unless you know what you're doing :D) -----------------------
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
local loopStartPos, loopEndPos = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
local isLoopSelectionSet = loopEndPos > 0

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    GetNextTransientPos: Gets the nearest transient position adjusted for marker creation
	@arg1: timeLinePosition [Double]
	@arg2: itemStartPos [Double]
	@arg3: playRate [Double]
	@return1: Marker position on nearest transient [Double]
--]]
function GetNextTransientPos(timeLinePos, itemStartPos, playRate)
    reaper.PreventUIRefresh(1)

    reaper.SetEditCurPos(timeLinePos, false, false)
    reaper.Main_OnCommand(40376, 0) -- Cursor to previous transient
    local offsetLeft = reaper.GetCursorPosition() - timeLinePos

    reaper.SetEditCurPos(timeLinePos, false, false)
    reaper.Main_OnCommand(40375, 0) -- Cursor to next transient
    local offsetRight = reaper.GetCursorPosition() - timeLinePos

    local offset = offsetRight < math.abs(offsetLeft) and offsetRight or offsetLeft
    local randomOffset = GetRandomOffset()

    local newMarkerPos = ((timeLinePos + offset) - itemStartPos) * playRate + randomOffset * playRate

    reaper.PreventUIRefresh(-1)

    return newMarkerPos
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    GetRandomOffset: Gets a random offset based on RANDOM_OFFSET_MS and OFFSET_MODE
    @return1: Random offset (in seconds) [Double]
--]]
function GetRandomOffset()
    local offsetSeconds = RANDOM_OFFSET_MS / 1000

    local min, max
    if OFFSET_MODE == 1 then
        min = offsetSeconds * -1
        max = 0
    elseif OFFSET_MODE == 2 then
        min = 0
        max = offsetSeconds
    elseif OFFSET_MODE == 0 then
        min = offsetSeconds * -1
        max = offsetSeconds
    else
        min = 0
        max = 0
    end

    return min + math.random() * (max - min)
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    GetStretchMarkerData:
	@arg1: take [Take]
	@arg2: itemStartPos [Double]
	@arg3: playRate [Double]
	@return1: First valid stretchMarker index [Integer]
	@return2: Amount of markers to delete [Integer]
	@return3: newMarkerPositions [Table]
--]]
function GetStretchMarkerData(take, itemStartPos, playRate)
    local stretchMarkerCount = reaper.GetTakeNumStretchMarkers(take)
    local firstIndex = -1
    local markerDeletionCount = 0
    local newMarkerPositions = {}

    if stretchMarkerCount == 0 then
        return firstIndex, markerDeletionCount, newMarkerPositions
    end

    for i = 0, stretchMarkerCount - 1 do
        local _, markerPos = reaper.GetTakeStretchMarker(take, i)

        local timeLinePos = itemStartPos + markerPos / playRate

        if isLoopSelectionSet and (timeLinePos < loopStartPos or timeLinePos > loopEndPos) then
            goto continue
        end

        local newMarkerPos = GetNextTransientPos(timeLinePos, itemStartPos, playRate)

        if firstIndex == -1 then
            firstIndex = i
        end

        markerDeletionCount = markerDeletionCount + 1
        table.insert(newMarkerPositions, newMarkerPos)

        ::continue::
    end

    return firstIndex, markerDeletionCount, newMarkerPositions
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
function Main()
    local selectedItemCount = reaper.CountSelectedMediaItems(0)

    if selectedItemCount == 0 then
        return
    end

    reaper.PreventUIRefresh(1)
    local arrangeViewStart, arrangeViewEnd = reaper.GetSet_ArrangeView2(0, false, 0, 0, 0, 0)
    local cursorStartPos = reaper.GetCursorPosition()

    for i = 0, selectedItemCount - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)

        if not item then
            goto continue
        end

        local take = reaper.GetActiveTake(item)

        if not take then
            goto continue
        end

        local itemStartPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local playRate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")

        local firstIndex, markerDeletionCount, newMarkerPositions = GetStretchMarkerData(take, itemStartPos, playRate)

        if markerDeletionCount == 0 then
            goto continue
        end

        reaper.DeleteTakeStretchMarkers(take, firstIndex, markerDeletionCount)

        for _, pos in pairs(newMarkerPositions) do
            reaper.SetTakeStretchMarker(take, -1, pos)
        end

        ::continue::
    end

    reaper.SetEditCurPos(cursorStartPos, false, false)
    reaper.GetSet_ArrangeView2(0, true, 0, 0, arrangeViewStart, arrangeViewEnd) -- Undo the view shift from moving cursor to transient
    reaper.PreventUIRefresh(-1)
end

Main()
