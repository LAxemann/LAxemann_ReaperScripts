-- @noindex
----------------------------------------------------------------------------------------
-- Requirements
local colors = require("LAx_Shared_Colors")

----------------------------------------------------------------------------------------
-- Declaration + Constructor
GhostItem = {}
GhostItem.__index = GhostItem

function GhostItem.new()
    local instance = setmetatable({}, GhostItem)
    return instance
end

----------------------------------------------------------------------------------------
--[[
    create: Creates the ghostItem and sets its properties
    @arg1: item [Media item]
    @arg2: itemTrack [Track]
    @return1: Creation successful [Bool]
--]]
function GhostItem:create(item, itemTrack)
    if not item then
        return false
    end

    local itemTake = reaper.GetActiveTake(item)
    if not itemTake then
        return false
    end

    local itemPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local itemLength = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

    local ghostItemStartOffset, ghostItemTargetPos, sourceItemLength, ghostItemLength, ghostItemPlayRate =
        self:calculateGhostItemValues(item, itemTake, itemPos, itemTrack)

    -- Create the ghost item and set values accordingly
    local ghostItem = reaper.AddMediaItemToTrack(itemTrack)
    reaper.SetMediaItemInfo_Value(ghostItem, "D_POSITION", ghostItemTargetPos)
    reaper.SetMediaItemInfo_Value(ghostItem, "D_LENGTH", ghostItemLength)
    reaper.SetMediaItemInfo_Value(ghostItem, "D_VOL", reaper.GetMediaItemInfo_Value(item, "D_VOL"))
    local ghostItemColor = colors.darkenColor(colors.getItemOrTrackCustomColor(item, itemTrack), 0.5)
    reaper.SetMediaItemInfo_Value(ghostItem, "I_CUSTOMCOLOR", ghostItemColor)
    reaper.SetMediaItemInfo_Value(ghostItem, "F_FREEMODE_Y", reaper.GetMediaItemInfo_Value(item, "F_FREEMODE_Y"))
    reaper.SetMediaItemInfo_Value(ghostItem, "F_FREEMODE_H", reaper.GetMediaItemInfo_Value(item, "F_FREEMODE_H"))
    reaper.SetMediaItemInfo_Value(ghostItem, "B_LOOPSRC", 1)

    -- Apply the original takes
    local takeNumber = reaper.GetMediaItemTakeInfo_Value(itemTake, "IP_TAKENUMBER")
    local takeCount = (State.settings.createGhostTrack and 1) or reaper.GetMediaItemNumTakes(item)
    local ghostTake

    local tempTakeNumber = (State.settings.createGhostTrack and 0) or takeNumber
    for i = 0, takeCount - 1 do
        if (i == tempTakeNumber) then
            ghostTake = reaper.AddTakeToMediaItem(ghostItem)
            reaper.SetActiveTake(ghostTake)
        else
            reaper.AddTakeToMediaItem(ghostItem)
        end
    end

    if ghostTake then
        reaper.SetMediaItemTake_Source(ghostTake, reaper.GetMediaItemTake_Source(itemTake))
        reaper.SetMediaItemTakeInfo_Value(ghostTake, "D_STARTOFFS", ghostItemStartOffset)
        reaper.SetMediaItemTakeInfo_Value(ghostTake, "D_PLAYRATE", ghostItemPlayRate)
        reaper.SetMediaItemTakeInfo_Value(ghostTake, "D_VOL", reaper.GetMediaItemTakeInfo_Value(itemTake, "D_VOL"))
        reaper.SetMediaItemTakeInfo_Value(ghostTake, "I_CHANMODE",
            reaper.GetMediaItemTakeInfo_Value(itemTake, "I_CHANMODE"))
        reaper.SetMediaItemTakeInfo_Value(ghostTake, "I_CUSTOMCOLOR",
            reaper.GetMediaItemTakeInfo_Value(itemTake, "I_CUSTOMCOLOR"))
        reaper.GetSetMediaItemTakeInfo_String(ghostTake, "P_NAME", State.ghostItemName, true)

        if State.settings.showTakeMarkers then
            local takeMarkerCount = reaper.GetNumTakeMarkers(itemTake)

            for i = 0, takeMarkerCount - 1 do
                local takeMarkerOffset, takeMarkerName, takeMarkerColor = reaper.GetTakeMarker(itemTake, i)
                reaper.SetTakeMarker(ghostTake, i, takeMarkerName, takeMarkerOffset, takeMarkerColor)
            end
        end
    end

    State.originalTakePseudoHash = State.originalTakePseudoHash + takeNumber

    -- Set object variables
    self.item = ghostItem
    self.originalItem = item
    self.originalItemStartPos = itemPos
    self.originalItemStartPosRelative = itemPos - ghostItemTargetPos
    self.originalItemLength = itemLength
    self.startPos = ghostItemTargetPos
    self.playRate = ghostItemPlayRate
    self.playRateFactor = 1 / ghostItemPlayRate
    self.startOffsetCompensated = ghostItemStartOffset
    self.transientTakeStretchMarkerID = -1
    self.length = sourceItemLength
    self.lengthAdjusted = ghostItemLength

    return true
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    calculateGhostItemValues: Calculates offset, position and length of the GhostItem.
    @arg1: selectedItem [Media Item]
    @arg2: take [Take]
    @arg3: itemPos [Float]
    @arg4: itemTrack [Track]
    @return1: ghostItemStartOffset [Float]
    @return2: ghostItemTargetPos [Float]
    @return3: itemTakeSourceLength [Float]
    @return4: itemTakeSourceLengthAdjusted [Float]
    @return5: playRate [Float]
