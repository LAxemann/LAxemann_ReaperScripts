-- @noindex

local M = {}

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[ 
    getItemStartAndEnd: Returns the item start and end positions in seconds
    @arg1: item [Media Item]
	@return1: Item start position in s [Float]
	@return2: Item end position in s [Float]
--]]
function M.getItemStartAndEnd(item)
	local itemStart = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
	local itemEnd = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
	return itemStart,  (itemStart + itemEnd)
end

return M