-- @noindex

local M = {}

local utility = require("LAx_Shared_Utility")
local settings = require("LAx_Shared_Settings")
local styles = require("LAx_Shared_Styles")

M.productTabs = {
    SLIPVIEW = "SlipView",
    TRANSIENTTOOLS = "Transient Tools",
    MINISCRIPTS = "Mini Scripts"
}

M.extStateIDs = {
    SLIPVIEW = "LAx_SlipView",
    TRANSIENTTOOLS = "LAx_TransientTools",
    MINISCRIPTS = "LAx_MiniScripts"
}

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    openSettingsGui: Initializes the settings gui, then opens it.
--]]
function M.openSettingsGui(initTab)
    if not initTab then
        initTab = M.productTabs.SLIPVIEW
    end

    -- ImGui init
    package.path = package.path .. ";" .. reaper.ImGui_GetBuiltinPath() .. '/?.lua'
    ImGui = require 'imgui' '0.10'

    -- Menu ctx init
    M.gui = {
        ctx = ImGui.CreateContext('LAx ReaperScript Settings'),
        windowName = "LAx ReaperScript Settings",
        baseWindowFlags = ImGui.WindowFlags_NoResize | ImGui.WindowFlags_NoCollapse | ImGui.WindowFlags_AlwaysAutoResize |
            ImGui.WindowFlags_MenuBar,
        guiW = 280,
        guiH = 340,
        styleObject = styles.createStyleObject()
    }

    -- Runtime var init
    M.gui.isSettingShortcut = true
    M.gui.madePrimaryChoice = false
    M.gui.primaryKeyChoice = nil
    M.gui.firstOpen = true
    M.gui.currentTab = initTab
    M.gui.settingsData = {}
    M.gui.settingsWereUpdated = false

    settingsGuiLoop()
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    settingsGuiLoop:
--]]
function settingsGuiLoop()
    local doPopFont, styleVarCount, styleColorCount, styleName = styles.applyVarsAndStyles(M.gui.ctx, M.gui.styleObject)
    local windowFlags = M.gui.baseWindowFlags

    if M.gui.settingsWereUpdated then
        windowFlags = windowFlags | ImGui.WindowFlags_UnsavedDocument
    end

    ImGui.SetNextWindowSize(M.gui.ctx, M.gui.guiW, M.gui.guiH, ImGui.Cond_Once)

    local guiIsVisible, guiIsOpen = ImGui.Begin(M.gui.ctx, M.gui.windowName, true, windowFlags)

    if guiIsVisible then
        -- Menu bar
        if ImGui.BeginMenuBar(M.gui.ctx) then
            if ImGui.MenuItem(M.gui.ctx, "Options##optionsButton") then
                ImGui.OpenPopup(M.gui.ctx, 'OptionsMenu')
            end

            if ImGui.BeginPopup(M.gui.ctx, 'OptionsMenu', ImGui.WindowFlags_AlwaysAutoResize) then
                if ImGui.MenuItem(M.gui.ctx, 'Restore defaults for current tab') then
                    settings.restoreDefaults(M.gui.settingsData)
                end

                styles.addStyleMenu(M.gui.ctx, M.gui.styleObject)

                if ImGui.MenuItem(M.gui.ctx, 'More scripts') then
                    utility.openURL(
                        "https://leonbeilmann.gumroad.com/?section=csoQqCxvgrTEhTLkFXsyZw==#csoQqCxvgrTEhTLkFXsyZw==")
                end

                ImGui.EndPopup(M.gui.ctx)
            end

            ImGui.EndMenuBar(M.gui.ctx)
        end

        -- Tabs
        if ImGui.BeginTabBar(M.gui.ctx, 'MyTabBar', ImGui.TabBarFlags_None) then
            tabSlipView()
            tabTransientTools()
            tabMiniScripts()

            ImGui.EndTabBar(M.gui.ctx)
        end

        if M.gui.firstOpen then
            M.gui.firstOpen = false
        end

        M.gui.settingsWereUpdated = settings.wereSettingsUpdated(M.gui.settingsData)

        -- Save button
        if M.gui.settingsWereUpdated then
            ImGui.NewLine(M.gui.ctx)
            if ImGui.Button(M.gui.ctx, 'Save changes') then
                settings.saveSettings(M.gui.settingsData, LAx_ProductData.name)

                -- Update save time
                reaper.SetExtState(LAx_ProductData.name, "LastSettingsUpdate", tostring(os.clock()), false)
            end
        end

        if M.gui.settingsWereUpdated then
            ImGui.SameLine(M.gui.ctx)
            if ImGui.GetTime(M.gui.ctx) % 0.40 < 0.20 then
                ImGui.TextColored(M.gui.ctx, styles.SharedColors.red, 'Unsaved changes')
            end
        end

        styles.popVarsAndStyles(M.gui.ctx, doPopFont, styleVarCount, styleColorCount)
        ImGui.End(M.gui.ctx)
    end

    -- Run loop while window is considered open
    if guiIsOpen then
        reaper.defer(function()
            settingsGuiLoop()
        end)
    end
