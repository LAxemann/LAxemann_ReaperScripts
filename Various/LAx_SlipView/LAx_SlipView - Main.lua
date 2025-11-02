-- @description Allows it to display the full waveform of one or multiple selected items when pressing a (bindable) key.
-- @author Leon 'LAxemann' Beilmann
-- @version 1.50
-- @about
--   # About
--   SlipView allows it to display the full waveform of one or multiple selected items when pressing a (bindable) key.
--   This was meant with Slip Editing (using ALT to move the contents of an item without moving the item itself) in mind,
--   Key features:
--   - Shows the full waveform of a selected media item when pressing a (bindable) key or key combination.
--   - The waveform preview will be created relative to the media item for quick orientation within the waveform.
--   - It can be set so that the preview will either stop at neighboring items or ignore them.
--   - If things get too cluttered, the preview can be created on an entirely new track.
--   - If the timeline or a neighboring item is in the way in either direction, it'll compensate towards the other direction.
--   - A "snap to transient" mode, including previewing the next transient(s) is available.
--   - Supports multiple items VERTICALLY: The first selected item of each track will have its preview shown.
--   - Supports multiple takes on one item. The selected take will have its preview shown.
--   - An activation delay can be set; Only if the keys are pressed longer than the delay the waveform preview will show up.
--   - The previews will automatically update if the selected items or takes change.
--
--  # Requirements
--  JS_ReaScriptAPI, SWS Extension
-- @links
--  Website https://www.youtube.com/@LAxemann
-- @provides
--   [main] LAx_SlipView - Settings.lua
--   [main] LAx_SlipView - Toggle On New Track.lua
--   [main] LAx_SlipView - Toggle Restrict To Neighbors.lua
--   [main] LAx_SlipView - Configure Shortcut.lua
--   [main] LAx_SlipView - Toggle Snap To Transients.lua
--   [main] LAx_SlipView - Toggle Show Transient Guides.lua
--   [nomain] ReadMe.txt
--   [nomain] Changelog.txt
--   [nomain] runShared.lua
--   [nomain] c_GState.lua
--   [nomain] c_GhostTracks.lua
--   [nomain] c_GhostTrack.lua
--   [nomain] c_GhostItems.lua
--   [nomain] c_GhostItem.lua
--   [data] toolbar_icons/**/*.png
--[[
 * Changelog:
    * v1.50
      + Added: "Restore Defaults" to Settings
      + Added: Style menu to Settings
      + Tweaked: Preview items will now adapt to on-the-fly length and playRate changes
      + Tweaked: Under-the-hood changes to how settings work
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
local utility = require("LAx_Shared_Utility")

if not utility.checkRequiredExtensions("LAx_SplipView", { "JS_VKeys_GetState", "CF_GetSWSVersion" }) then
    return
end

runFile(currentFolder .. "c_GhostItem", true)
runFile(currentFolder .. "c_GhostItems", true)
runFile(currentFolder .. "c_GhostTrack", true)
runFile(currentFolder .. "c_GhostTracks", true)
runFile(currentFolder .. "c_GState", true)

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    versionCheck: Displays information on new version
--]]
function versionCheck(versionNumber)
    if extState.getExtStateValue("LAx_SlipView", "LastUsedVersion", 0) < versionNumber then
        if extState.getExtStateValue("LAx_SlipView", "PrimaryKey", 0) ~= 0 then
            local answer = reaper.ShowMessageBox(
                "SlipView was updated to v1.30!\n\nNew main features:\n- Transient snap capability (Optional)\n" ..
                "- A new action for easy setting of the shortcut\n- New toolbar icons\n- An extensive code rewrite\n" ..
                "Make sure to check out and set up the new actions.\n\nWould you like to watch a quick video going over the new stuff?",
                "LAx_SlipView: Info", 4)

            if answer == 6 then
                utility.openURL("https://youtu.be/31Oj43tAEY0")
            end
        end
    end
    reaper.SetExtState("LAx_SlipView", "LastUsedVersion", tostring(versionNumber), true)
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    setToggleFunctionsToggleState: Sets toggle state of toggle actions if they've been registered
--]]
function setToggleFunctionsToggleState()
    utility.toggleCommandState("LAx_SlipView", "CreateGhostTrack")
    utility.toggleCommandState("LAx_SlipView", "RestrictToNeighbors")
    utility.toggleCommandState("LAx_SlipView", "SnapToTransients")
    utility.toggleCommandState("LAx_SlipView", "ShowTransientGuides")
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    setToggleStatee: Sets a toggle state
--]]
function setToggleState(state)
    local _, _, sectionID, cmdID = reaper.get_action_context()
    reaper.SetToggleCommandState(sectionID, cmdID, state or 0)
    reaper.RefreshToolbar2(sectionID, cmdID)
end

----------------------------------------------------------------------------------------
versionCheck(150)

-- Create + init GhostItem, GhostTracks and GlobalState "objects"
GhostItems = GhostItems.new()
GhostItems:init()

GhostTracks = GhostTracks.new()
GhostTracks:init()

State = GState.new()
State:init(GhostItems, GhostTracks)

----------------------------------------------------------------------------------------
-- Main loop
function main()
    State:mainRoutine()
    reaper.defer(main)
end

-- Run main routine
setToggleFunctionsToggleState()
setToggleState(1)
main()
reaper.atexit(setToggleState)