--]]
function GhostItem:calculateGhostItemValues(selectedItem, take, itemPos, itemTrack)
    local takeOffset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS") -- Basically how much the item would need to shift left
    local playRate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    local playRateFactor = (1 / playRate)
    local takeOffsetCompensated = takeOffset * playRateFactor
    local itemTakeSource = reaper.GetMediaItemTake_Source(take)
    local itemTakeSourceLength = reaper.GetMediaSourceLength(itemTakeSource) * playRateFactor

    -- Get neighbor item positions. We do it before inserting the ghost item to avoid having to deal with changed indices.
    --  We also don't need to do it if the Ghost Item gets created on a new track anyway.
    local rightNeighborStartPos = 0
    local leftNeighborEndPos = 0

    if (State.settings.restrictToNeighbors and (not State.settings.createGhostTrack)) then
        local itemFixedLane = reaper.GetMediaItemInfo_Value(selectedItem, "I_FIXEDLANE")
        local itemFreeModeStart = reaper.GetMediaItemInfo_Value(selectedItem, "F_FREEMODE_Y")
        local itemFreeModeEnd = itemFreeModeStart + reaper.GetMediaItemInfo_Value(selectedItem, "F_FREEMODE_H")

        local itemEndPos = itemPos + reaper.GetMediaItemInfo_Value(selectedItem, "D_LENGTH")
        local selectedItemIndex = reaper.GetMediaItemInfo_Value(selectedItem, "IP_ITEMNUMBER")

        local rightNeighborItem = self:getNonClippingRightNeighbor(selectedItemIndex, itemTrack, itemEndPos,
            itemFixedLane, itemFreeModeStart, itemFreeModeEnd)

        if rightNeighborItem then
            rightNeighborStartPos = reaper.GetMediaItemInfo_Value(rightNeighborItem, "D_POSITION")
        end

        local leftNeighborItem = self:getNonClippingLeftNeighbor(selectedItemIndex, itemTrack, itemEndPos,
            itemFixedLane, itemFreeModeStart, itemFreeModeEnd)

        if leftNeighborItem then
            leftNeighborEndPos = reaper.GetMediaItemInfo_Value(leftNeighborItem, "D_POSITION") +
                reaper.GetMediaItemInfo_Value(leftNeighborItem, "D_LENGTH")
        end
    end

    -- Calculate start offset if GhostItem collides with a left neighbor.
    -- If no neighbor, the timeline start (0) is considered our neighbor.
    local ghostItemStartOffset = 0
    local ghostItemTargetPos =
        leftNeighborEndPos -- Set Ghost Item position to end of left neighbor/timeline start by default

    local spaceToLeft = itemPos - leftNeighborEndPos
    local isClippingLeft = takeOffsetCompensated >
        spaceToLeft -- Would offsetting the Ghost Item make it clip into an item/the timeline start to the left?

    if isClippingLeft then
        ghostItemStartOffset = (takeOffsetCompensated - spaceToLeft) / playRateFactor
    else
        ghostItemTargetPos = itemPos -
            takeOffsetCompensated -- Allow full expansion if not clipping by shifting to full offset length
    end

    -- Check if GhostItem clips into the right neighbor. If so, look for available space to the left to fill
    local itemTakeSourceLengthAdjusted = itemTakeSourceLength
    if ((State.settings.restrictToNeighbors) and (not State.settings.createGhostTrack) and (rightNeighborStartPos > 0)) then
        local distToRightItem = rightNeighborStartPos - ghostItemTargetPos

        if (itemTakeSourceLength > distToRightItem) then
            local clipRightDistance = itemTakeSourceLength - distToRightItem

            if (not isClippingLeft) then
                local maxPossibleAdjustment = math.min(ghostItemTargetPos - leftNeighborEndPos, clipRightDistance)
                ghostItemTargetPos = ghostItemTargetPos - maxPossibleAdjustment
                ghostItemStartOffset = (ghostItemStartOffset - maxPossibleAdjustment) / playRateFactor
                distToRightItem = rightNeighborStartPos - ghostItemTargetPos
            end

            itemTakeSourceLengthAdjusted = distToRightItem
        end
    end

    return ghostItemStartOffset, ghostItemTargetPos, itemTakeSourceLength, itemTakeSourceLengthAdjusted, playRate
