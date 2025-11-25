-- @noindex

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
		take = reaper.GetMediaItemTake(item, 0)

		if take then
			reaper.SetMediaItemTake_Source(take, source)
			reaper.UpdateItemInProject(item)
		end
	end
end

reaper.UpdateArrange()
reaper.UpdateTimeline()
