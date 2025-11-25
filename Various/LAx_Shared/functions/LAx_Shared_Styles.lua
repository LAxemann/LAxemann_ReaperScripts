-- @noindex
local M = {}

-- Color definitions
M.Styles = {}

-- Styles
----------------------------------------------------------------------------------------
M.Styles.renderBuddy = {
    name = "RenderBuddy",
    colors = {
        background = 0x1A3330FF,
        frameBackgroundGreen = 0x32645EFF,
        frameBackgroundGreenHovered = 0x559C94FF,
        titleBackground = 0x401867FF,
        titleBackgroundActive = 0x6529A0FF,
        menuBarBackground = 0x11201EFF,
        activeElementPink = 0xDB67D1FF,
        activeElementPinkHighlighted = 0xF4CAF0FF,
        interactionLightGreen = 0x65663EFF,
        interactionLightGreenHovered = 0xB4B56EFF,
        interactionLightGreenActive = 0x81824FFF,
        headerActive = 0x594F5BFF,
        separator = 0xDB67D142,
        separatorHovered = 0xF576EA73,
        separatorActive = 0xDB67D173,
        resizeGrip = 0x9B4A9468,
        resizeGripHovered = 0xEC00FF86,
        resizeGripActive = 0xDB67D1FF,
    },
    fontSizes = {
        regular = 18
    },
    styleVars = {
        FrameRounding = 7,
        GrabRounding = 7
    }
}
----------------------------------------------------------------------------------------
M.Styles.laxReaperScripts = {
    name = "LAx Reaper Scripts",
    colors = {
        background = 0x2B3332FF,
        border = 0x695C236B,
        elementGreen = 0x2E5B56FF,
        elementGreenHovered = 0x488881FF,
        elementGreenActive = 0x48C2B6FF,
        mainYellow = 0x695C23FF,
        mainYellowActive = 0x8F7C2EFF,
        mainYellowActiveBrighter = 0xB59E40FF,
        menuBarBackground = 0x242424FF,
        headerHovered = 0x695C23BC,
        separator = 0xDB67D142,
        separatorHovered = 0xF576EA73,
        separatorActive = 0xDB67D173,
        resizeGrip = 0x9B4A9468,
        resizeGripHovered = 0xEC00FF86,
        resizeGripActive = 0xDB67D1FF,
        dockingPreview = 0x695C23A4,
        textSelectedBg = 0xDB67D15D
    },
    fontSizes = {
        regular = 16
    },
    styleVars = {
        FrameRounding = 2,
        GrabRounding = 2
    }
}
----------------------------------------------------------------------------------------
M.Styles.imGuiDefault = {
    name = "ImGui"
}
----------------------------------------------------------------------------------------
-- Shared, basic colors
M.SharedColors = {
    black = 0x000000FF,
    red = 0xFF0000FF,
    yellow = 0xFFFF00FF,
    green = 0x72FF83FF
}

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    createStyleObject: Creates a style object
    @arg1: ctx [Ctx]
    @arg2: StyleName [String]
    @return1: Style object [Table]
--]]
function M.createStyleObject()
    local styleObject = {}

    M.applyStyle(styleObject, reaper.GetExtState(LAx_ProductData.name, "Style") or getDefaultStyleName())

    return styleObject
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    getDefaultStyleName:
--]]
function getDefaultStyleName()
    if LAx_ProductData.name == "LAx_RenderBuddy" then
        return "RenderBuddy"
    end

    return "LAx Reaper Scripts"
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    addStyleMenu:
--]]
function M.addStyleMenu(ctx, styleObject)
    if ImGui.BeginMenu(ctx, 'Menu style') then
        if ImGui.MenuItem(ctx, 'LAx Reaper Scripts') then
            M.applyStyle(styleObject, "LAx Reaper Scripts")
        end
        if ImGui.MenuItem(ctx, 'RenderBuddy') then
            M.applyStyle(styleObject, "RenderBuddy")
        end
        if ImGui.MenuItem(ctx, 'ImGui default') then
            M.applyStyle(styleObject, "ImGui")
        end

        --[[
        for k, style in pairs(M.Styles) do
            if ImGui.MenuItem(ctx, style.name) then

                M.applyStyle(styleObject, style.name) -- ToDo: Needs to be sorted first
            end
        end
        --]]

        ImGui.EndMenu(ctx)
    end
