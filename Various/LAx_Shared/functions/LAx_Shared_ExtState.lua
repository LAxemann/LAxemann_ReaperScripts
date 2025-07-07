-- @noindex
local M = {}

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[ 
    getExtStateValue: Checks a stored ExtState value and returns it, returns a default value if original return was nil
    @arg1: extStateID [String]
    @arg2: valueID [String]
    @arg3: default [Any]
    Returns: stored value or defaultValue
--]]
function M.getExtStateValue(extStateID, valueID, defaultValue)
    return tonumber(reaper.GetExtState(extStateID, valueID)) or defaultValue
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[ 
    toggleCommand: Toggles the toggle command state of an action and updates ExtState values
    @arg1: productName [String]
    @arg2: actionExtStateName [String]
    @return1: NewState [Integer]
--]]
function M.toggleCommand(productName, actionExtStateName, sectionID, cmdID)
    local currentState = tonumber(reaper.GetExtState(productName, actionExtStateName))

    if currentState == nil then
        currentState = 0
    end

    local newState = ((currentState == 0) and 1) or 0

    reaper.SetExtState(productName, actionExtStateName, newState, true)
    reaper.SetExtState(productName, actionExtStateName .. "ToggleCmdID", tostring(cmdID), true)
    reaper.SetToggleCommandState(sectionID, cmdID, newState)
    reaper.RefreshToolbar2(sectionID, cmdID)

    reaper.SetExtState(productName, "LastSettingsUpdate", tostring(os.clock()), false)

    return newState
end

return M
