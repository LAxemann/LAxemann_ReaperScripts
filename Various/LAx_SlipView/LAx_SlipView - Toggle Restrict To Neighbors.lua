-- @noindex


local _, _, sectionID, cmdID = reaper.get_action_context()

local currentState = tonumber(reaper.GetExtState("LAx_SlipView", "RestrictToNeighbors"))

if currentState == nil then
	currentState = 0
end

local newState = ((currentState == 0) and 1) or 0

reaper.SetExtState("LAx_SlipView", "RestrictToNeighbors", newState, true)
reaper.SetExtState("LAx_SlipView", "RestrictToNeighborsToggleCmdID", tostring(cmdID), true)
reaper.SetToggleCommandState(sectionID, cmdID, newState)
reaper.RefreshToolbar2(sectionID, cmdID)