end

----------------------------------------------------------------------------------------
--[[
    applyStyle: Applies the chosen style
    @arg1: ctx [Ctx]
    @arg2: StyleName [String]
    @return1: Style object [Table]
--]]
function M.applyStyle(styleObject, styleName)
    if not styleObject then
        return
    end

    reaper.SetExtState(LAx_ProductData.name, "Style", styleName, true)

    -- Default ImGui style
    if not styleName or styleName == "" then
        styleName = getDefaultStyleName()
    elseif styleName == "ImGui" then
        styleObject.styleName = "ImGui"
    end

    -- Default LAx Reaper Scripts
    if styleName == "LAx Reaper Scripts" then
        styleObject.styleName = "LAx Reaper Scripts"
        styleObject.colors = {
            WindowBg = M.Styles.laxReaperScripts.colors.background,
            PopupBg = M.Styles.laxReaperScripts.colors.menuBarBackground,
            Border = M.Styles.laxReaperScripts.colors.border,
            FrameBg = M.Styles.laxReaperScripts.colors.elementGreen,
            FrameBgHovered = M.Styles.laxReaperScripts.colors.elementGreenHovered,
            FrameBgActive = M.Styles.laxReaperScripts.colors.elementGreenActive,
            TitleBg = M.Styles.laxReaperScripts.colors.mainYellow,
            TitleBgActive = M.Styles.laxReaperScripts.colors.mainYellowActive,
            MenuBarBg = M.Styles.laxReaperScripts.colors.menuBarBackground,
            CheckMark = M.Styles.laxReaperScripts.colors.elementGreenActive,
            SliderGrab = M.Styles.laxReaperScripts.colors.mainYellowActive,
            SliderGrabActive = M.Styles.laxReaperScripts.colors.mainYellowActiveBrighter,
            Button = M.Styles.laxReaperScripts.colors.elementGreen,
            ButtonHovered = M.Styles.laxReaperScripts.colors.elementGreenHovered,
            ButtonActive = M.Styles.laxReaperScripts.colors.elementGreenActive,
            Header = M.Styles.laxReaperScripts.colors.mainYellow,
            HeaderHovered = M.Styles.laxReaperScripts.colors.headerHovered,
            HeaderActive = M.Styles.laxReaperScripts.colors.mainYellowActive,
            Separator = M.Styles.laxReaperScripts.colors.separator,
            SeparatorHovered = M.Styles.laxReaperScripts.colors.separatorHovered,
            SeparatorActive = M.Styles.laxReaperScripts.colors.separatorActive,
            ResizeGrip = M.Styles.laxReaperScripts.colors.resizeGrip,
            ResizeGripHovered = M.Styles.laxReaperScripts.colors.resizeGripHovered,
            ResizeGripActive = M.Styles.laxReaperScripts.colors.resizeGripActive,
            TabHovered = M.Styles.laxReaperScripts.colors.mainYellowActiveBrighter,
            Tab = M.Styles.laxReaperScripts.colors.mainYellow,
            TabSelected = M.Styles.laxReaperScripts.colors.mainYellowActive,
            TabSelectedOverline = M.Styles.laxReaperScripts.colors.mainYellow,
            DockingPreview = M.Styles.laxReaperScripts.colors.dockingPreview,
            DockingEmptyBg = M.Styles.laxReaperScripts.colors.background,
            TextSelectedBg = M.Styles.laxReaperScripts.colors.textSelectedBg
        }
        styleObject.fontSizes = {
            regular = M.Styles.laxReaperScripts.fontSizes.regular
        }
        styleObject.styleVars = {
            frameRounding = M.Styles.laxReaperScripts.styleVars.FrameRounding,
            grabRounding = M.Styles.laxReaperScripts.styleVars.GrabRounding
        }
        -- RenderBuddy Style
    elseif styleName == "RenderBuddy" then
        styleObject.styleName = "RenderBuddy"
        styleObject.colors = {
            WindowBg = M.Styles.renderBuddy.colors.background,
            PopupBg = M.Styles.renderBuddy.colors.menuBarBackground,
            Border = M.Styles.renderBuddy.colors.menuBarBackground,
            FrameBg = M.Styles.renderBuddy.colors.frameBackgroundGreen,
            FrameBgHovered = M.Styles.renderBuddy.colors.frameBackgroundGreenHovered,
            FrameBgActive = M.Styles.renderBuddy.colors.frameBackgroundGreen,
            TitleBg = M.Styles.renderBuddy.colors.titleBackground,
            TitleBgActive = M.Styles.renderBuddy.colors.titleBackgroundActive,
            MenuBarBg = M.Styles.renderBuddy.colors.menuBarBackground,
            CheckMark = M.Styles.renderBuddy.colors.activeElementPink,
            SliderGrab = M.Styles.renderBuddy.colors.titleBackground,
            SliderGrabActive = M.Styles.renderBuddy.colors.activeElementPink,
            Button = M.Styles.renderBuddy.colors.interactionLightGreen,
            ButtonHovered = M.Styles.renderBuddy.colors.interactionLightGreenHovered,
            ButtonActive = M.Styles.renderBuddy.colors.interactionLightGreenActive,
            Header = M.Styles.renderBuddy.colors.interactionLightGreen,
            HeaderHovered = M.Styles.renderBuddy.colors.interactionLightGreenHovered,
            HeaderActive = M.Styles.renderBuddy.colors.headerActive,
            Separator = M.Styles.renderBuddy.colors.separator,
            SeparatorHovered = M.Styles.renderBuddy.colors.separatorHovered,
            SeparatorActive = M.Styles.renderBuddy.colors.separatorActive,
            ResizeGrip = M.Styles.renderBuddy.colors.resizeGrip,
            ResizeGripHovered = M.Styles.renderBuddy.colors.resizeGripHovered,
            ResizeGripActive = M.Styles.renderBuddy.colors.resizeGripActive,
            TabHovered = M.Styles.renderBuddy.colors.frameBackgroundGreenHovered,
            Tab = M.Styles.renderBuddy.colors.frameBackgroundGreen,
            TabSelected = M.Styles.renderBuddy.colors.interactionLightGreenHovered,
            TabSelectedOverline = M.Styles.renderBuddy.colors.frameBackgroundGreen,
            DockingPreview = M.Styles.renderBuddy.colors.background,
            DockingEmptyBg = M.Styles.renderBuddy.colors.menuBarBackground,
            TextSelectedBg = M.Styles.renderBuddy.colors.headerActive,
        }
        styleObject.fontSizes = {
            regular = M.Styles.renderBuddy.fontSizes.regular
        }
        styleObject.styleVars = {
            frameRounding = M.Styles.renderBuddy.styleVars.FrameRounding,
            grabRounding = M.Styles.renderBuddy.styleVars.GrabRounding
        }
    end
