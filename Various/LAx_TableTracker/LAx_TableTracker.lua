-- @description Allows it to import and continuously update tracks based on a CSV table encoded in plain UTF-8.
-- @author Leon 'LAxemann' Beilmann
-- @version 1.00
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
--   [main] LAx_TableTracker - Run with previous settings.lua
--   [nomain] ReadMe.txt
--   [nomain] Changelog.txt
--   [data] toolbar_icons/**/*.png
--   [data] Example.csv
--@changelog
--   1.00: Initial version  


----------------------------------------------------------------------------------------
-- First-time message
if not reaper.HasExtState("LAx_TableTracker", "TrackHeaderName") then
	reaper.ShowMessageBox("This appears to be the first time you are running TableTracker.\nTo get the most common issues out of the way: Please note that TableTracker ONLY supports .CSV ENCODED IN PLAIN UTF-8.", "Info", 0)
end


----------------------------------------------------------------------------------------
-- Local variable declaration
local filetxt, parentHeaderName, trackHeaderName, considerExisting, sortOrder, deleteNonMatching, allowEmpty = nil, nil, nil, nil, nil, nil, nil


----------------------------------------------------------------------------------------
-- Settings.
-- Check if script is "run with previous settings". If so, get data from ExtState. If not, get data from new inputs
if runWithPrevious == nil then
	-- File import dialogue
	retVal, filetxt = reaper.GetUserFileNameForRead("", "Import csv (ENCODED IN PLAIN UTF-8!)", "csv")

	-- Check if successful
	if not retVal then
		reaper.ShowMessageBox("File import failed.", "LAx_TableTracker: Error", 0)
		return
	end

	-- File type check
	if not string.match(filetxt, "%.csv$") then
		reaper.ShowMessageBox("Unsupported file format.\nCSV only.", "LAx_TableTracker: Error", 0)
		return
	end

	----------------------------------------------------------------------------------------
	-- Track header dialogue
	local ret, userInput = reaper.GetUserInputs("LAx_TableTracker: Import settings", 6, "Parent header name (Opt.),Track header name,Consider existing tracks,Sort alphabetically,Delete non-matching,Allow empty tracknames (Risky),extrawidth=300","ParentName,TrackName,1,0,0,0")
	parentHeaderName, trackHeaderName, considerExisting, sortOrder, deleteNonMatching, allowEmpty = userInput:match("([^,]*),([^,]+),([01]),([012]),([012]),([01])")

	if not ret then
		return
	end

	if (trackHeaderName == nil) then
		reaper.ShowMessageBox("Track Header Name must not be empty!", "LAx_TableTracker: Error", 0)
		return
	end
else 
	filetxt = reaper.GetExtState("LAx_TableTracker", "FilePath")
	if filetxt == "" then
		reaper.ShowMessageBox("No previous run available.\nPlease make sure to run TableTracker at least once.", "LAx_TableTracker: Error", 0)
		return
	end
	if not reaper.file_exists(filetxt) then
		reaper.ShowMessageBox("File no longer exists.", "LAx_TableTracker: Error", 0)
		return
	end
	
	parentHeaderName = reaper.GetExtState("LAx_TableTracker", "ParentHeaderName")
	trackHeaderName = reaper.GetExtState("LAx_TableTracker", "TrackHeaderName")
	considerExisting = reaper.GetExtState("LAx_TableTracker", "ConsiderExisting")
	sortOrder = reaper.GetExtState("LAx_TableTracker", "SortOrder")
	deleteNonMatching = reaper.GetExtState("LAx_TableTracker", "DeleteNonMatching")
	allowEmpty = reaper.GetExtState("LAx_TableTracker", "AllowEmpty")
	
	----------------------------------------------------------------------------------------
	-- Confirm dialogue if run with previous settings
	local answer = reaper.MB(
	"TableTracker will run with the following settings:\n\nFile: " .. filetxt ..
	"\nParent header name: " .. parentHeaderName ..
	"\nTrack header name: " .. trackHeaderName ..
	"\nConsider existing tracks: " .. considerExisting ..
	"\nSort alphabetically: " .. sortOrder ..
	"\nDelete non-matching: " .. deleteNonMatching ..
	"\nAllow empty tracknames: " .. allowEmpty ..
	"\n\nIs this OK?", "Confirm", 1)
	
	if answer == 2 then
		return
	end
