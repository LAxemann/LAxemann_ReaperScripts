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
-- Requirements
local extState = require("LAx_Shared_ExtState")
local utility = require("LAx_Shared_Utility")

reaper.ShowMessageBox("As of version 1.33, the shortcut can be comfortably configured via the main settings.\nThis script might be removed in a few versions.", "LAx_SlipView: Info", 0)