end

----------------------------------------------------------------------------------------
--[[
    applyVarsAndStyles:
    @arg1: ctx [Ctx]
    @arg2: StyleObject [Table]
    @return1: Did provide font? [Bool]
    @return2: Nr StyleVars [Integer]
    @return3: Nr StyleColors[Integer]
    @return4: Style name [String]
--]]
function M.applyVarsAndStyles(ctx, styleObject)
    if styleObject and styleObject.styleName ~= "ImGui" then
        ImGui.PushFont(ctx, nil, styleObject.fontSizes.regular)

        ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding, styleObject.styleVars.frameRounding)
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_GrabRounding, styleObject.styleVars.grabRounding)

        ImGui.PushStyleColor(ctx, ImGui.Col_WindowBg, styleObject.colors.WindowBg)
        ImGui.PushStyleColor(ctx, ImGui.Col_PopupBg, styleObject.colors.PopupBg)
        ImGui.PushStyleColor(ctx, ImGui.Col_Border, styleObject.colors.Border)
        ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg, styleObject.colors.FrameBg)
        ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgHovered, styleObject.colors.FrameBgHovered)
        ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgActive, styleObject.colors.FrameBgActive)
        ImGui.PushStyleColor(ctx, ImGui.Col_TitleBg, styleObject.colors.TitleBg)
        ImGui.PushStyleColor(ctx, ImGui.Col_TitleBgActive, styleObject.colors.TitleBgActive)
        ImGui.PushStyleColor(ctx, ImGui.Col_MenuBarBg, styleObject.colors.MenuBarBg)
        ImGui.PushStyleColor(ctx, ImGui.Col_CheckMark, styleObject.colors.CheckMark)
        ImGui.PushStyleColor(ctx, ImGui.Col_SliderGrab, styleObject.colors.SliderGrab)
        ImGui.PushStyleColor(ctx, ImGui.Col_SliderGrabActive, styleObject.colors.SliderGrabActive)
        ImGui.PushStyleColor(ctx, ImGui.Col_Button, styleObject.colors.Button)
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, styleObject.colors.ButtonHovered)
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, styleObject.colors.ButtonActive)
        ImGui.PushStyleColor(ctx, ImGui.Col_Header, styleObject.colors.Header)
        ImGui.PushStyleColor(ctx, ImGui.Col_HeaderHovered, styleObject.colors.HeaderHovered)
        ImGui.PushStyleColor(ctx, ImGui.Col_HeaderActive, styleObject.colors.HeaderActive)
        ImGui.PushStyleColor(ctx, ImGui.Col_Separator, styleObject.colors.Separator)
        ImGui.PushStyleColor(ctx, ImGui.Col_SeparatorHovered, styleObject.colors.SeparatorHovered)
        ImGui.PushStyleColor(ctx, ImGui.Col_SeparatorActive, styleObject.colors.SeparatorActive)
        ImGui.PushStyleColor(ctx, ImGui.Col_ResizeGrip, styleObject.colors.ResizeGrip)
        ImGui.PushStyleColor(ctx, ImGui.Col_ResizeGripHovered, styleObject.colors.ResizeGripHovered)
        ImGui.PushStyleColor(ctx, ImGui.Col_ResizeGripActive, styleObject.colors.ResizeGripActive)
        ImGui.PushStyleColor(ctx, ImGui.Col_TabHovered, styleObject.colors.TabHovered)
        ImGui.PushStyleColor(ctx, ImGui.Col_Tab, styleObject.colors.Tab)
        ImGui.PushStyleColor(ctx, ImGui.Col_TabSelected, styleObject.colors.TabSelected)
        ImGui.PushStyleColor(ctx, ImGui.Col_TabSelectedOverline, styleObject.colors.TabSelectedOverline)
        ImGui.PushStyleColor(ctx, ImGui.Col_DockingPreview, styleObject.colors.DockingPreview)
        ImGui.PushStyleColor(ctx, ImGui.Col_DockingEmptyBg, styleObject.colors.DockingEmptyBg)
        ImGui.PushStyleColor(ctx, ImGui.Col_TextSelectedBg, styleObject.colors.TextSelectedBg)

        return true, 2, 31, styleObject.styleName
    end

    return false, 0, 0, "ImGui"
end

----------------------------------------------------------------------------------------
--[[
    popVarsAndStyles:
    @arg1: ctx [Ctx]
    @arg2: Do pop font? [Bool]
    @arg3: Nr StyleVars to pop [Integer]
    @arg4: Nr StyleColors to pop [Integer]
--]]
function M.popVarsAndStyles(ctx, doPopFont, styleVarCount, styleColorCount)
    if doPopFont then
        ImGui.PopFont(ctx)
    end

    if styleVarCount and styleVarCount > 0 then
        ImGui.PopStyleVar(ctx, styleVarCount)
    end

    if styleColorCount and styleColorCount > 0 then
        ImGui.PopStyleColor(ctx, styleColorCount)
    end
end

return M