end

----------------------------------------------------------------------------------------
--[[
    getNonClippingRightNeighbor: go through items to the right and check if the entire item isn't clipping inside of the original item
    @arg1: indexStart [Int]
    @arg2: track [Track]
    @arg3: itemEndPos [Float]
    @arg4: itemFixedLane [Int]
    @arg5: itemFreeModeStart [Float]
    @arg6: itemFreeModeEnd [Float]
    @return1: non-clipping right neighbor or nil [Item]
--]]
function GhostItem:getNonClippingRightNeighbor(indexStart, track, itemEndPos, itemFixedLane, itemFreeModeStart,
                                               itemFreeModeEnd)
    local nonClippingRightNeighbor = nil

    local itemsOnTrackCount = reaper.CountTrackMediaItems(track)

    for i = indexStart + 1, itemsOnTrackCount - 1 do
        local currentItem = reaper.GetTrackMediaItem(track, i)
        if currentItem ~= self.item then
            local currentItemFixedLane = reaper.GetMediaItemInfo_Value(currentItem, "I_FIXEDLANE")

            -- No need to do further checks if the two items are not on the same fixed lane
            if currentItemFixedLane == itemFixedLane then
                local itemsOverlap = self:doItemsOverlapInFreeMode(itemFreeModeStart, itemFreeModeEnd, currentItem)

                if itemsOverlap then
                    local currentItemEnd = reaper.GetMediaItemInfo_Value(currentItem, "D_POSITION") +
                        reaper.GetMediaItemInfo_Value(currentItem, "D_LENGTH")

                    -- Check if the current item's start position is greater than the reference item's end position
                    if currentItemEnd > itemEndPos then
                        nonClippingRightNeighbor = currentItem
                        break
                    end
                end
            end
        end
    end

    return nonClippingRightNeighbor
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    getNonClippingLeftNeighbor: go through items to the left and check if the entire item isn't clipping inside of the original item
    @arg1: indexStart [Int]
    @arg2: track [Track]
    @arg3: itemEndPos [Float]
    @arg4: itemFixedLane [Int]
    @arg5: itemFreeModeStart [Float]
    @arg6: itemFreeModeEnd [Float]
    @return1: non-clipping left neighbor or nil [Item]
--]]
function GhostItem:getNonClippingLeftNeighbor(indexStart, track, itemEndPos, itemFixedLane, itemFreeModeStart,
                                              itemFreeModeEnd)
    local nonClippingLeftNeighbor = nil

    for i = indexStart - 1, 0, -1 do
        local currentItem = reaper.GetTrackMediaItem(track, i)
        if currentItem ~= self.item then
            local currentItemFixedLane = reaper.GetMediaItemInfo_Value(currentItem, "I_FIXEDLANE")

            -- No need to do further checks if the two items are not on the same fixed lane
            if currentItemFixedLane == itemFixedLane then
                local itemsOverlap = self:doItemsOverlapInFreeMode(itemFreeModeStart, itemFreeModeEnd, currentItem)

                if itemsOverlap then
                    nonClippingLeftNeighbor = currentItem
                    break
                end
            end
        end
    end

    return nonClippingLeftNeighbor
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    doItemsOverlapInFreeMode: Check if two items would overlap vertically in free mode
    @arg1: itemFreeModeStart [Float]
    @arg2: itemFreeModeEnd [Float]
    @return1: Whether items would overlap vertically or not [Bool]