end

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

            if not M.gui.madePrimaryChoice then
                M.gui.primaryKeyChoice = i
                M.gui.settingsData.PrimaryKey.runtimeSetting = i
                M.gui.madePrimaryChoice = true
            else
                if i ~= M.gui.primaryKeyChoice then
                    M.gui.settingsData.ModifierKey.runtimeSetting = i
                    return false
                end
            end
        else
            if i == M.gui.primaryKeyChoice then
                M.gui.settingsData.ModifierKey.runtimeSetting = ""
                return false
            end
        end
    end

    return true
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    tabSlipView:
--]]
function tabSlipView()
    local tabBarFlags = nil

    if M.gui.firstOpen and M.gui.currentTab == M.productTabs.SLIPVIEW then
        tabBarFlags = ImGui.TabItemFlags_SetSelected
        addSettingsSlipview()
        M.gui.firstOpen = false
    end

    if ImGui.BeginTabItem(M.gui.ctx, M.productTabs.SLIPVIEW, nil, tabBarFlags) then
        if LAx_ProductData.name ~= M.extStateIDs.SLIPVIEW then
            LAx_ProductData.name = M.extStateIDs.SLIPVIEW
            addSettingsSlipview()
        end

        -- Shortcut setting
        ImGui.SeparatorText(M.gui.ctx, "Shortcut")

        if ImGui.Button(M.gui.ctx, utility.getKeyNameFromDecimal(M.gui.settingsData.PrimaryKey.runtimeSetting, true) .. (M.gui.settingsData.ModifierKey.runtimeSetting ~= "" and " + " or "") .. utility.getKeyNameFromDecimal(M.gui.settingsData.ModifierKey.runtimeSetting, true)) then
            ImGui.OpenPopup(M.gui.ctx, 'Set shortcut')
        end
        ImGui.SetItemTooltip(M.gui.ctx,
            'Click to assign SlipView\'s shortcut.\nNote: Both "Windows" keys WILL cause trouble.')

        local center_x, center_y = ImGui.Viewport_GetCenter(ImGui.GetWindowViewport(M.gui.ctx))
        ImGui.SetNextWindowPos(M.gui.ctx, center_x, center_y, ImGui.Cond_Appearing, 0.5, 0.5)
        if ImGui.BeginPopupModal(M.gui.ctx, 'Set shortcut', nil, ImGui.WindowFlags_AlwaysAutoResize) then
            M.gui.isSettingShortcut = handleShortcutSetting()

            if not M.gui.isSettingShortcut then
                ImGui.CloseCurrentPopup(M.gui.ctx)
                M.gui.isSettingShortcut = true
                M.gui.madePrimaryChoice = false
                M.gui.primaryKeyChoice = nil
            else
                ImGui.Text(M.gui.ctx,
                    'Please press the desired shortcut (up to two keys).\nIn order to cancel, press the ESC key or click "Cancel"')

                if ImGui.Button(M.gui.ctx, 'Cancel', 120, 0) then
                    ImGui.CloseCurrentPopup(M.gui.ctx)
                    M.gui.isSettingShortcut = true
                    M.gui.madePrimaryChoice = false
                    M.gui.primaryKeyChoice = nil
                end
            end

            ImGui.SetItemDefaultFocus(M.gui.ctx)
            ImGui.EndPopup(M.gui.ctx)
        end

        ImGui.SeparatorText(M.gui.ctx, "Settings")

        -- Bools
        _, M.gui.settingsData.RestrictToNeighbors.runtimeSetting = ImGui.Checkbox(M.gui.ctx, "Restrict to neighbors",
            M.gui.settingsData.RestrictToNeighbors.runtimeSetting)
        ImGui.SetItemTooltip(M.gui.ctx, 'If checked, the preview item will "stop" at the next item in each direction.')

        _, M.gui.settingsData.CreateGhostTrack.runtimeSetting = ImGui.Checkbox(M.gui.ctx, "Create previews on new tracks",
            M.gui.settingsData.CreateGhostTrack.runtimeSetting)
        ImGui.SetItemTooltip(M.gui.ctx, 'If checked, the preview item will be created on a new, temporary track.')

        _, M.gui.settingsData.ShowOnlyOnDrag.runtimeSetting = ImGui.Checkbox(M.gui.ctx, "Show preview only when dragging",
            M.gui.settingsData.ShowOnlyOnDrag.runtimeSetting)
        ImGui.SetItemTooltip(M.gui.ctx,
            'If checked, the preview item will only appear once you actually start dragging the (clicked) mouse.')

        _, M.gui.settingsData.SnapToTransients.runtimeSetting = ImGui.Checkbox(M.gui.ctx, "Snap to transients",
            M.gui.settingsData.SnapToTransients.runtimeSetting)
        ImGui.SetItemTooltip(M.gui.ctx,
            'If checked, the items will snap to transients.\nNote: Transient detection can be adjusted with Reaper\'s own settings.')
        ImGui.SameLine(M.gui.ctx)
        if ImGui.Button(M.gui.ctx, 'Settings##transients') then
            reaper.Main_OnCommand(41208, 0) -- Transient detection sensitivity/threshold: Adjust...
        end
        ImGui.SetItemTooltip(M.gui.ctx,
            'Opens Reaper\'s default transient detection settings.\n(Command name: Transient detection sensitivity/threshold: Adjust...)')

        _, M.gui.settingsData.ShowTransientGuides.runtimeSetting = ImGui.Checkbox(M.gui.ctx, "Show transient guides",
            M.gui.settingsData.ShowTransientGuides.runtimeSetting)
        ImGui.SetItemTooltip(M.gui.ctx,
            'If checked, Reaper will calculate "transient guides" for the preview item.\nNote: May take a while.')

        _, M.gui.settingsData.ShowTakeMarkers.runtimeSetting = ImGui.Checkbox(M.gui.ctx, "Show take markers",
            M.gui.settingsData.ShowTakeMarkers.runtimeSetting)
        ImGui.SetItemTooltip(M.gui.ctx,
            'If checked, SlipView will show take markers in the preview item.')

        _, M.gui.settingsData.DontDisableAutoCF.runtimeSetting = ImGui.Checkbox(M.gui.ctx, "Don't disable auto-crossfade",
            M.gui.settingsData.DontDisableAutoCF.runtimeSetting)
        ImGui.SetItemTooltip(M.gui.ctx,
            'NOTE: Not recommended!\nIf checked, SlipView will not temporarily disable auto-crossfade.')

        -- Ints
        ImGui.SetNextItemWidth(M.gui.ctx, 130)
        _, M.gui.settingsData.Delay.runtimeSetting = ImGui.InputDouble(M.gui.ctx, "Delay",
            math.max(M.gui.settingsData.Delay.runtimeSetting, 0), 0.25, 0.75, "%.2f s")
        ImGui.SetItemTooltip(M.gui.ctx, 'How long the shortcut needs to be held before previews appear.')

        ImGui.EndTabItem(M.gui.ctx)
    end

    if ImGui.IsItemActivated(M.gui.ctx) then
        M.gui.currentTab = M.productTabs.SLIPVIEW
    end
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    addSettingsSlipview:
--]]
function addSettingsSlipview()
    M.gui.settingsData = {}
    settings.addSetting(M.gui.settingsData, M.extStateIDs.SLIPVIEW, "PrimaryKey", settings.settingsTypes.number,
        18)
    settings.addSetting(M.gui.settingsData, M.extStateIDs.SLIPVIEW, "ModifierKey", settings.settingsTypes.number,
        "")
    settings.addSetting(M.gui.settingsData, M.extStateIDs.SLIPVIEW, "Delay", settings.settingsTypes.number, 0)
    settings.addSetting(M.gui.settingsData, M.extStateIDs.SLIPVIEW, "RestrictToNeighbors",
        settings.settingsTypes.bool, true, true)
    settings.addSetting(M.gui.settingsData, M.extStateIDs.SLIPVIEW, "CreateGhostTrack",
        settings.settingsTypes.bool, false, true)
    settings.addSetting(M.gui.settingsData, M.extStateIDs.SLIPVIEW, "ShowOnlyOnDrag", settings.settingsTypes
        .bool, false)
    settings.addSetting(M.gui.settingsData, M.extStateIDs.SLIPVIEW, "SnapToTransients",
        settings.settingsTypes.bool, false, true)
    settings.addSetting(M.gui.settingsData, M.extStateIDs.SLIPVIEW, "ShowTransientGuides",
        settings.settingsTypes.bool, false, true)
    settings.addSetting(M.gui.settingsData, M.extStateIDs.SLIPVIEW, "DontDisableAutoCF",
        settings.settingsTypes.bool, false)
    settings.addSetting(M.gui.settingsData, M.extStateIDs.SLIPVIEW, "ShowTakeMarkers",
        settings.settingsTypes.bool, true)
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    tabTransientTools:
--]]
function tabTransientTools()
    local tabBarFlags = nil

    if M.gui.firstOpen and M.gui.currentTab == M.productTabs.TRANSIENTTOOLS then
        tabBarFlags = ImGui.TabItemFlags_SetSelected
        addSettingsTransientTools()
        M.gui.firstOpen = false
    end

    if ImGui.BeginTabItem(M.gui.ctx, M.productTabs.TRANSIENTTOOLS, nil, tabBarFlags) then
        if LAx_ProductData.name ~= M.extStateIDs.TRANSIENTTOOLS then
            LAx_ProductData.name = M.extStateIDs.TRANSIENTTOOLS
            addSettingsTransientTools()
        end

        ImGui.SetNextItemWidth(M.gui.ctx, 130)
        _, M.gui.settingsData.ScrollDelayMin.runtimeSetting = ImGui.InputDouble(M.gui.ctx, "Time between scrolls",
            math.max(M.gui.settingsData.ScrollDelayMin.runtimeSetting, 0), 0.02, 0.05, "%.2f s")
        ImGui.SetItemTooltip(M.gui.ctx,
            'Adjusts the minimum time that needs to elapse between scrolls.\nHelpful if your scroll device does not have steps and would otherwise blaze through the transients.')

        ImGui.EndTabItem(M.gui.ctx)
    end

    if ImGui.IsItemActivated(M.gui.ctx) then
        M.gui.currentTab = M.productTabs.TRANSIENTTOOLS
    end
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    addSettingsTransientTools:
--]]
function addSettingsTransientTools()
    M.gui.settingsData = {}
    settings.addSetting(M.gui.settingsData, M.extStateIDs.TRANSIENTTOOLS, "ScrollDelayMin",
        settings.settingsTypes.number, 0.15)
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    tabMiniScripts:
--]]
function tabMiniScripts()
    local tabBarFlags = nil

    if M.gui.firstOpen and M.gui.currentTab == M.productTabs.MINISCRIPTS then
        tabBarFlags = ImGui.TabItemFlags_SetSelected
        addSettingsMiniScripts()
        M.gui.firstOpen = false
    end

    if ImGui.BeginTabItem(M.gui.ctx, M.productTabs.MINISCRIPTS, nil, tabBarFlags) then
        if LAx_ProductData.name ~= M.extStateIDs.MINISCRIPTS then
            LAx_ProductData.name = M.extStateIDs.MINISCRIPTS
            addSettingsMiniScripts()
        end

        -- LAx_Adjust selected item volume by mousewheel.lua
        ImGui.SeparatorText(M.gui.ctx, "Mousewheel volume")

        ImGui.SetNextItemWidth(M.gui.ctx, 135)
        _, M.gui.settingsData.MouseWheelVolume_VolMin.runtimeSetting = ImGui.InputDouble(M.gui.ctx, "Minimum volume",
            math.max(M.gui.settingsData.MouseWheelVolume_VolMin.runtimeSetting, 0), 0.25, 1, "%.2f dB")
        ImGui.SetItemTooltip(M.gui.ctx,
            'Minimum volume (in dB)')

        ImGui.SetNextItemWidth(M.gui.ctx, 135)
        _, M.gui.settingsData.MouseWheelVolume_ChangeDB.runtimeSetting = ImGui.InputDouble(M.gui.ctx,
            "Volume change per scroll",
            math.max(M.gui.settingsData.MouseWheelVolume_ChangeDB.runtimeSetting, 0), 0.1, 0.25, "%.2f dB")
        ImGui.SetItemTooltip(M.gui.ctx,
            'Volume change per scroll (in dB)')

        -- LAx_Move stretch markers to nearest transients on selected items (In time selection if available).lua
        ImGui.SeparatorText(M.gui.ctx, "Stretch markers to transients")

        ImGui.SetNextItemWidth(M.gui.ctx, 135)
        _, M.gui.settingsData.StretchMarkersToNearestTransients_RandomOffset.runtimeSetting = ImGui.InputDouble(
            M.gui.ctx, "Random offset",
            math.max(M.gui.settingsData.StretchMarkersToNearestTransients_RandomOffset.runtimeSetting, 0), 1, 5,
            "%.0f ms")
        ImGui.SetItemTooltip(M.gui.ctx,
            'Sets a random offset (in ms) for a "humanized" feel.')

        ImGui.SetNextItemWidth(M.gui.ctx, 155)
        _, M.gui.settingsData.StretchMarkersToNearestTransients_Mode.runtimeSetting = ImGui.Combo(M.gui.ctx,
            'Offset direction##StretchM', M.gui.settingsData.StretchMarkersToNearestTransients_Mode.runtimeSetting,
            'Both directions\0Left only\0Right only\0')
        ImGui.SetItemTooltip(M.gui.ctx,
            'Determines in which direction(s) the offset is applied.')

        ImGui.EndTabItem(M.gui.ctx)
    end

    if ImGui.IsItemActivated(M.gui.ctx) then
        M.gui.currentTab = M.productTabs.MINISCRIPTS
    end
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    addSettingsMiniScripts:
--]]
function addSettingsMiniScripts()
    M.gui.settingsData = {}

    -- LAx_Adjust selected item volume by mousewheel.lua
    settings.addSetting(M.gui.settingsData, M.extStateIDs.MINISCRIPTS, "MouseWheelVolume_VolMin",
        settings.settingsTypes.number, 0)

    settings.addSetting(M.gui.settingsData, M.extStateIDs.MINISCRIPTS, "MouseWheelVolume_ChangeDB",
        settings.settingsTypes.number, 0.5)

    -- LAx_Move stretch markers to nearest transients on selected items (In time selection if available).lua
    settings.addSetting(M.gui.settingsData, M.extStateIDs.MINISCRIPTS,
        "StretchMarkersToNearestTransients_RandomOffset",
        settings.settingsTypes.number, 70)

    settings.addSetting(M.gui.settingsData, M.extStateIDs.MINISCRIPTS,
        "StretchMarkersToNearestTransients_Mode",
        settings.settingsTypes.number, 0)
end

return M
