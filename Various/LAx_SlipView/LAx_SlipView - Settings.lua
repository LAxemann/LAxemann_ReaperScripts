-- @noindex


----------------------------------------------------------------------------------------
--[[ 
    checkStoredValue: Checks a stored ExtState value and returns it, returns a default value if original return was nil
    @arg1: valueID [String]
    @arg2: default [Any]
    Returns: stored value or nil
--]]
function checkStoredValue(valueID, defaultValue)
	local returnValue = tonumber(reaper.GetExtState("LAx_SlipView", valueID))
	
	if returnValue == nil then
		returnValue = defaultValue
	end
	
	return returnValue
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
		if createGhostTrackToggleCmdID ~= "" then
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
local primaryKey = checkStoredValue("PrimaryKey", 18)
local modifierKey = checkStoredValue("ModifierKey", "")
local restrictToNeighbors = checkStoredValue("RestrictToNeighbors", 0)
local restrictToNeighborsToggleCmdID = checkStoredValue("RestrictToNeighborsToggleCmdID", "")
local createGhostTrack = checkStoredValue("CreateGhostTrack", 0)
local createGhostTrackToggleCmdID = checkStoredValue("CreateGhostTrackToggleCmdID", "")
local showOnlyOnDrag = checkStoredValue("ShowOnlyOnDrag", 0)
local delay = checkStoredValue("Delay", 0)

-- Open our humble UI
local ret, userInput = reaper.GetUserInputs("SlipView settings", 6, "Primary Key (VK Code),Modifier Key (VK Code or empty),Restrict to neighbors,On new track (0 = no),Only when dragging content,Delay (s)", primaryKey .. "," .. modifierKey .. "," .. restrictToNeighbors .. "," .. createGhostTrack .. "," .. showOnlyOnDrag .. "," .. delay)

if ret then
    -- Parse the input
    local primary_key, modifier_key, restrict_to_neighbors, create_ghost_track, show_only_on_drag, delay = userInput:match("([^,]*),([^,]*),([01]),([01]),([01]),([^,]*)")
    primary_key = tonumber(primary_key)
    modifier_key = tonumber(modifier_key)
    restrict_to_neighbors = tonumber(restrict_to_neighbors) 
    create_ghost_track = tonumber(create_ghost_track)
    show_only_on_drag = tonumber(show_only_on_drag)
	delay = tonumber(delay)

    if primary_key then
        -- Save the keybinding in ExtState
        reaper.SetExtState("LAx_SlipView", "PrimaryKey", tostring(primary_key), true)
        reaper.SetExtState("LAx_SlipView", "ModifierKey", tostring(modifier_key or ""), true)
		applyToggle("RestrictToNeighbors", restrictToNeighbors, restrict_to_neighbors, restrictToNeighborsToggleCmdID)
		applyToggle("CreateGhostTrack", createGhostTrack, create_ghost_track, createGhostTrackToggleCmdID)
		reaper.SetExtState("LAx_SlipView", "ShowOnlyOnDrag", tostring(show_only_on_drag), true)
		reaper.SetExtState("LAx_SlipView", "Delay", tostring(delay), true)
		
        reaper.ShowMessageBox("Settings saved successfully!\nNote: Keybinding changes require a restart of the main script!", "Info", 0)
    else
        reaper.ShowMessageBox("Invalid input!", "Error", 0)
    end
end



