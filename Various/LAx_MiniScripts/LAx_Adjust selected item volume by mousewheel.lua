-- @description LAx_MiniScripts
-- @author Leon 'LAxemann' Beilmann
-- @version 1.00
-- @about
--   # About
--   A collection of small scripts that usually 'stand on their own'.
--
--  # Requirements
--  JS_ReaScriptAPI, SWS Extension, ReaImGui
-- @links
--  Website https://www.youtube.com/@LAxemann
-- @provides
--   [main] LAx_Move stretch markers to nearest transients on selected items (In time selection if available).lua
--   [main] LAx_Replace source of all selected items with last previewed file.lua
--   [main] LAx_MiniScripts - Settings.lua
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
local extState = require("LAx_Shared_ExtState")

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
local newValue, _, _, _, _, _, val = reaper.get_action_context()

if val == 0 or not newValue then
	return
end

local VOL_MIN = extState.getExtStateValue(LAx_ProductData.name, "MouseWheelVolume_VolMin", 0)
local DB_CHANGE = extState.getExtStateValue(LAx_ProductData.name, "MouseWheelVolume_ChangeDB", 0.5)

local volMod = 0

if val > 0 then
	volMod = 10 ^ (DB_CHANGE / 20)
elseif val < 0 then
	volMod = 10 ^ (-DB_CHANGE / 20)
else
	return
end

local selectedItemCount = reaper.CountSelectedMediaItems(0)

if selectedItemCount == 0 then
	return
end

for i = 0, selectedItemCount - 1 do
	local item = reaper.GetSelectedMediaItem(0, i)

	if item then
		local previousVolume = reaper.GetMediaItemInfo_Value(item, "D_VOL")
		local newVolume = math.max(previousVolume * volMod, VOL_MIN)
		reaper.SetMediaItemInfo_Value(item, "D_VOL", newVolume)
	end
end

reaper.UpdateArrange()
