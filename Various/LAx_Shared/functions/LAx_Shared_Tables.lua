-- @noindex
local M = {}

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[ 
    getReversedTable: Reverses a table
	@arg1: Table [Table]
	@return1: Reversed table [Table]
--]]
function M.getReversedTable(tbl)
    local reversed = {}

    for i = #tbl, 1, -1 do
        table.insert(reversed, tbl[i])
    end

    return reversed
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[ 
    getTableMaxValueAndIndex: Returns the largest element of a table and its index
    @arg1: table [Table]
    @arg2: elementIndex [Integer]
	@return1: Largest value within the table [Var]
	@return2: Index containing the largest value [Int]
--]]
function M.getTableMaxValueAndIndex(tbl, elementIndex)
    if #tbl == 0 then
        return nil, nil
    end

    local maxIndex, maxValue = 1, tbl[1][elementIndex]
    for i = 2, #tbl do
        local val = tbl[i][elementIndex]
        if val > maxValue then
            maxValue, maxIndex = val, i
        end
    end

    return maxValue, maxIndex
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[ 
    getMapElementCount: Deletes regions based on indices
	@arg1: Map [Table (Dictionary)]
	@return1: elementCount [Integer]
--]]
function M.getMapElementCount(map)
    local count = 0
    for _ in pairs(map) do
        count = count + 1
    end
    return count
end

return M
