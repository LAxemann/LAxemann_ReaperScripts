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

if reaper.CountSelectedTracks(0) == 0 then
    return
end

local itemCount = reaper.CountMediaItems(0)

if itemCount == 0 then
    return
end

local cursorPos = reaper.GetCursorPosition()
local firstTrack = reaper.GetSelectedTrack(0, 0)
local firstTrackNumber = reaper.GetMediaTrackInfo_Value(firstTrack, "IP_TRACKNUMBER")

local itemsToSplit = {}

for i = 1, itemCount do
    local item = reaper.GetMediaItem(0, i - 1)
    local itemTrack = reaper.GetMediaItemTrack(item)

    if reaper.GetMediaTrackInfo_Value(itemTrack, "IP_TRACKNUMBER") >= firstTrackNumber then
        if item ~= nil then
            local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

            if pos < cursorPos and pos + length > cursorPos then
                itemsToSplit[item] = true
            end
        end
    end
end

reaper.Undo_BeginBlock()
for item, v in pairs(itemsToSplit) do
    reaper.SplitMediaItem(item, cursorPos)
end
reaper.Undo_EndBlock("Split all items below selected track at edit cursor", -1)

reaper.UpdateArrange()
