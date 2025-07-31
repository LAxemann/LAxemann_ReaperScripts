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

if not utility.checkRequiredExtensions("LAx_SplipView", { "JS_VKeys_GetState", "CF_GetSWSVersion", "ImGui_GetVersion" }) then
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
            reaper.SetExtState(LAx_ProductData.name, extStateString, tostring(newValue), true)
        end
    end
end

-- Get settings
local primaryKey = extState.getExtStateValue(LAx_ProductData.name, "PrimaryKey", 18)
local modifierKey = extState.getExtStateValue(LAx_ProductData.name, "ModifierKey", "")
local restrictToNeighbors = extState.getExtStateValue(LAx_ProductData.name, "RestrictToNeighbors", 0) == 1
local restrictToNeighborsToggleCmdID = extState.getExtStateValue(LAx_ProductData.name, "RestrictToNeighborsToggleCmdID",
    "")
local createGhostTrack = extState.getExtStateValue(LAx_ProductData.name, "CreateGhostTrack", 0) == 1
local createGhostTrackToggleCmdID = extState.getExtStateValue(LAx_ProductData.name, "CreateGhostTrackToggleCmdID", "")
local showOnlyOnDrag = extState.getExtStateValue(LAx_ProductData.name, "ShowOnlyOnDrag", 0) == 1
local delay = extState.getExtStateValue(LAx_ProductData.name, "Delay", 0)
local snapToTransients = extState.getExtStateValue(LAx_ProductData.name, "SnapToTransients", 0) == 1
local snapToTransientsToggleCmdID = extState.getExtStateValue(LAx_ProductData.name, "SnapToTransientsToggleCmdID", "")
local showTransientGuides = extState.getExtStateValue(LAx_ProductData.name, "ShowTransientGuides", 0) == 1
local dontDisableAutoCF = extState.getExtStateValue(LAx_ProductData.name, "DontDisableAutoCF", 0) == 1
local showTransientGuidesToggleCmdID = extState.getExtStateValue(LAx_ProductData.name, "ShowTransientGuidesToggleCmdID",
    "")
local showTakeMarkers = extState.getExtStateValue(LAx_ProductData.name, "ShowTakeMarkers", 1) == 1

-- Transfer settings for comparison
local primaryKeyStart = primaryKey
local modifierKeyStart = modifierKey
local restrictToNeighborsStart = restrictToNeighbors
local createGhostTrackStart = createGhostTrack
local showOnlyOnDragStart = showOnlyOnDrag
local delayStart = delay
local snapToTransientsStart = snapToTransients
local showTransientGuidesStart = showTransientGuides
local dontDisableAutoCFStart = dontDisableAutoCF
local showTakeMarkersStart = showTakeMarkers
local primaryKeyChoice = nil

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    wereSettingsUpdated: Checks whether or not settings were changed by comparing "starting" and "current" settings
	@return1: Settings were change [Bool]
--]]
function wereSettingsUpdated()
    if primaryKeyStart ~= primaryKey then return true end
    if modifierKeyStart ~= modifierKey then return true end
    if restrictToNeighborsStart ~= restrictToNeighbors then return true end
    if createGhostTrackStart ~= createGhostTrack then return true end
    if showOnlyOnDragStart ~= showOnlyOnDrag then return true end
    if delayStart ~= delay then return true end
    if snapToTransientsStart ~= snapToTransients then return true end
    if showTransientGuidesStart ~= showTransientGuides then return true end
    if dontDisableAutoCFStart ~= dontDisableAutoCF then return true end
    if showTakeMarkersStart ~= showTakeMarkers then return true end

    return false
end

-- ImGui init
package.path = package.path .. ";" .. reaper.ImGui_GetBuiltinPath() .. '/?.lua'
local ImGui = require 'imgui' '0.9.3'