end

----------------------------------------------------------------------------------------
-- Warn about potential item deletion
if tonumber(deleteNonMatching) == 2 then
	local answer = reaper.MB("Delete non-matching is set to 2.\nTracks not present in the CSV will be deleted, even if they contain items.\nIs this OK?", "Warning!", 1)
	if answer == 2 then
		return
	end
end


----------------------------------------------------------------------------------------
-- Save settings to ExtState
reaper.SetExtState("LAx_TableTracker", "FilePath", filetxt, true)	
reaper.SetExtState("LAx_TableTracker", "ParentHeaderName", parentHeaderName, true)	
reaper.SetExtState("LAx_TableTracker", "TrackHeaderName", trackHeaderName, true)	
reaper.SetExtState("LAx_TableTracker", "ConsiderExisting", tostring(considerExisting), true)
reaper.SetExtState("LAx_TableTracker", "SortOrder", tostring(sortOrder), true)
reaper.SetExtState("LAx_TableTracker", "DeleteNonMatching", tostring(deleteNonMatching), true)
reaper.SetExtState("LAx_TableTracker", "AllowEmpty", tostring(allowEmpty), true)


----------------------------------------------------------------------------------------
-- Script variable declarations
local trackIDAndParentNamePairs = {}
local trackMap = {}
local hasParentHeader = parentHeaderName ~= ""

considerExisting = tonumber(considerExisting)
considerExisting = considerExisting == 1;

sortOrder = tonumber(sortOrder)

deleteNonMatching = tonumber(deleteNonMatching)

allowEmpty = tonumber(allowEmpty)
allowEmpty = allowEmpty == 1;

local masterFolders = {}
local processedTracks = {}
local userTracks = {}
local userTrackPairs = {}


----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[ 
    readCSV: Reads CSV file, creates and returns a table of tables (Rows + Cells)
    @arg1: filePath [String]
	Return1: Table data [Table]
--]]
function readCSV(filePath)
    local file = io.open(filePath, "r")
	
    if not file then 
		reaper.ShowMessageBox("Could not open file.", "LAx_TableTracker: Error", 0)
        return {}
    end

    local data = {}
    
    for line in file:lines() do
        -- Trim leading/trailing whitespace
        line = line:match("^%s*(.-)%s*$") 
        
        -- Skip if line is completely empty and match empty fields
        if line ~= "" then
            local row = {}
            for value in line:gmatch("([^,]*)") do
                table.insert(row, value)
            end
            table.insert(data, row)
        end
    end

    file:close()
	
    return data
end


----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[ 
    createAndStoreTrack: Creates a track with given name and stores itself together with 
	parentName information in trackIDAndParentNamePairs
    @arg1: trackName [String]
    @arg2: parentName [String]
--]]
function createAndStoreTrack(trackName, parentName)
	-- If desired, check if a track with the same name already exists. If so, add it to the sorting table for later.
	if considerExisting and trackMap[trackName] then
		local track = trackMap[trackName]
		local pairTable = {track, parentName, trackName}
		table.insert(trackIDAndParentNamePairs, pairTable)
		table.insert(processedTracks, trackName)
		return
	end
	
	-- Skip empty tracks if allowEmpty is false
	if (not allowEmpty and trackName == "") then
		return
	end

	-- Create track
    local trackIndex = reaper.CountTracks(0)
    reaper.InsertTrackAtIndex(trackIndex, true)
    local newTrack = reaper.GetTrack(0, trackIndex)
    local _, _ = reaper.GetSetMediaTrackInfo_String(newTrack, "P_NAME", trackName, true)
	
	-- Add to pair table
	local pairTable = {newTrack, parentName, trackName}
	table.insert(trackIDAndParentNamePairs, pairTable)
	table.insert(processedTracks, trackName)
	trackMap[trackName] = newTrack
