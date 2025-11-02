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
local utility = require("LAx_Shared_Utility")
local settings = require("LAx_Shared_Settings")
local styles = require("LAx_Shared_Styles")

if not utility.checkRequiredExtensions("LAx_SplipView", { "JS_VKeys_GetState", "CF_GetSWSVersion", "ImGui_GetVersion" }) then
    return
end

-- Add settings
local settingsData = {}
local _, primaryKey = settings.addSetting(settingsData, LAx_ProductData.name, "PrimaryKey", settings.settingsTypes
    .number, 18)
local _, modifierKey = settings.addSetting(settingsData, LAx_ProductData.name, "ModifierKey",
    settings.settingsTypes.number, "")
local _, delay = settings.addSetting(settingsData, LAx_ProductData.name, "Delay", settings.settingsTypes.number, 0)
local _, restrictToNeighbors = settings.addSetting(settingsData, LAx_ProductData.name, "RestrictToNeighbors",
    settings.settingsTypes.bool, true, true)
local _, createGhostTrack = settings.addSetting(settingsData, LAx_ProductData.name, "CreateGhostTrack",
    settings.settingsTypes.bool, false, true)
local _, showOnlyOnDrag = settings.addSetting(settingsData, LAx_ProductData.name, "ShowOnlyOnDrag",
    settings.settingsTypes.bool, false)
local _, snapToTransients = settings.addSetting(settingsData, LAx_ProductData.name, "SnapToTransients",
    settings.settingsTypes.bool, false, true)
local _, showTransientGuides = settings.addSetting(settingsData, LAx_ProductData.name, "ShowTransientGuides",
    settings.settingsTypes.bool, false, true)
local _, dontDisableAutoCF = settings.addSetting(settingsData, LAx_ProductData.name, "DontDisableAutoCF",
    settings.settingsTypes.bool, false)
local _, showTakeMarkers = settings.addSetting(settingsData, LAx_ProductData.name, "ShowTakeMarkers",
    settings.settingsTypes.bool, true)

local primaryKeyChoice = nil

-- ImGui init
package.path = package.path .. ";" .. reaper.ImGui_GetBuiltinPath() .. '/?.lua'
ImGui = require 'imgui' '0.10'

-- Menu ctx init
local ctx = ImGui.CreateContext('My script')
local windowName = LAx_ProductData.name .. " Settings"
local baseWindowFlags = ImGui.WindowFlags_NoResize | ImGui.WindowFlags_NoCollapse | ImGui.WindowFlags_AlwaysAutoResize |
ImGui.WindowFlags_MenuBar
local guiW = 280
local guiH = 340
local isSettingShortcut = true
local madePrimaryChoice = false

-- Style object
local styleObject = styles.createStyleObject()

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    handleShortcutSetting: Checks whether or not settings were changed by comparing "starting" and "current" settings
	@return1: Settings were change [Bool]
--]]
function handleShortcutSetting()
    local keyState = reaper.JS_VKeys_GetState(0)

    for i = 1, 255 do
        if keyState:byte(i) ~= 0 then
            -- Abort if ESC was pressed
            if i == 27 then
                return false
            end

            if not madePrimaryChoice then
                primaryKeyChoice = i
                primaryKey.runtimeSetting = i
                madePrimaryChoice = true
            else
                if i ~= primaryKeyChoice then
                    modifierKey.runtimeSetting = i
                    return false
                end
            end
        else
            if i == primaryKeyChoice then
                modifierKey.runtimeSetting = ""
                return false
            end
        end
    end

    return true
end

