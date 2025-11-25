-- @noindex
----------------------------------------------------------------------------------------
-- Requirements
local extState = require("LAx_Shared_ExtState")

local M = {}

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    isMouseClicked: Checks if mouse is clicked, return if not
	@return1: IsMouseClicked [Bool]
--]]
function M.isMouseClicked()
    return reaper.JS_Mouse_GetState(1) == 1
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    openURL: Opens an URL in the default browser
	@arg1: URL [String]
--]]
function M.openURL(url)
    local OS = reaper.GetOS()

    if OS == "OSX32" or OS == "OSX64" or OS == "macOS-arm64" then
        os.execute("open " .. url)
    else
        os.execute("start " .. url)
    end
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    checkRequiredExtensions: Checks if all required extensions are installed
	@arg1: ProductName [String]
	@return1: All extensions installed [Bool]
--]]
function M.checkRequiredExtensions(productName, requiredExtensions)
    if #requiredExtensions == 0 then
        return true
    end

    requiredExtensions = LAx_ProductData.requirements

    for i, extensionName in ipairs(requiredExtensions) do
        if not reaper.APIExists(extensionName) then
            -- JS
            if extensionName == "JS_VKeys_GetState" then
                reaper.ShowMessageBox(productName ..
                    " requires the free JS_ReaScript API.\nReaPack will try to fetch the package. Right-click it and choose 'install'.",
                    productName .. ": Missing requirement", 0)
                if reaper.ReaPack_GetRepositoryInfo and reaper.ReaPack_GetRepositoryInfo "ReaTeam Extensions" then
                    reaper.ReaPack_BrowsePackages [[^"js_ReaScriptAPI: API functions for ReaScripts"$ ^"ReaTeam Extensions"$]]
                end
            end

            -- SWS
            if extensionName == "CF_GetSWSVersion" then
                local answer = reaper.MB(productName ..
                    " requires the free SWS extension for Reaper.\nWould you like to download it now?",
                    productName .. ": Missing requirement", 4)
                if answer == 6 then
                    M.openURL("https://www.sws-extension.org/")
                end
            end

            -- ImGui
            if extensionName == "ImGui_GetVersion" then
                reaper.ShowMessageBox(productName ..
                    " requires the free ImGui API.\nReaPack will try to fetch the package. Right-click it and choose 'install'.",
                    productName .. ": Missing requirement", 0)
                if reaper.ReaPack_GetRepositoryInfo and reaper.ReaPack_GetRepositoryInfo "ReaTeam Extensions" then
                    reaper.ReaPack_BrowsePackages [[^"ReaImGui: ReaScript binding for Dear ImGui"$ ^"ReaTeam Extensions"$]]
                end
            end

            -- Exit, at least one extension isn't installed
            return false
        end
    end

    -- All extensions are valid
    return true
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    toggleCommandState: Checks Toggles the command state of an action if it was previously registered in ExtState.
	@arg1: ProductName [String]
	@arg2: Extensions [Table of strings]
	@return1: Toggle was successful [Bool]
--]]
function M.toggleCommandState(productName, extStateName)
    local value = (tonumber(reaper.GetExtState(productName, extStateName)) or 0) -- Default: 0

    local toggleCmdID = extState.getExtStateValue(productName, extStateName .. "ToggleCmdID", "")

    if toggleCmdID ~= 0 then
        local commandID = reaper.NamedCommandLookup(tostring(toggleCmdID))
        reaper.SetToggleCommandState(0, commandID, value)

        return true
    end

    return false
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    interpolate: Linearly interpolates between two numbers Y based on an input X.
	@arg1: Value [Float]
	@arg2: Value XMin  [Float]
	@arg3: Value XMax [Float]
	@arg4: Value YMin [Float]
	@arg5: Value YMax [Float]
	@return1: Interpolated value [Float]
--]]
function M.interpolate(x, x1, x2, y1, y2)
    -- In case x > x2
    if x1 > x2 then
        local storeVal = x1
        x1 = x2
        x2 = storeVal
        storeVal = y1
        y1 = y2
        y2 = storeVal
    end

    -- Clamp
    if x < x1 then
        x = x1
    elseif x > x2 then
        x = x2
    end

    -- Calculate
    return y1 + (x - x1) * (y2 - y1) / (x2 - x1)
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    simulateActionInMainHWND: Simulates an action in the main HWND, e.g. lifting a mouse button.
	@arg1: Message [String]
