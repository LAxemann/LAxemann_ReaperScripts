-- @noindex

local M = {}

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[ 
    getRandomColor: Generates a random color
	@return1: Color [Color]
--]]
function M.getRandomColor()
    local red = math.random(0, 255)
    local green = math.random(0, 255)
    local blue = math.random(0, 255)

    local color = (1 << 24) + (red << 16) + (green << 8) + blue
    return color
end


----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[ 
    darkenColor: Darkens an existing color by a factor
    @arg1: Color [Color]
    @arg2: Factor [Float]
	@return1: Color [Color]
--]]
function M.darkenColor(color, factor)
    if color == 0 then return 0 end 

    local r = (color & 0xFF)
    local g = (color >> 8) & 0xFF
    local b = (color >> 16) & 0xFF

    -- Multiply each channel and clamp between 0 and 255
    r = math.min(255, math.max(0, math.floor(r * factor)))
    g = math.min(255, math.max(0, math.floor(g * factor)))
    b = math.min(255, math.max(0, math.floor(b * factor)))

    return (b << 16) | (g << 8) | r | 0x1000000
end


----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[ 
    getItemOrTrackCustomColor: Gets the item's color if it has a custom color, otherwise uses the track's
    @arg1: item [Item]
    @arg2: track [Track]
	@return1: Color [Color]
--]]
function M.getItemOrTrackCustomColor(item, track)
    local itemColor = reaper.GetMediaItemInfo_Value(item, "I_CUSTOMCOLOR")

    return itemColor ~= 0 and itemColor or reaper.GetMediaTrackInfo_Value(track, "I_CUSTOMCOLOR")
end

return M