----------------------------------------------------------------------------------------
--[[
    guiLoop: Main gui loop/defer function
--]]
function guiLoop()
    local doPopFont, styleVarCount, styleColorCount, styleName = styles.applyVarsAndStyles(ctx, styleObject)
    local windowFlags = baseWindowFlags
    local settingsWereUpdated = settings.wereSettingsUpdated(settingsData)

    if settingsWereUpdated then
        windowFlags = windowFlags | ImGui.WindowFlags_UnsavedDocument
    end

    ImGui.SetNextWindowSize(ctx, guiW, guiH, ImGui.Cond_Once)
    local guiIsVisible, guiIsOpen = ImGui.Begin(ctx, windowName, true, windowFlags)

    if guiIsVisible then
        -- Menu bar
        if ImGui.BeginMenuBar(ctx) then
            if ImGui.MenuItem(ctx, "Options##optionsButton") then
                ImGui.OpenPopup(ctx, 'OptionsMenu')
            end

            if ImGui.BeginPopup(ctx, 'OptionsMenu', ImGui.WindowFlags_AlwaysAutoResize) then
                if ImGui.MenuItem(ctx, 'Restore defaults') then
                    settings.restoreDefaults(settingsData)
                end

                styles.addStyleMenu(ctx, styleObject)

                ImGui.EndPopup(ctx)
            end

            ImGui.EndMenuBar(ctx)
        end

        -- Shortcut setting
        ImGui.SeparatorText(ctx, "Shortcut")

        if ImGui.Button(ctx, utility.getKeyNameFromDecimal(primaryKey.runtimeSetting, true) .. (modifierKey.runtimeSetting ~= "" and " + " or "") .. utility.getKeyNameFromDecimal(modifierKey.runtimeSetting, true)) then
            ImGui.OpenPopup(ctx, 'Set shortcut')
        end
        ImGui.SetItemTooltip(ctx, 'Click to assign SlipView\'s shortcut.\nNote: Both "Windows" keys WILL cause trouble.')

        local center_x, center_y = ImGui.Viewport_GetCenter(ImGui.GetWindowViewport(ctx))
        ImGui.SetNextWindowPos(ctx, center_x, center_y, ImGui.Cond_Appearing, 0.5, 0.5)
        if ImGui.BeginPopupModal(ctx, 'Set shortcut', nil, ImGui.WindowFlags_AlwaysAutoResize) then
            isSettingShortcut = handleShortcutSetting()

            if not isSettingShortcut then
                ImGui.CloseCurrentPopup(ctx)
                isSettingShortcut = true
                madePrimaryChoice = false
                primaryKeyChoice = nil
            else
                ImGui.Text(ctx,
                    'Please press the desired shortcut (up to two keys).\nIn order to cancel, press the ESC key or click "Cancel"')

                if ImGui.Button(ctx, 'Cancel', 120, 0) then
                    ImGui.CloseCurrentPopup(ctx)
                    isSettingShortcut = true
                    madePrimaryChoice = false
                    primaryKeyChoice = nil
                end
            end

            ImGui.SetItemDefaultFocus(ctx)
            ImGui.EndPopup(ctx)
        end

        ImGui.SeparatorText(ctx, "Settings")

        -- Bools
        _, restrictToNeighbors.runtimeSetting = ImGui.Checkbox(ctx, "Restrict to neighbors",
            restrictToNeighbors.runtimeSetting)
        ImGui.SetItemTooltip(ctx, 'If checked, the preview item will "stop" at the next item in each direction.')

        _, createGhostTrack.runtimeSetting = ImGui.Checkbox(ctx, "Create previews on new tracks",
            createGhostTrack.runtimeSetting)
        ImGui.SetItemTooltip(ctx, 'If checked, the preview item will be created on a new, temporary track.')

        _, showOnlyOnDrag.runtimeSetting = ImGui.Checkbox(ctx, "Show preview only when dragging",
            showOnlyOnDrag.runtimeSetting)
        ImGui.SetItemTooltip(ctx,
            'If checked, the preview item will only appear once you actually start dragging the (clicked) mouse.')

        _, snapToTransients.runtimeSetting = ImGui.Checkbox(ctx, "Snap to transients", snapToTransients.runtimeSetting)
        ImGui.SetItemTooltip(ctx,
            'If checked, the items will snap to transients.\nNote: Transient detection can be adjusted with Reaper\'s own settings.')
        ImGui.SameLine(ctx)
        if ImGui.Button(ctx, 'Settings##transients') then
            reaper.Main_OnCommand(41208, 0) -- Transient detection sensitivity/threshold: Adjust...
        end
        ImGui.SetItemTooltip(ctx,
            'Opens Reaper\'s default transient detection settings.\n(Command name: Transient detection sensitivity/threshold: Adjust...)')

        _, showTransientGuides.runtimeSetting = ImGui.Checkbox(ctx, "Show transient guides",
            showTransientGuides.runtimeSetting)
        ImGui.SetItemTooltip(ctx,
            'If checked, Reaper will calculate "transient guides" for the preview item.\nNote: May take a while.')

        _, showTakeMarkers.runtimeSetting = ImGui.Checkbox(ctx, "Show take markers", showTakeMarkers.runtimeSetting)
        ImGui.SetItemTooltip(ctx,
            'If checked, SlipView will show take markers in the preview item.')

        _, dontDisableAutoCF.runtimeSetting = ImGui.Checkbox(ctx, "Don't disable auto-crossfade",
            dontDisableAutoCF.runtimeSetting)
        ImGui.SetItemTooltip(ctx,
            'NOTE: Not recommended!\nIf checked, SlipView will not temporarily disable auto-crossfade.')

        -- Ints
        ImGui.SetNextItemWidth(ctx, 130)
        _, delay.runtimeSetting = ImGui.InputDouble(ctx, "Delay", math.max(delay.runtimeSetting, 0), 0.25, 0.75, "%.2f s")
        ImGui.SetItemTooltip(ctx, 'How long the shortcut needs to be held before previews appear.')

        -- Save button
        if settingsWereUpdated then
            ImGui.NewLine(ctx)
            if ImGui.Button(ctx, 'Save changes') then
                settings.saveSettings(settingsData, LAx_ProductData.name)

                -- Update save time
                reaper.SetExtState(LAx_ProductData.name, "LastSettingsUpdate", tostring(os.clock()), false)
            end
        end

        if settingsWereUpdated then
            ImGui.SameLine(ctx)
            if ImGui.GetTime(ctx) % 0.40 < 0.20 then
                ImGui.Text(ctx, 'Unsaved changes')
            end
        end

        styles.popVarsAndStyles(ctx, doPopFont, styleVarCount, styleColorCount)
        ImGui.End(ctx)
    end

    -- Run loop while window is considered open
    if guiIsOpen then
        reaper.defer(guiLoop)
    end
end

guiLoop()
