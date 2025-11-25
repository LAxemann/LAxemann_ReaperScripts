--[[
 ReaScript Name: LAx_ReaperScripts_Shared
 Author: Leon 'LAxemann' Beilmann
 REAPER: 6
 Extensions: SWS, JS_ReaScript_API
 Version: 1.21
 Provides:
  [main] LAx_ReaperScripts - Settings.lua
  [nomain] runShared.lua
  functions/*.lua
 About:
  # LAx_Shared

  ## Contains functions shared between LAxemann Scripts.

--[[
 * Changelog:
    * v1.21
      + Fixed: (Hopefully) fixed settings not included in ReaPack
]]
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    pathNorm: Add subFolders to package paths (Also normalizing to / .. fn OS differences
    @arg1: Path [String]
	@return1: Normalized path [String]
--]]
function pathNorm(path)
    return path and path:gsub("\\", "/") or ""
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
local sep = package.config:sub(1, 1) -- OS path separator
local currentFolder = pathNorm(debug.getinfo(1).source:match("@?(.*[\\|/])"))

local function addSubfoldersToPackagePath(rootPath)
    local index = 0

    while true do
        local subFolder = pathNorm(reaper.EnumerateSubdirectories(rootPath, index))
        if subFolder == "" then
            break
        end

        index = index + 1

        local fullPath = pathNorm(rootPath .. sep .. subFolder)
        package.path = pathNorm(package.path .. ";" .. fullPath .. sep .. "?.lua")
        package.path = pathNorm(package.path .. ";" .. fullPath .. sep .. "?.dat")

        -- Recursively scan deeper subfolders
        addSubfoldersToPackagePath(fullPath)
    end
end

addSubfoldersToPackagePath(currentFolder)

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    fileExists: Checks whether or not a file exists, case-insensitive
	@return1: Whether the file exists [Bool]
--]]
function fileExists(path)
    return reaper.file_exists(path) or reaper.file_exists(path:lower())
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    runFile: Runs a file if it's found. If checkExtension is true, it'll expect the filename to be without suffix.
	@arg1: path [String]
	@arg2: checkExtension [Bool] (Optional)
	@return1: Whether the file was executed successfully [Bool]
--]]
function runFile(path, checkExtension)
    path = pathNorm(path)

    if checkExtension then
        local luaPath = path .. ".lua"
        local datPath = path .. ".dat"

        if fileExists(luaPath) then
            dofile(luaPath)
            return true
        elseif fileExists(datPath) then
            dofile(datPath)
            return true
        end
    elseif fileExists(path) then
        dofile(path)
        return true
    end

    reaper.ShowMessageBox("File not found:\n" .. path, "Error", 0)
    return false
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    runAllFilesInFolder: Runs all files within a folder using runFile
	@arg1: Folder path [String]
--]]
function runAllFilesInFolder(folder)
    -- Auto load all scripts in functions folder
    folder = pathNorm(folder)
    local sep = package.config:sub(1, 1) -- OS path separator

    local fileIndex = 0
    local file = reaper.EnumerateFiles(folder, fileIndex)

    while file do
        runFile(pathNorm(folder .. sep .. file))
        fileIndex = fileIndex + 1
        file = reaper.EnumerateFiles(folder, fileIndex)
    end
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    msg: Shortcut for reaper.ShowConsoleMsg()
	@arg1: String [String]
--]]
function msg(str)
    reaper.ShowConsoleMsg(str)
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    msg: Shortcut for reaper.ShowConsoleMsg(tostring(ARG))
	@arg1: arg [Any]
--]]
function msgstr(arg)
    reaper.ShowConsoleMsg(tostring(arg))
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    openURL: Opens an URL in the default browser
	@arg1: URL [String]
--]]
function openURL(url)
    local OS = reaper.GetOS()

    if OS == "OSX32" or OS == "OSX64" or OS == "macOS-arm64" then
        os.execute("open " .. url)
    else
        os.execute("start " .. url)
    end
end

local utility = require("LAx_Shared_Utility")
LAx_Shared_Installed = utility.checkRequiredExtensions(LAx_ProductData.name, LAx_ProductData.requirements)