end


----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[ 
	getHeaderColumns: Searches for the specified header names and returns their column indices
	@arg1: csvData [Table]
	Return1: parentNameHeaderColumn [Int]
	Return2: trackNameHeaderColumn [Int]
--]]
function getHeaderColumns(csvData)
	local parentNameHeaderColumn = -1
	local trackNameHeaderColumn = -1
	
	local headerRowTable = csvData[1]
	local headerCount = #headerRowTable
	
	for i = 1, headerCount do
		local content = csvData[1][i]
		
		if hasParentHeader then
			if content == parentHeaderName then
				parentNameHeaderColumn = i
			end
		end
		
		if content == trackHeaderName then
			trackNameHeaderColumn = i
		end
	end
	
	return parentNameHeaderColumn, trackNameHeaderColumn
end


----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[ 
	registerExistingTracks: Gets existing track names and adds them to the "trackMap"
--]]
function registerExistingTracks()
	local trackCount = reaper.CountTracks(0)
	
	for i = 0, trackCount - 1 do
		local track = reaper.GetTrack(0, i)
		local _, trackName = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
		
		-- Store track name in table
		trackMap[trackName] = track
	end
end


----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[ 
	registerUserTracks: Registers user-created tracks for sorting
--]]
function registerUserTracks()
	local trackCount = reaper.CountTracks(0)
	
	for i = 0, trackCount - 1 do
		local track = reaper.GetTrack(0, i)
		local _, trackName = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
		
		-- We check if the track is part of the "processed tracks" from the CSV. If not, it's a "usertrack".
		if not contains(processedTracks, trackName) then
			table.insert(userTracks, track)
			
			-- Check if the usertrack has a parent. If not, we'll handle it like a master folder.
			local parentTrack = reaper.GetParentTrack(track)
			
			if (parentTrack) then
				local previousTrack = reaper.GetTrack(0, i-1)
				local pairTable = {track, previousTrack}
				table.insert(userTrackPairs, pairTable)
			else
				table.insert(masterFolders, track)
			end
		end
	end
end


----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[ 
	contains: Checks if a table contains an element
	@arg1: tableToCheck [Table]
	@arg2: String [String]
	Return1: Element present [Bool]
--]]
function contains(tableToCheck, str)
    for _, value in ipairs(tableToCheck) do
        if value == str then
            return true
        end
    end
    return false
end


----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[ 
	deleteNonMatching: Deletes non-matching usertracks
--]]
function deleteNonMatchingTracks(deleteNonMatching)
	reaper.PreventUIRefresh(1)
	local trackCount = reaper.CountTracks(0)

	-- We loop through tracks in reverse order to prevent indexing issues
	for i = trackCount - 1, 0, -1 do
		local track = reaper.GetTrack(0, i)
		local _, trackName = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
		
		if track then
			if contains(userTracks, track) then
				if deleteNonMatching == 1 then
					local itemCount = reaper.CountTrackMediaItems(track)
					
					if itemCount == 0 then
						reaper.DeleteTrack(track)
					end					
				elseif deleteNonMatching == 2 then
					reaper.DeleteTrack(track)
				end
			end
		end
	end	
	reaper.PreventUIRefresh(-1)	
end


