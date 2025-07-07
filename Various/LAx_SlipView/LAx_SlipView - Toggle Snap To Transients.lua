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

----------------------------------------------------------------------------------------
local _, _, sectionID, cmdID = reaper.get_action_context()
extState.toggleCommand("LAx_SlipView", "SnapToTransients", sectionID, cmdID)

-- Update save time
reaper.SetExtState("LAx_SlipView", "LastSettingsUpdate", tostring(os.clock()), false)