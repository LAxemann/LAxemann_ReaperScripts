-- @noindex

--[[
    This version of the script can be assigned to a "scrollable" key such as the mousewheel.
    The transient detection will then depend on the scroll direction.
--]]

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
local transients = require("LAx_Shared_Transients")
local utility = require("LAx_Shared_Utility")
local extState = require("LAx_Shared_ExtState")

if not utility.checkRequiredExtensions("LAx_TransientTools", { "JS_VKeys_GetState", "CF_GetSWSVersion" }) then
    return
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
local newValue, _, _, _, _, _, val, contextStr = reaper.get_action_context()

if val == 0 or not newValue then
    return
end

if string.match(contextStr, "hwheel") then
    local scrollDelayMin = 0.15
    local lastScroll = tonumber(extState.getExtStateValue(LAx_ProductData.name, "LastScroll", "0"))

    if os.clock() - lastScroll < scrollDelayMin then
        return
    end

    reaper.SetExtState(LAx_ProductData.name, "LastScroll", tostring(os.clock()), false)
end

local selectedItemCount = reaper.CountSelectedMediaItems(0)

if selectedItemCount == 0 then
    return
end

local direction = val > 0 and 1 or -1

for i = 0, selectedItemCount - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)

    if item then
        transients.moveItemContentToNextTransient(item, direction)
    end
end
