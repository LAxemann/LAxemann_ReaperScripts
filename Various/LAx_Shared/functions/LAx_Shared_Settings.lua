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
    @return1: Success [Bool]
    @return2: Settings Table Segment [Table]
--]]
function M.addSetting(settingsTable, extStateID, settingsName, settingsType, defaultValue)
    local value

    if settingsType == M.settingsTypes.number then
        value = extState.getExtStateValue(extStateID, settingsName, defaultValue)
    elseif settingsType == M.settingsTypes.bool then
        value = extState.getExtStateValueBool(extStateID, settingsName, defaultValue)
    elseif settingsType == M.settingsTypes.string then
        value = extState.getExtStateValueStr(extStateID, settingsName, defaultValue)
    else
        msg("Error: Invalid data type for setting " .. settingsName)
        return false, {}
    end

    settingsTable[settingsName] = {
        type = settingsType,
        storedSetting = value,
        runtimeSetting = value,
        defaultValue = defaultValue
    }

    return true, settingsTable[settingsName]
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
