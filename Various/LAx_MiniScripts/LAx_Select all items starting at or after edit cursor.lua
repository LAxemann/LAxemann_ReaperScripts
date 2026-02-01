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

local cursorPos = reaper.GetCursorPosition()

local itemCount = reaper.CountMediaItems(0)

if itemCount == 0 then
    return
end

reaper.Undo_BeginBlock()
for i = 1, itemCount do
    local item = reaper.GetMediaItem(0, i - 1)

    if item ~= nil then
        local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

        if pos >= cursorPos then
            reaper.SetMediaItemSelected(item, true)
        end
    end
end
reaper.Undo_EndBlock("Select all items starting at or after edit cursor", -1)

reaper.UpdateArrange()
