-- @noindex
----------------------------------------------------------------------------------------
-- Run shared functions
LAx_ProductData = {}
LAx_ProductData.name = "LAx_SlipView"

local function fileExists(path)
    return reaper.file_exists(path) or reaper.file_exists(path:lower())
end

local sep = package.config:sub(1, 1) -- OS path separator
local currentFolder = (debug.getinfo(1).source:match("@?(.*[\\|/])"))
currentFolder = currentFolder:gsub("\\", "/")

local parentFolder = currentFolder:match("(.*)/[^/]+/?$") or currentFolder:match("(.*)/")
parentFolder = parentFolder:gsub("\\", "/")

local sharedFolder = parentFolder .. sep .. "LAx_Shared" .. sep
local sharedMainFile = sharedFolder .. "LAx_Shared - Main"
sharedMainFile = sharedMainFile:gsub("\\", "/")

if fileExists(sharedMainFile .. ".lua") then
    dofile(sharedMainFile .. ".lua")
    LAx_Shared_Installed = true
else
    reaper.ShowMessageBox("LAx_ReaperScripts_Shared package not found.\nPlease install it from the same repository as " ..
                              LAx_ProductData.name .. ".\n\nReaPack will try to open the repository so you can install the LAx_ReaperScripts_Shared package.", LAx_ProductData.name .. ": Error", 0)
    reaper.ReaPack_BrowsePackages("LAxemann_ReaperScripts")

    return
end