--]]
----------------------------------------------------------------------------------------
-- Check if the mouse is clicked and a selected item is under the cursor
function GhostItem:doItemsOverlapInFreeMode(itemFreeModeStart, itemFreeModeEnd, otherItem)
    local currentItemFreeModeStart = reaper.GetMediaItemInfo_Value(otherItem, "F_FREEMODE_Y")
    local currentItemFreeModeEnd = currentItemFreeModeStart + reaper.GetMediaItemInfo_Value(otherItem, "F_FREEMODE_H")
    local doesOverlap = (itemFreeModeEnd > currentItemFreeModeStart and itemFreeModeStart < currentItemFreeModeEnd)

    --[[
    -- DEBUG
	reaper.ClearConsole()
	reaper.ShowConsoleMsg(
		"1 Start: " ..
		tostring(itemFreeModeStart) ..
		"\n1 End: " ..
		tostring(itemFreeModeEnd) ..
		"\n2 Start: " ..
		tostring(currentItemFreeModeStart) ..
		"\n2 End: " ..
		tostring(currentItemFreeModeEnd) ..
		"\nOverlaps: " ..
		tostring(doesOverlap)
	)
	--]]

    return doesOverlap
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    snapToTransient: Snaps the Ghost Item and the original item to the transient
        by offsetting by distance.
    @arg1: distance [Float]
    @return1: Snap successful [Bool]
--]]
function GhostItem:snapToTransient(distance)
    if not reaper.ValidatePtr(self.item, 'MediaItem*') then
        return false
    end

    local ghostTake = reaper.GetActiveTake(self.item)
    local ghostTakeOffset = reaper.GetMediaItemTakeInfo_Value(ghostTake, "D_STARTOFFS")
    reaper.SetMediaItemTakeInfo_Value(ghostTake, "D_STARTOFFS", ghostTakeOffset - distance * self.playRate)

    if not reaper.ValidatePtr(self.originalItem, 'MediaItem*') then
        return false
    end

    local originalTake = reaper.GetActiveTake(self.originalItem)
    local originalTakeOffset = reaper.GetMediaItemTakeInfo_Value(originalTake, "D_STARTOFFS")
    reaper.SetMediaItemTakeInfo_Value(originalTake, "D_STARTOFFS", originalTakeOffset - distance * self.playRate)

    return true
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    checkAndUpdateValues: Refreshes variables
    @return1: Updated length [Bool]
    @return2: Updated playRate [Bool]
--]]
function GhostItem:checkAndUpdateValues()
    if not reaper.ValidatePtr(self.originalItem, 'MediaItem*') then
        return false, false
    end

    local itemLength = reaper.GetMediaItemInfo_Value(self.originalItem, "D_LENGTH")
    local take = reaper.GetActiveTake(self.originalItem)
    local playRate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")

    if self.originalItemLength ~= itemLength or self.playRate ~= playRate then
        local ghostItemStartOffset, ghostItemTargetPos, sourceItemLength, ghostItemLength, ghostItemPlayRate =
            self:calculateGhostItemValues(self.originalItem, reaper.GetActiveTake(self.originalItem),
                reaper.GetMediaItemInfo_Value(self.originalItem, "D_POSITION"),
                reaper.GetMediaItem_Track(self.originalItem))

        self.playRate = ghostItemPlayRate
        self.startOffsetCompensated = ghostItemStartOffset
        self.startPos = ghostItemTargetPos
        self.playRate = ghostItemPlayRate
        self.playRateFactor = 1 / ghostItemPlayRate
        self.originalItemLength = itemLength

        reaper.SetMediaItemInfo_Value(self.item, "D_POSITION", ghostItemTargetPos)
        reaper.SetMediaItemInfo_Value(self.item, "D_LENGTH", ghostItemLength)

        local ghostTake = reaper.GetActiveTake(self.item)
        reaper.SetMediaItemTakeInfo_Value(ghostTake, "D_STARTOFFS", ghostItemStartOffset)
        reaper.SetMediaItemTakeInfo_Value(ghostTake, "D_PLAYRATE", ghostItemPlayRate)
    end
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    refresh: Refreshes variables
    @return1: Refresh successful [Bool]
--]]
function GhostItem:refresh()
    if not reaper.ValidatePtr(self.item, 'MediaItem*') then
        return false
    end

    self.startPos = reaper.GetMediaItemInfo_Value(self.item, "D_POSITION")

    local take = reaper.GetActiveTake(self.item)
    self.playRateFactor = 1 / reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    self.startOffsetCompensated = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS") * self.playRateFactor

    if self.transientTakeStretchMarkerID ~= -1 then
        reaper.DeleteTakeMarker(take, self.transientTakeStretchMarkerID)
        reaper.DeleteTakeStretchMarkers(take, self.transientTakeStretchMarkerID)
        self.transientTakeStretchMarkerID = -1
    end

    return true
end
