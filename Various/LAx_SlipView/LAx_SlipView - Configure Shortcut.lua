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

msg(
    "\n\nLAx_SlipView shortcut configuration:\nPlease press the desired shortcut (up to two keys).\nIn order to cancel, press the ESC key.\n\n")

local madePrimaryChoice = false
local primaryKey = -1
local modifierKey = -1

function confirmChoice(primaryKey, modifierKey)
    local primaryKeyName = utility.getKeyNameFromDecimal(primaryKey)
    if primaryKeyName ~= "" then
        primaryKeyName = " [" .. primaryKeyName .. "]"
    end

    local modifierKeyName = utility.getKeyNameFromDecimal(modifierKey)
    if modifierKeyName ~= "" then
        modifierKeyName = " [" .. modifierKeyName .. "]"
    end

    local modifierString = (modifierKey ~= -1 and tostring(modifierKey)) or "None"
    local answer = reaper.MB(
        "Primary key will be set to: " .. tonumber(primaryKey) .. primaryKeyName .."\nModifier key will be set to: " .. modifierString .. modifierKeyName ..
            "\n\nPress OK to confirm or Cancel to discard.", "LAx_SlipView: Confirm Shortcut", 1)
    if answer == 1 then
        reaper.SetExtState("LAx_SlipView", "PrimaryKey", tostring(primaryKey), true)
        modifierString = (modifierKey == -1 and "") or tostring(modifierKey)
        reaper.SetExtState("LAx_SlipView", "ModifierKey", modifierString, true)
        msg("Shortcut saved successfully!\n\n")

        -- Update save time
        reaper.SetExtState("LAx_SlipView", "LastSettingsUpdate", tostring(os.clock()), false)
    else
        msg("Changes discarded.")
    end
end

function main()
    local keyState = reaper.JS_VKeys_GetState(0)

    for i = 1, 255 do
        if keyState:byte(i) ~= 0 then
            -- Abort if ESC was pressed
            if i == 27 then
                msg("Cancelled setting the SlipView shortcut.")
                return
            end

            if not madePrimaryChoice then
                primaryKey = i
                madePrimaryChoice = true
            else
                if i ~= primaryKey then
                    modifierKey = i
                    confirmChoice(primaryKey, modifierKey)
                    return
                end
            end
        else
            if i == primaryKey then
                confirmChoice(primaryKey, modifierKey)
                return
            end
        end
    end

    reaper.defer(main)
end

main()
