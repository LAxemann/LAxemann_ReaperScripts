-- ImGui init
package.path = package.path .. ";" .. reaper.ImGui_GetBuiltinPath() .. '/?.lua'
local ImGui = require 'imgui' '0.9.3'

-- Menu ctx init
local ctx = ImGui.CreateContext("Test")
local windowName = LAx_ProductData.name
local guiW = 600
local guiH = 350
local ranScript = false
local init = true
local firstStartup = not reaper.HasExtState(LAx_ProductData.name, "EnableParenting")

----------------------------------------------------------------------------------------
--[[
    guiLoop: Main gui loop/defer function
--]]
function guiLoop()
    if init then
        updateHeaderInfo()
        init = false
    end

    if ranScript then
        if Settings.closeOnRun then
            return
        else
            ranScript = false
        end
    end

    local window_flags = ImGui.WindowFlags_NoResize | ImGui.WindowFlags_NoCollapse | ImGui.WindowFlags_MenuBar |
        ImGui.WindowFlags_AlwaysAutoResize

    ImGui.SetNextWindowSize(ctx, guiW, guiH, ImGui.Cond_Once)
    local guiIsVisible, guiIsOpen = ImGui.Begin(ctx, windowName, true, window_flags)

    -- Main GUI body
    if guiIsVisible then
        if ImGui.BeginMenuBar(ctx) then
            _, Settings.closeOnRun = ImGui.Checkbox(ctx, "Close window after running script", Settings.closeOnRun)
            ImGui.EndMenuBar(ctx)
        end

        -- First use message
        if firstStartup then
            ImGui.OpenPopup(ctx, 'Info')
            local center_x, center_y = ImGui.Viewport_GetCenter(ImGui.GetWindowViewport(ctx))
            ImGui.SetNextWindowPos(ctx, center_x, center_y, ImGui.Cond_Appearing, 0.5, 0.5)
            if ImGui.BeginPopupModal(ctx, 'Info', nil, ImGui.WindowFlags_AlwaysAutoResize) then
                ImGui.Text(ctx,
                    "This appears to be the first time you are running TableTracker.\n\nTo get the most common issues out of the way:\nPlease note that TableTracker ONLY supports .CSV ENCODED IN PLAIN UTF-8.")

                if ImGui.Button(ctx, 'OK', 500, 0) then
                    firstStartup = false
                end

                ImGui.SetItemDefaultFocus(ctx)
                ImGui.EndPopup(ctx)
            end
        end

        -- File Selection
        ImGui.SeparatorText(ctx, "File (.csv formatted in PLAIN UTF-8)")

        ImGui.BeginDisabled(ctx)
        ImGui.SetNextItemWidth(ctx, 520)
        ImGui.InputText(ctx, "##fileName", Data.filetxtShortened)
        ImGui.SetItemTooltip(ctx, Settings.filetxt)
        ImGui.EndDisabled(ctx)

        ImGui.SameLine(ctx)
        if ImGui.Button(ctx, 'Browse') then
            local browseString = browseFile()
            Settings.filetxt = browseString ~= "" and browseString or Settings.filetxt
            Data.filetxtShortened = shortenString(Settings.filetxt, Settings.filetxtLengthMax)
            updateHeaderInfo()
        end

        -- Column selection
        ImGui.SeparatorText(ctx, "Column selection")
        _, Settings.enableParenting = ImGui.Checkbox(ctx, "Enable parenting", Settings.enableParenting)
        ImGui.SetItemTooltip(ctx,
            "If checked, TableTracker will build a folder hierarchy based on a parent structure.")

        if Settings.filetxt == "" then
            ImGui.BeginDisabled(ctx)
        end

        if Settings.enableParenting then
            _, Settings.parentHeaderIDX = ImGui.Combo(ctx, "Parent column", Settings.parentHeaderIDX,
                Data.headerString)
        end
        _, Settings.trackHeaderIDX = ImGui.Combo(ctx, "Track column", Settings.trackHeaderIDX, Data.headerString)

        if Settings.filetxt == "" then
            ImGui.EndDisabled(ctx)
        end

        -- Settings
        ImGui.SeparatorText(ctx, "Settings")
        _, Settings.considerExisting = ImGui.Checkbox(ctx, "Consider existing tracks", Settings.considerExisting)
        ImGui.SetItemTooltip(ctx,
            "If checked, TableTracker will not create tracks that already exist.")

        ImGui.SetNextItemWidth(ctx, 190)
        _, Settings.sortOrder = ImGui.Combo(ctx, "Sort order", Settings.sortOrder,
            Enums.sortOrder.ORIGINAL ..
            "\0" .. Enums.sortOrder.ALPHABETICALLY .. "\0" .. Enums.sortOrder.REVALPHABETICALLY .. "\0")

        ImGui.SetNextItemWidth(ctx, 190)
        _, Settings.deleteNonMatching = ImGui.Combo(ctx, "Delete non-matching tracks?", Settings.deleteNonMatching,
            Enums.deleteNonMatching.NONE ..
            "\0" .. Enums.deleteNonMatching.EMPTY .. "\0" .. Enums.deleteNonMatching.ALL .. "\0")
        ImGui.SetItemTooltip(ctx,
            "Determines what happens to tracks not found within the .CSV file.")

        _, Settings.allowEmpty = ImGui.Checkbox(ctx, "Allow empty track names", Settings.allowEmpty)
        ImGui.SetItemTooltip(ctx,
            "If checked, tracks without a name will be imported as well. This WILL cause issues when re-importing.")
        if Settings.allowEmpty then
            ImGui.SameLine(ctx)
            ImGui.TextColored(ctx, 0xFF00FFFF, "Empty track names WILL cause issues when re-ordering.")
        end

        ImGui.Separator(ctx)
        if Data.headerString == "\0" then
            ImGui.BeginDisabled(ctx)
        end

        if ImGui.Button(ctx, "Run", 400, 60) then
            getHeaders(Settings.filetxt)
            ranScript = main()
        end

        if Data.headerString == "\0" then
            ImGui.EndDisabled(ctx)
        end

        ImGui.End(ctx)
    end

    -- Run loop while window is considered open
    if guiIsOpen then
        reaper.defer(guiLoop)
    else
        saveExtState()
    end
end
