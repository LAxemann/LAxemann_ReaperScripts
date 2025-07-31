-- @description LAx_TransientTools
-- @author Leon 'LAxemann' Beilmann
-- @version 1.00
-- @about
--   # About
--   Simple scripts for transient-based workflows
--
--  # Requirements
--  JS_ReaScriptAPI, SWS Extension
-- @links
--  Website https://www.youtube.com/@LAxemann
-- @provides
--   [main] LAx_TransientTools - Move item content to previous transient.lua
--   [nomain] runShared.lua
--[[
 * Changelog:
    * v1.00
      + Initial release
]] ----------------------------------------------------------------------------------------
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
        transients.moveItemContentToNextTransient(item, 1)
    end
end
