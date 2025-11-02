-- @noindex

local M = {}

local extState = require("LAx_Shared_ExtState")

M.settingsTypes = {
    number = "NUMBER",
    bool = "BOOL",
    string = "STRING"
}

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    addSetting:
    @arg1: SettingsTable [Table]
    @arg2: ExtStateID [String]
    @arg3: SettingsName [String]
    @arg4: SettingsType [String]
    @arg5: DefaultValue [Any]
    @arg6: IsToggle [Bool] (Optional)
    @return1: Success [Bool]
    @return2: Settings Table Segment [Table]
--]]
function M.addSetting(settingsTable, extStateID, settingsName, settingsType, defaultValue, isToggle)
    local value

    if settingsType == M.settingsTypes.number then
        value = extState.getExtStateValue(extStateID, settingsName, defaultValue)
    elseif settingsType == M.settingsTypes.bool then
        value = extState.getExtStateValueBool(extStateID, settingsName, defaultValue)
    elseif settingsType == M.settingsTypes.string then
        value = extState.getExtStateValueStr(extStateID, settingsName, defaultValue)
    else
        msg("Error: Invalid data type for setting " .. settingsName .. "\n")
        return false, {}
    end

    settingsTable[settingsName] = {
        type = settingsType,
        storedSetting = value,
        runtimeSetting = value,
        defaultValue = defaultValue,
        isToggle = isToggle and true or false
    }

    return true, settingsTable[settingsName]
end

----------------------------------------------------------------------------------------
--[[
    applyToggle: Checks if a toggle function command ID is stored. Triggers the command if yes, simply sets the new value if not
    @arg1: extStateString [String]
    @arg2: originalValue [String]
    @arg3: newValue [Float/Int]
	@arg4: cmdID [String]
--]]
function M.applyToggle(extStateString, originalValue, newValue)
    if tonumber(originalValue) ~= newValue then
        local cmdID = extState.getExtStateValue(LAx_ProductData.name, extStateString .. "ToggleCmdID", -1)

        local commandID = reaper.NamedCommandLookup(cmdID)
        if commandID ~= 0 then
            reaper.Main_OnCommand(commandID, 0)
        end
    else
        reaper.SetExtState(LAx_ProductData.name, extStateString, tostring(newValue), true)
    end
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    wereSettingsUpdated: Checks whether or not settings were changed by comparing "starting" and "current" settings
	@return1: Settings were change [Bool]
--]]
function M.wereSettingsUpdated(settingsTable)
    for _, settingData in pairs(settingsTable) do
        if settingData.storedSetting ~= settingData.runtimeSetting then
            return true
        end
    end

    return false
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    saveSettings: Sets stored settings to runtime settings and saves to ExtState
	@arg1: SettingsTable [Table]
	@arg2: ExtStateID [String]
--]]
function M.saveSettings(settingsTable, extStateID)
    for settingName, settingData in pairs(settingsTable) do
        if settingData.isToggle then
            M.applyToggle(settingName, settingData.storedSetting, settingData.runtimeSetting)
        end

        settingData.storedSetting = settingData.runtimeSetting
        extState.saveExtStateValue(extStateID, settingName, settingData.type, settingData.runtimeSetting)
    end
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    restoreDefaults: Restores default values but does not save to extState
	@arg1: SettingsTable [Table]
--]]
function M.restoreDefaults(settingsTable)
    for _, settingData in pairs(settingsTable) do
        settingData.runtimeSetting = settingData.defaultValue
    end
end

return M
