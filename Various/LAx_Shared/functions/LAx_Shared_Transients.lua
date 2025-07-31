-- @noindex
local M = {}

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    getNextTransientFromStart: Tries to get a transient in a specified direction
	@arg1: Item [Item]
	@arg2: Direction [Integer]
	@return1: Distance to next transient from item start position (0 = No transient found) [Float]
--]]
function M.getNextTransientFromStart(item, direction)
    local take = reaper.GetActiveTake(item)

    if not take then
        return 0
    end

    reaper.PreventUIRefresh(1)

    -- Get current state
    local arrangeViewStart, arrangeViewEnd = reaper.GetSet_ArrangeView2(0, false, 0, 0, 0, 0)
    local cursorStartPos = reaper.GetCursorPosition()

    local originalItemLength = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    local itemStartPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local playRate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    local playRateFactor = (1 / playRate)
    local itemTakeSource = reaper.GetMediaItemTake_Source(take)
    local itemTakeSourceLength = reaper.GetMediaSourceLength(itemTakeSource) * playRateFactor
    local originalStartOffset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")

    local startPosOffset = 0

    reaper.SetMediaItemInfo_Value(item, "D_LENGTH", itemTakeSourceLength)

    -- We need to shift the item so its full waveform is temporarily shown in order to detect previous transients
    if direction < 0 then
        local newItemStartPos = itemStartPos - originalStartOffset * playRateFactor

        -- If we'd clip into the timeline start, we need to offset the item to get "everything before"
        if newItemStartPos < 0 then
            startPosOffset = math.abs(newItemStartPos)
            newItemStartPos = 0
        end

        reaper.SetEditCurPos(itemStartPos + startPosOffset, false, false)

        reaper.SetMediaItemInfo_Value(item, "D_POSITION", newItemStartPos)
        reaper.SetMediaItemTakeInfo_Value(take, "D_STARTOFFS", 0)

        reaper.Main_OnCommand(40376, 0) -- Cursor to previous transient
    else
        reaper.SetEditCurPos(itemStartPos, false, false)
        reaper.Main_OnCommand(40375, 0) -- Cursor to next transient
    end

    reaper.SetMediaItemInfo_Value(item, "D_LENGTH", originalItemLength)

    local transientPosition = reaper.GetCursorPosition()
    local offset = transientPosition - (itemStartPos + startPosOffset)

    --[[
    -- DEBUG
    reaper.ClearConsole()
    msg("Transient position: " .. transientPosition ..
        "\nItemStartPos: " .. itemStartPos ..
        "\nOffset: " .. offset .. "\n\n")
    --]]

    if direction < 0 then
        reaper.SetMediaItemTakeInfo_Value(take, "D_STARTOFFS", originalStartOffset)
        reaper.SetMediaItemInfo_Value(item, "D_POSITION", itemStartPos)
    end

    reaper.SetEditCurPos(cursorStartPos, false, false)
    reaper.GetSet_ArrangeView2(0, true, 0, 0, arrangeViewStart, arrangeViewEnd) -- Undo the view shift from moving cursor to transient
    reaper.PreventUIRefresh(-1)

    return offset
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    moveItemContentToNextTransient: Tries to move an item's content to its next transient in a specified direction
	@arg1: Item [Item]
	@arg2: Direction [Integer]
	@return1: Was moved successfully [Bool]
    @return2: Move offset [Float]
--]]
function M.moveItemContentToNextTransient(item, direction)
    local offset = M.getNextTransientFromStart(item, direction)

    if offset == 0 then
        return false, offset
    end

    local take = reaper.GetActiveTake(item)

    if not take then
        return false, offset
    end

    local playRate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    local originalStartOffset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
    local targetStartOffset = originalStartOffset + offset * playRate

    reaper.SetMediaItemTakeInfo_Value(take, "D_STARTOFFS", targetStartOffset)
    reaper.UpdateArrange()

    return true, offset
end

return M