-- Menu ctx init
local ctx = ImGui.CreateContext('My script')
local windowName = LAx_ProductData.name .. " Settings"
local guiW = 280
local guiH = 340
local isSettingShortcut = true
local madePrimaryChoice = false

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
                primaryKey = i
                madePrimaryChoice = true
            else
                if i ~= primaryKeyChoice then
                    modifierKey = i
                    return false
                end
            end
        else
            if i == primaryKeyChoice then
                modifierKey = ""
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
    local window_flags = ImGui.WindowFlags_NoResize | ImGui.WindowFlags_NoCollapse
    local settingsWereUpdated = wereSettingsUpdated()

    if settingsWereUpdated then
        window_flags = window_flags | ImGui.WindowFlags_UnsavedDocument
    end

    ImGui.SetNextWindowSize(ctx, guiW, guiH, ImGui.Cond_Once)
    local guiIsVisible, guiIsOpen = ImGui.Begin(ctx, windowName, true, window_flags)

    if guiIsVisible then
        -- Shortcut setting
        ImGui.SeparatorText(ctx, "Shortcut")

        if ImGui.Button(ctx, utility.getKeyNameFromDecimal(primaryKey, true) .. (modifierKey ~= "" and " + " or "") .. utility.getKeyNameFromDecimal(modifierKey, true)) then
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
        _, restrictToNeighbors = ImGui.Checkbox(ctx, "Restrict to neighbors", restrictToNeighbors)
        ImGui.SetItemTooltip(ctx, 'If checked, the preview item will "stop" at the next item in each direction.')

        _, createGhostTrack = ImGui.Checkbox(ctx, "Create previews on new tracks", createGhostTrack)
        ImGui.SetItemTooltip(ctx, 'If checked, the preview item will be created on a new, temporary track.')

        _, showOnlyOnDrag = ImGui.Checkbox(ctx, "Show preview only when dragging", showOnlyOnDrag)
        ImGui.SetItemTooltip(ctx,
            'If checked, the preview item will only appear once you actually start dragging the (clicked) mouse.')

        _, snapToTransients = ImGui.Checkbox(ctx, "Snap to transients", snapToTransients)
        ImGui.SetItemTooltip(ctx,
            'If checked, the items will snap to transients.\nNote: Transient detection can be adjusted with Reaper\'s own settings.')
        ImGui.SameLine(ctx)
        if ImGui.Button(ctx, 'Settings##transients') then
            reaper.Main_OnCommand(41208, 0) -- Transient detection sensitivity/threshold: Adjust...
        end
        ImGui.SetItemTooltip(ctx,
            'Opens Reaper\'s default transient detection settings.\n(Command name: Transient detection sensitivity/threshold: Adjust...)')

        _, showTransientGuides = ImGui.Checkbox(ctx, "Show transient guides", showTransientGuides)
        ImGui.SetItemTooltip(ctx,
            'If checked, Reaper will calculate "transient guides" for the preview item.\nNote: May take a while.')

        _, showTakeMarkers = ImGui.Checkbox(ctx, "Show take markers", showTakeMarkers)
        ImGui.SetItemTooltip(ctx,
            'If checked, SlipView will show take markers in the preview item.')

        _, dontDisableAutoCF = ImGui.Checkbox(ctx, "Don't disable auto-crossfade", dontDisableAutoCF)
        ImGui.SetItemTooltip(ctx,
            'NOTE: Not recommended!\nIf checked, SlipView will not temporarily disable auto-crossfade.')

        -- Ints
        ImGui.SetNextItemWidth(ctx, 100)
        _, delay = ImGui.InputDouble(ctx, "Delay", math.max(delay, 0), 0.25, 0.75, "%.2f s")
        ImGui.SetItemTooltip(ctx, 'How long the shortcut needs to be held before previews appear.')

        -- Save button
        if settingsWereUpdated then
            ImGui.NewLine(ctx)
            if ImGui.Button(ctx, 'Save changes') then
                reaper.SetExtState(LAx_ProductData.name, "PrimaryKey", tostring(primaryKey), true)
                reaper.SetExtState(LAx_ProductData.name, "ModifierKey", tostring(modifierKey or ""), true)
                applyToggle("RestrictToNeighbors", restrictToNeighborsStart and 1 or 0, restrictToNeighbors and 1 or 0,
                    restrictToNeighborsToggleCmdID)
                applyToggle("CreateGhostTrack", createGhostTrackStart and 1 or 0, createGhostTrack and 1 or 0,
                    createGhostTrackToggleCmdID)
                reaper.SetExtState(LAx_ProductData.name, "ShowOnlyOnDrag", showOnlyOnDrag and "1" or "0", true)
                reaper.SetExtState(LAx_ProductData.name, "ShowTakeMarkers", showTakeMarkers and "1" or "0", true)
                applyToggle("SnapToTransients", snapToTransientsStart and 1 or 0, snapToTransients and 1 or 0,
                    snapToTransientsToggleCmdID)
                applyToggle("ShowTransientGuides", showTransientGuidesStart and 1 or 0, showTransientGuides and 1 or 0,
                    showTransientGuidesToggleCmdID)
                reaper.SetExtState(LAx_ProductData.name, "DontDisableAutoCF", dontDisableAutoCF and "1" or "0", true)
                reaper.SetExtState(LAx_ProductData.name, "Delay", tostring(delay), true)

                primaryKeyStart = primaryKey
                modifierKeyStart = modifierKey
                restrictToNeighborsStart = restrictToNeighbors
                createGhostTrackStart = createGhostTrack
                showOnlyOnDragStart = showOnlyOnDrag
                delayStart = delay
                snapToTransientsStart = snapToTransients
                showTransientGuidesStart = showTransientGuides
                dontDisableAutoCFStart = dontDisableAutoCF
                showTakeMarkersStart = showTakeMarkers

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

        ImGui.End(ctx)
    end

    -- Run loop while window is considered open
    if guiIsOpen then
        reaper.defer(guiLoop)
    end
end

guiLoop()
