-- @noindex
local M = {}

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    getExtStateValue: Checks a stored ExtState value and returns it, returns a default value if original return was nil
    @arg1: extStateID [String]
    @arg2: valueID [String]
    @arg3: default [Float]
    @return1: stored value or defaultValue [Number]
--]]
function M.getExtStateValue(extStateID, valueID, defaultValue)
    return tonumber(reaper.GetExtState(extStateID, valueID)) or defaultValue
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    getExtStateValueStr: Checks a stored ExtState value and returns it as a string, returns a default value if original return was nil
    @arg1: extStateID [String]
    @arg2: valueID [String]
    @arg3: default [String]
    @return1: stored value or defaultValue [String]
--]]
function M.getExtStateValueStr(extStateID, valueID, defaultValue)
    return reaper.GetExtState(extStateID, valueID) or defaultValue
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    getExtStateValueBool:
    @arg1: extStateID [String]
    @arg2: valueID [String]
    @arg3: default [Bool]
    @return1: stored value or defaultValue [Bool]
--]]
function M.getExtStateValueBool(extStateID, valueID, defaultValue)
    local value = reaper.GetExtState(extStateID, valueID)

    if value == "" then
        return defaultValue
    end

    -- Backwards comp
    if value == "1" then 
        return true
    elseif value == "0" then
        return false
    end

    return value == "true"
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    saveExtStateValue:
    @arg1: extStateID [String]
    @arg2: valueID [String]
    @arg3: DataType [String]
    @arg4: default [String]
--]]
function M.saveExtStateValue(extStateID, valueID, dataType, value)
    if dataType ~= "STRING" then
        value = tostring(value)
    end

    reaper.SetExtState(extStateID, valueID, value, true)
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    getProjExtStateValue: Checks a stored ExtState value and returns it, returns a default value if original return was nil
    @arg1: Project [Integer]
    @arg2: extStateID [String]
    @arg3: valueID [String]
    @arg4: default [Any]
    @return1: stored value or defaultValue [Float]
--]]
function M.getProjExtStateValue(proj, extStateID, valueID, defaultValue)
    return tonumber(select(2, reaper.GetProjExtState(proj, extStateID, valueID))) or defaultValue
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
    local currentState = M.getExtStateValueBool(productName, actionExtStateName, false)

    if currentState == nil then
        currentState = false
    end

    local newState = (currentState == false) and 1 or 0

    reaper.SetExtState(productName, actionExtStateName, tostring(newState == 1), true)
    reaper.SetExtState(productName, actionExtStateName .. "ToggleCmdID", tostring(cmdID), true)
    reaper.SetToggleCommandState(sectionID, cmdID, newState)
    reaper.RefreshToolbar2(sectionID, cmdID)

    reaper.SetExtState(productName, "LastSettingsUpdate", tostring(os.clock()), false)

    return newState
end

return M
