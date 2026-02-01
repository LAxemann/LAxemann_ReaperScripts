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

local selectedItemCount = reaper.CountSelectedMediaItems(0)

if selectedItemCount == 0 then
	return
end

local retVal, fileName = reaper.MediaExplorerGetLastPlayedFileInfo()

if not retVal or fileName == "" then
	return
end

local source = reaper.PCM_Source_CreateFromFile(fileName)

for i = 0, selectedItemCount - 1 do
	local item = reaper.GetSelectedMediaItem(0, i)

	if item then
		local take = reaper.GetMediaItemTake(item, 0)

		if take then
			reaper.SetMediaItemTake_Source(take, source)
			reaper.UpdateItemInProject(item)
		end
	end
end

reaper.Main_OnCommand(40047, 0)
reaper.UpdateArrange()
reaper.UpdateTimeline()
