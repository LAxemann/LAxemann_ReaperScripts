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

if not utility.checkRequiredExtensions("LAx_SplipView", {"JS_VKeys_GetState", "CF_GetSWSVersion"}) then
    return
end

----------------------------------------------------------------------------------------
--[[ 
    applyToggle: Checks if a toggle function command ID is stored. Triggers the command if yes, simply sets the new value if not
    @arg1: extStateString [String]
    @arg2: originalValue [String]
    @arg3: newValue [Float/Int]
	@arg4: cmdID [String]
--]]
function applyToggle(extStateString, originalValue, newValue, cmdID)
    if tonumber(originalValue) ~= newValue then
        if cmdID ~= "" then
            local commandID = reaper.NamedCommandLookup(cmdID)

            if commandID ~= 0 then
                reaper.Main_OnCommand(commandID, 0)
            end
        else
            reaper.SetExtState("LAx_SlipView", extStateString, tostring(newValue), true)
        end
    end
end

----------------------------------------------------------------------------------------
-- Check if values are already assigned
local primaryKey = extState.getExtStateValue("LAx_SlipView", "PrimaryKey", 18)
local modifierKey = extState.getExtStateValue("LAx_SlipView", "ModifierKey", "")
local restrictToNeighbors = extState.getExtStateValue("LAx_SlipView", "RestrictToNeighbors", 0)
local restrictToNeighborsToggleCmdID = extState.getExtStateValue("LAx_SlipView", "RestrictToNeighborsToggleCmdID", "")
local createGhostTrack = extState.getExtStateValue("LAx_SlipView", "CreateGhostTrack", 0)
local createGhostTrackToggleCmdID = extState.getExtStateValue("LAx_SlipView", "CreateGhostTrackToggleCmdID", "")
local showOnlyOnDrag = extState.getExtStateValue("LAx_SlipView", "ShowOnlyOnDrag", 0)
local delay = extState.getExtStateValue("LAx_SlipView", "Delay", 0)
local snapToTransients = extState.getExtStateValue("LAx_SlipView", "SnapToTransients", 0)
local snapToTransientsToggleCmdID = extState.getExtStateValue("LAx_SlipView", "SnapToTransientsToggleCmdID", "")
local showTransientGuides = extState.getExtStateValue("LAx_SlipView", "ShowTransientGuides", 0)
local showTransientGuidesToggleCmdID = extState.getExtStateValue("LAx_SlipView", "ShowTransientGuidesToggleCmdID", "")

-- Open our humble UI
local ret, userInput = reaper.GetUserInputs("SlipView settings", 8,
    "Primary Key (VK Code),Modifier Key (VK Code or empty),Restrict to neighbors (0=off),On new track (0=off),Only on content drag (0=off),Delay (s),Snap to transients (0=off),Show transient guides(0=off)",
    primaryKey .. "," .. modifierKey .. "," .. restrictToNeighbors .. "," .. createGhostTrack .. "," .. showOnlyOnDrag ..
        "," .. delay .. "," .. snapToTransients .. "," .. showTransientGuides)

if ret then
    -- Parse the input
    local primary_key, modifier_key, restrict_to_neighbors, create_ghost_track, show_only_on_drag, delay,
        snap_to_transients, show_transient_guides = userInput:match(
        "([^,]*),([^,]*),([01]),([01]),([01]),([^,]*),([01]),([01])")

    if primary_key then
        -- Save the keybinding in ExtState
        reaper.SetExtState("LAx_SlipView", "PrimaryKey", tostring(primary_key), true)
        reaper.SetExtState("LAx_SlipView", "ModifierKey", tostring(modifier_key or ""), true)
        applyToggle("RestrictToNeighbors", restrictToNeighbors, tonumber(restrict_to_neighbors),
            restrictToNeighborsToggleCmdID)
        applyToggle("CreateGhostTrack", createGhostTrack, tonumber(create_ghost_track), createGhostTrackToggleCmdID)
        reaper.SetExtState("LAx_SlipView", "ShowOnlyOnDrag", tostring(show_only_on_drag), true)
        reaper.SetExtState("LAx_SlipView", "Delay", tostring(delay), true)
        applyToggle("SnapToTransients", snapToTransients, tonumber(snap_to_transients), snapToTransientsToggleCmdID)
        applyToggle("ShowTransientGuides", showTransientGuides, tonumber(show_transient_guides),
            showTransientGuidesToggleCmdID)

        -- Update save time
        reaper.SetExtState("LAx_SlipView", "LastSettingsUpdate", tostring(os.clock()), false)

        -- Confirm
        reaper.ShowMessageBox("Settings saved successfully!", "LAx_SlipView info", 0)
    else
        reaper.ShowMessageBox("Invalid input!", "LAx_SlipView Error", 0)
    end
end

