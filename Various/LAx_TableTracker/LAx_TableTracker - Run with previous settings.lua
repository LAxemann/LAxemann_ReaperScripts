-- @noindex

runWithPrevious = true
local script = "LAx_TableTracker.lua"
local scriptFolder = debug.getinfo(1).source:match("@?(.*[\\|/])")
local scriptPath = scriptFolder .. script

-- Check for main file, then get previous data from ExState, finally run the main script.
if reaper.file_exists(scriptPath) then
	dofile(scriptPath)
else
	reaper.ShowMessageBox("Could not open file.\nMissing parent script.\n" .. scriptPath, "Error", 0)
	return
end