--]]
function M.simulateActionInMainHWND(message)
    local arrangeHWND = reaper.JS_Window_FindChildByID(reaper.GetMainHwnd(), 0x3E8)
    reaper.JS_WindowMessage_Send(arrangeHWND, message, 0, 0, 0, 0)
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    stringIsNumber: Checks whether or not a string only consists of numbers.
	@arg1: String [String]
--]]
function M.stringIsNumber(str)
    return str:match("^%d+$") ~= nil
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    getKeyNameFromDecimal: Tries to get a keyboard key name based on a decimal value.
        Returns an empty string if no matching key was found.
	@arg1: Decimal [Integer]
	@return1: KeyName [String]
--]]
function M.getKeyNameFromDecimal(decimal, returnOriginalIfNotFound)
    local OS = reaper.GetOS()

    if OS == "Win64" or OS == "Win32" then
        local map = {}
        map[8] = "Backspace"
        map[9] = "TAB"
        map[13] = "Enter"
        map[16] = "LShift"
        map[17] = "LCTRL"
        map[18] = "LAlt"
        map[19] = "Pause"
        map[20] = "CapsLock"
        map[32] = "Spacebar"
        map[33] = "Page up"
        map[34] = "Page down"
        map[35] = "End"
        map[36] = "Home"
        map[37] = "Left arrow"
        map[38] = "Up arrow"
        map[39] = "Right arrow"
        map[40] = "Down arrow"
        map[44] = "Print screen"
        map[45] = "Insert"
        map[46] = "Del"
        map[48] = "0"
        map[49] = "1"
        map[50] = "2"
        map[51] = "3"
        map[52] = "4"
        map[53] = "5"
        map[54] = "6"
        map[55] = "7"
        map[56] = "8"
        map[57] = "9"
        map[65] = "A"
        map[66] = "B"
        map[67] = "C"
        map[68] = "D"
        map[69] = "E"
        map[70] = "F"
        map[71] = "G"
        map[72] = "H"
        map[73] = "I"
        map[74] = "J"
        map[75] = "K"
        map[76] = "L"
        map[77] = "M"
        map[78] = "N"
        map[79] = "O"
        map[80] = "P"
        map[81] = "Q"
        map[82] = "R"
        map[83] = "S"
        map[84] = "T"
        map[85] = "U"
        map[86] = "V"
        map[87] = "W"
        map[88] = "X"
        map[89] = "Y"
        map[90] = "Z"
        map[91] = "LWin"
        map[92] = "RWin"
        map[93] = "Apps"
        map[96] = "0 (Num)"
        map[97] = "1 (Num)"
        map[98] = "2 (Num)"
        map[99] = "3 (Num)"
        map[100] = "4 (Num)"
        map[101] = "5 (Num)"
        map[102] = "6 (Num)"
        map[103] = "7 (Num)"
        map[104] = "8 (Num)"
        map[105] = "9 (Num)"
        map[106] = "Multiply"
        map[107] = "Add"
        map[108] = "Separator"
        map[109] = "Subtract"
        map[110] = "Decimal"
        map[111] = "Divide"
        map[112] = "F1"
        map[113] = "F2"
        map[114] = "F3"
        map[115] = "F4"
        map[116] = "F5"
        map[117] = "F6"
        map[118] = "F7"
        map[119] = "F8"
        map[120] = "F9"
        map[121] = "F10"
        map[122] = "F11"
        map[123] = "F12"
        map[124] = "F13"
        map[125] = "F14"
        map[126] = "F15"
        map[127] = "F16"
        map[128] = "F17"
        map[129] = "F18"
        map[130] = "F19"
        map[131] = "F20"
        map[132] = "F21"
        map[133] = "F22"
        map[134] = "F23"
        map[135] = "F24"
        map[144] = "Num lock"
        map[145] = "Scroll lock"
        map[160] = "LShift"
        map[161] = "RShift"
        map[162] = "LCtrl"
        map[163] = "RCtrl"
        map[164] = "LAlt"
        map[165] = "RAlt"
        map[186] = "Ü"
        map[192] = "Ö"
        map[222] = "Ä"

        local keyString = map[decimal]
        if keyString then
            return keyString
        end
    end

    return returnOriginalIfNotFound and tostring(decimal) or ""
end

return M
