-- @description Allows it to import and continuously update tracks based on a CSV table encoded in plain UTF-8.
-- @author Leon 'LAxemann' Beilmann
-- @version 1.50
-- @about
--   # About
--	 TableTracker allows it to import and continuously manage tracks in Reaper based on .CSV files encoded in plain UTF-8.	
--	 Key features:
--	 - Ability to import a .CSV file and automatically generate a track structure
--	 - Complex nested structures are no problem thanks to parenting support
--	 - Comfortable import and configuration via file selection and input fields
--	 - Ability to consider existing tracks in order to continuously update the track structure if the CSV updates
--	 - Even when adding own tracks, full folder structure support can be maintained
--	 - Ability to sort tracks like in the .csv, alphabetically or reverse alphabetically, with full support for sorting changes at any time
--	 - Ability to automatically delete tracks not present in the CSV
--	 - ''Run with previous settings'' script for rapid usage without re-configuring each time
--	 - Custom toolbar icons
--
--  # Requirements
--  None
--@links
--  Website https://www.youtube.com/@LAxemann
-- @provides
--   [nomain] fnc/functions.lua
--   [nomain] fnc/gui.lua
--   [nomain] runShared.lua
--   [nomain] ReadMe.txt
--   [nomain] Changelog.txt
--   [nomain] Example.csv
--   [data] toolbar_icons/**/*.png
--[[
 * Changelog:
    * v1.50 
      + Tweaked: Complete, GUI-based overhaul.
]] ----------------------------------------------------------------------------------------
LAx_Shared_Installed = false
local currentFolder = (debug.getinfo(1).source:match("@?(.*[\\|/])"))
currentFolder = currentFolder:gsub("\\", "/")
dofile(currentFolder .. "runShared.lua")
if not LAx_Shared_Installed then
	return
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
-- Requirements
local sep = package.config:sub(1, 1) -- OS path separator
package.path = pathNorm(package.path .. ";" .. currentFolder .. sep .. "fnc" .. sep .. "?.lua")

local extState = require("LAx_Shared_ExtState")
require("functions")
require("gui")

----------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
Enums = {
	sortOrder = {
		ORIGINAL = "Original",
		ALPHABETICALLY = "Alphabetically",
		REVALPHABETICALLY = "Reverse Alphabetically"
	},

	deleteNonMatching = {
		NONE = "Don't delete",
		EMPTY = "Delete if empty",
		ALL = "Delete all"
	}
}

Settings = {
	filetxt = extState.getExtStateValueStr(LAx_ProductData.name, "FilePath", ""),
	considerExisting = extState.getExtStateValue(LAx_ProductData.name, "ConsiderExisting", 1) == 1,
	sortOrder = extState.getExtStateValue(LAx_ProductData.name, "SortOrder", 0),
	deleteNonMatching = extState.getExtStateValue(LAx_ProductData.name, "DeleteNonMatching", 0),
	allowEmpty = extState.getExtStateValue(LAx_ProductData.name, "AllowEmpty", 0) == 1,
	closeOnRun = extState.getExtStateValue(LAx_ProductData.name, "CloseOnRun", 0) == 1,
	enableParenting = extState.getExtStateValue(LAx_ProductData.name, "EnableParenting", 1) == 1,
	parentHeaderIDX = extState.getExtStateValue(LAx_ProductData.name, "ParentHeaderIDX", 0),
	trackHeaderIDX = extState.getExtStateValue(LAx_ProductData.name, "TrackHeaderIDX", 0),
	filetxtLengthMax = 50
}


Data = {
	filetxtShortened = shortenString(Settings.filetxt, Settings.filetxtLengthMax),
	trackMap = {},
	trackIDAndParentNamePairs = {},
	processedTracks = {},
	userTracks = {},
	userTrackPairs = {},
	masterFolders = {},
	headers = { "" },
	parentHeaderName = "",
	trackHeaderName = "",
	headerString = ""
}

guiLoop()
