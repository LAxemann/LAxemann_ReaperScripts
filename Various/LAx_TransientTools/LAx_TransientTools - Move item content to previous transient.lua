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
local transients = require("LAx_Shared_Transients")
local utility = require("LAx_Shared_Utility")

if not utility.checkRequiredExtensions("LAx_TransientTools", { "JS_VKeys_GetState", "CF_GetSWSVersion" }) then
    return
end

----------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
local selectedItemCount = reaper.CountSelectedMediaItems(0)

if selectedItemCount == 0 then
    return
end

for i = 0, selectedItemCount - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)

    if item then
        transients.moveItemContentToNextTransient(item, -1)
    end
end