----------------------------------------------------------------------------------------
-- Main function
function main()
	-- Read CSV file
	local csvData = readCSV(filetxt) 

	if csvData then
		if considerExisting then
			registerExistingTracks()
		end
	
		parentNameHeaderColumn, trackNameHeaderColumn = getHeaderColumns(csvData)
		
		-- Check if headers match and if not, name the ones that don't
		local errorSum = 0
		if (hasParentHeader and parentNameHeaderColumn == -1) then errorSum = errorSum + 2 end
		if (trackNameHeaderColumn == -1) then errorSum = errorSum + 1 end
		
		if errorSum == 3 then 
			reaper.ShowMessageBox("No matching headers found.\nMake sure the .csv file uses UTF-8 encoding.", "LAx_TableTracker: Error", 0)
			return
		elseif errorSum == 2 then
			reaper.ShowMessageBox("No matching parent name headers found.\nMake sure the .csv file uses UTF-8 encoding.", "LAx_TableTracker: Error", 0)
			return
		elseif errorSum == 1 then
			reaper.ShowMessageBox("No matching track name headers found.\nMake sure the .csv file uses UTF-8 encoding.", "LAx_TableTracker: Error", 0)
			return
		end
		
		-- Create the tracks
		reaper.PreventUIRefresh(1)
		for i, row in ipairs(csvData) do
			if (i > 1) then -- TODO (?): Currently assuming first row is headers, could be optional
				createAndStoreTrack(tostring(csvData[i][trackNameHeaderColumn]), tostring(csvData[i][parentNameHeaderColumn]))
			end
		end
		reaper.PreventUIRefresh(-1)
		
		-- Register remaining tracks (meaning user-generated)
		if considerExisting then
			registerUserTracks()
		end
		
		-- Sort the elements if desired
		if sortOrder == 1 then
			table.sort(trackIDAndParentNamePairs, function(a, b)
				return a[3] < b[3]
			end)
		elseif sortOrder == 2 then
			table.sort(trackIDAndParentNamePairs, function(a, b)
				return a[3] > b[3]
			end)	
		end
		
		-- Sort master folders first. Leads to running through the table twice but sorting would be a nightmare otherwise.
		for i, track in ipairs(trackIDAndParentNamePairs) do	
			local pair = trackIDAndParentNamePairs[i]
			local track = pair[1]
			local parentName = pair[2]
			
			if not trackMap[parentName] then
				table.insert(masterFolders, track)
			end
		end
			
		reaper.PreventUIRefresh(1)
		for i, track in ipairs(masterFolders) do
			if (i > 1) then
				local previousTrack = masterFolders[i-1]
				local previousTrackIndex = reaper.GetMediaTrackInfo_Value(previousTrack, "IP_TRACKNUMBER")
				reaper.SetOnlyTrackSelected(track)
				reaper.ReorderSelectedTracks(previousTrackIndex, 0)
				reaper.SetMediaTrackInfo_Value(track, "I_FOLDERDEPTH", 0)
				reaper.SetMediaTrackInfo_Value(previousTrack, "I_FOLDERDEPTH", 0)
				reaper.SetTrackSelected(track, false)
			end
		end
		reaper.PreventUIRefresh(-1)		
		
		-- Assign tracks to parents using ReOrder if a valid parent header was specified
		if hasParentHeader then 
			reaper.PreventUIRefresh(1)
			for i = #trackIDAndParentNamePairs, 1, -1 do
				local pair = trackIDAndParentNamePairs[i]
				local track = pair[1]
				local parentName = pair[2]
				
				if trackMap[parentName] then
					local parentTrack = trackMap[parentName];
					local parentTrackIndex = reaper.GetMediaTrackInfo_Value(parentTrack, "IP_TRACKNUMBER")
					
					reaper.SetOnlyTrackSelected(track)
					reaper.ReorderSelectedTracks(parentTrackIndex, 1)
					reaper.SetTrackSelected(track, false)
				end
			end
			
			-- Bring user-created tracks back in correct position
			for i, pair in ipairs(userTrackPairs) do
				local track = pair[1]
				local previousTrack = pair[2]
				
				reaper.SetOnlyTrackSelected(track)
				local previousTrackIndex = reaper.GetMediaTrackInfo_Value(previousTrack, "IP_TRACKNUMBER")
				
				if contains(masterFolders, previousTrack) then
					reaper.ReorderSelectedTracks(previousTrackIndex, 1)
				else
					reaper.ReorderSelectedTracks(previousTrackIndex, 0)
				end
				
				reaper.SetTrackSelected(track, false)
			end
			reaper.PreventUIRefresh(-1)
		end
		
		-- Delete non-matching tracks if desired
		if (deleteNonMatching > 0) then
			deleteNonMatchingTracks(deleteNonMatching)
		end
		
		-- Update tracklist and arrange window
		reaper.TrackList_AdjustWindows(false)
		reaper.UpdateArrange()
	end
end

main()