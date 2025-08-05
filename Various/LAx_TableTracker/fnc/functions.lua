-- @noindex
local utility = require("LAx_Shared_Utility")
local extState = require("LAx_Shared_ExtState")

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    shortenString: Shortens a string by putting a "..." in its middle if it surpasses target length
    @arg1: String [String]
    @arg2: MaxLength [Integer]
	@return1: Table data [Table]
--]]
function shortenString(str, maxLength)
    if #str <= maxLength then return str end

    local ellipsis = "..."
    local prefixLength = 6
    local keepEnd = maxLength - prefixLength - #ellipsis

    return string.sub(str, 1, prefixLength) .. ellipsis .. string.sub(str, -keepEnd)
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    browseFile: Browses for the csv file
	@return1: Filepath or "" [String]
--]]
function browseFile()
    -- File import dialogue
    local retVal, filetxt = reaper.GetUserFileNameForRead("", "Import csv (ENCODED IN PLAIN UTF-8!)", "csv")

    -- Check if successful
    if not retVal then
        --reaper.ShowMessageBox("File import failed.", LAx_ProductData.name .. " Error", 0)
        return ""
    end

    -- File type check
    if not string.match(filetxt, "%.csv$") then
        reaper.ShowMessageBox("Unsupported file format.\nCSV only.", LAx_ProductData.name .. " Error", 0)
        return ""
    end

    return filetxt
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
    readCSV: Reads CSV file, creates and returns a table of tables (Rows + Cells)
    @arg1: filePath [String]
    @arg2: skipErrors [Bool]
	@return1: Table data [Table]
--]]
function readCSV(filePath, skipErrors)
    local file = io.open(filePath, "r")

    if not file then
        if not skipErrors then
            reaper.ShowMessageBox("Could not open file.", LAx_ProductData.name .. " Error", 0)
        end

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
	parentName information in Data.trackIDAndParentNamePairs
    @arg1: trackName [String]
    @arg2: parentName [String]
--]]
function createAndStoreTrack(trackName, parentName)
    -- If desired, check if a track with the same name already exists. If so, add it to the sorting table for later.
    if Settings.considerExisting and Data.trackMap[trackName] then
        local track = Data.trackMap[trackName]
        local pairTable = { track, parentName, trackName }
        table.insert(Data.trackIDAndParentNamePairs, pairTable)
        table.insert(Data.processedTracks, trackName)
        return
    end

    -- Skip empty tracks if Settings.allowEmpty is false
    if (not Settings.allowEmpty and trackName == "") then
        return
    end

    -- Create track
    local trackIndex = reaper.CountTracks(0)
    reaper.InsertTrackAtIndex(trackIndex, true)
    local newTrack = reaper.GetTrack(0, trackIndex)
    local _, _ = reaper.GetSetMediaTrackInfo_String(newTrack, "P_NAME", trackName, true)

    -- Add to pair table
    local pairTable = { newTrack, parentName, trackName }
    table.insert(Data.trackIDAndParentNamePairs, pairTable)
    table.insert(Data.processedTracks, trackName)
    Data.trackMap[trackName] = newTrack
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
	getHeaderColumns: Searches for the specified header names and returns their column indices
	@arg1: csvData [Table]
	@arg2: hasParentHeader [Bool]
	@return1: parentNameHeaderColumn [Int]
	@return2: trackNameHeaderColumn [Int]
--]]
function getHeaderColumns(csvData, hasParentHeader)
    local parentNameHeaderColumn = -1
    local trackNameHeaderColumn = -1

    local headerRowTable = csvData[1]
    local headerCount = #headerRowTable

    for i = 1, headerCount do
        local content = csvData[1][i]

        if hasParentHeader then
            if content == Data.parentHeaderName then
                parentNameHeaderColumn = i
            end
        end

        if content == Data.trackHeaderName then
            trackNameHeaderColumn = i
        end
    end

    return parentNameHeaderColumn, trackNameHeaderColumn
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
	getHeaders: Gets a table of the names of all headers
    @arg1: Filepath (String)
    @return1: Table of strings [Table]
--]]
function getHeaders(filepath)
    if filepath == "" then
        return { "" }
    end

    local csvData = readCSV(filepath, true)

    if not csvData then
        return { "" }
    end

    local headers = {}
    local headerRowTable = csvData[1]

    for i = 1, #headerRowTable do
        local content = csvData[1][i]

        if content == "ParentName" then
            Settings.parentHeaderIDX = i - 1
        elseif content == "TrackName" then
            Settings.trackHeaderIDX = i - 1
        end

        table.insert(headers, content)
    end

    return headers
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
        if not contains(Data.processedTracks, trackName) then
            table.insert(Data.userTracks, track)

            -- Check if the usertrack has a parent. If not, we'll handle it like a master folder.
            local parentTrack = reaper.GetParentTrack(track)

            if (parentTrack) then
                local previousTrack = reaper.GetTrack(0, i - 1)
                local pairTable = { track, previousTrack }
                table.insert(Data.userTrackPairs, pairTable)
            else
                table.insert(Data.masterFolders, track)
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
	@return1: Element present [Bool]
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
            if contains(Data.userTracks, track) then
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
        Data.trackMap[trackName] = track
    end
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
	Main:
    @return1: Executed successfully [Bool]
--]]
function main()
    -- Read CSV file
    local csvData = readCSV(Settings.filetxt)

    if csvData then
        reaper.Undo_BeginBlock()

        if Settings.considerExisting then
            registerExistingTracks()
        end

        Data.parentHeaderName = Settings.enableParenting and Data.headers[Settings.parentHeaderIDX + 1] or ""
        Data.trackHeaderName = Data.headers[Settings.trackHeaderIDX + 1]

        if Data.parentHeaderName == Data.trackHeaderName then
            reaper.ShowMessageBox("Parent and track headers can't be the same.",
                LAx_ProductData.name .. " Error", 0)
            return false
        end

        --debugShowSettings()

        local hasParentHeader = Data.parentHeaderName ~= ""
        local parentNameHeaderColumn, trackNameHeaderColumn = getHeaderColumns(csvData, hasParentHeader)

        -- Check if headers match and if not, name the ones that don't
        local errorSum = 0

        if (hasParentHeader and parentNameHeaderColumn == -1) then errorSum = errorSum + 2 end
        if (trackNameHeaderColumn == -1) then errorSum = errorSum + 1 end

        if errorSum == 3 then
            reaper.ShowMessageBox("No matching headers found.\nMake sure the .csv file uses UTF-8 encoding.",
                LAx_ProductData.name .. " Error", 0)
            return false
        elseif errorSum == 2 then
            reaper.ShowMessageBox("No matching parent name headers found.\nMake sure the .csv file uses UTF-8 encoding.",
                LAx_ProductData.name .. " Error", 0)
            return false
        elseif errorSum == 1 then
            reaper.ShowMessageBox("No matching track name headers found.\nMake sure the .csv file uses UTF-8 encoding.",
                LAx_ProductData.name .. " Error", 0)
            return false
        end

        reaper.PreventUIRefresh(1)

        -- Create the tracks
        for i, _ in ipairs(csvData) do
            if (i > 1) then
                createAndStoreTrack(tostring(csvData[i][trackNameHeaderColumn]),
                    tostring(csvData[i][parentNameHeaderColumn]))
            end
        end

        -- Register remaining tracks (meaning user-generated)
        if Settings.considerExisting then
            registerUserTracks()
        end

        -- Sort the elements if desired
        if Settings.sortOrder == 1 then
            table.sort(Data.trackIDAndParentNamePairs, function(a, b)
                return a[3] < b[3]
            end)
        elseif Settings.sortOrder == 2 then
            table.sort(Data.trackIDAndParentNamePairs, function(a, b)
                return a[3] > b[3]
            end)
        end

        -- Sort master folders first. Leads to running through the table twice but sorting would be a nightmare otherwise.
        for i, pair in ipairs(Data.trackIDAndParentNamePairs) do
            local track = pair[1]
            local parentName = pair[2]

            if not Data.trackMap[parentName] then
                table.insert(Data.masterFolders, track)
            end
        end


        for i, track in ipairs(Data.masterFolders) do
            if (i > 1) then
                local previousTrack = Data.masterFolders[i - 1]
                local previousTrackIndex = reaper.GetMediaTrackInfo_Value(previousTrack, "IP_TRACKNUMBER")
                reaper.SetOnlyTrackSelected(track)
                reaper.ReorderSelectedTracks(previousTrackIndex, 0)
                reaper.SetMediaTrackInfo_Value(track, "I_FOLDERDEPTH", 0)
                reaper.SetMediaTrackInfo_Value(previousTrack, "I_FOLDERDEPTH", 0)
                reaper.SetTrackSelected(track, false)
            end
        end

        -- Assign tracks to parents using ReOrder if a valid parent header was specified
        if hasParentHeader then
            for i = #Data.trackIDAndParentNamePairs, 1, -1 do
                local pair = Data.trackIDAndParentNamePairs[i]
                local track = pair[1]
                local parentName = pair[2]

                if Data.trackMap[parentName] then
                    local parentTrack = Data.trackMap[parentName];
                    local parentTrackIndex = reaper.GetMediaTrackInfo_Value(parentTrack, "IP_TRACKNUMBER")

                    reaper.SetOnlyTrackSelected(track)
                    reaper.ReorderSelectedTracks(parentTrackIndex, 1)
                    reaper.SetTrackSelected(track, false)
                end
            end

            -- Bring user-created tracks back in correct position
            for i, pair in ipairs(Data.userTrackPairs) do
                local track = pair[1]
                local previousTrack = pair[2]

                reaper.SetOnlyTrackSelected(track)
                local previousTrackIndex = reaper.GetMediaTrackInfo_Value(previousTrack, "IP_TRACKNUMBER")

                if contains(Data.masterFolders, previousTrack) then
                    reaper.ReorderSelectedTracks(previousTrackIndex, 1)
                else
                    reaper.ReorderSelectedTracks(previousTrackIndex, 0)
                end

                reaper.SetTrackSelected(track, false)
            end
        end

        -- Delete non-matching tracks if desired
        if (Settings.deleteNonMatching ~= 0) then
            deleteNonMatchingTracks(Settings.deleteNonMatching)
        end

        -- Update tracklist, arrange window and reset variables
        reaper.TrackList_AdjustWindows(false)
        reaper.UpdateArrange()
        reaper.Undo_EndBlock("LAx_TableTracker CSV import", -1)
        resetVariables()
        saveExtState()
        reaper.PreventUIRefresh(-1)
    end

    return true
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
	resetVariables: Resets all runtime variables
--]]
function resetVariables()
    Data.trackMap = {}
    Data.trackIDAndParentNamePairs = {}
    Data.processedTracks = {}
    Data.userTracks = {}
    Data.userTrackPairs = {}
    Data.masterFolders = {}
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
	debugShowSettings: Shows outputs current settings
--]]
function debugShowSettings()
    msg(
        "File: " .. Settings.filetxt .. "\n" ..
        "Parent Header: " .. Data.parentHeaderName .. "\n" ..
        "Track Header: " .. Data.trackHeaderName .. "\n" ..
        "Consider existing: " .. tostring(Settings.considerExisting) .. "\n" ..
        "Sort Order: " .. Settings.sortOrder .. "\n" ..
        "Delete NM: " .. Settings.deleteNonMatching .. "\n" ..
        "Allow empty: " .. tostring(Settings.allowEmpty) .. "\n\n"
    )
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
	saveExtState: Saves the current settings to ExtState
--]]
function saveExtState()
    reaper.SetExtState(LAx_ProductData.name, "FilePath", Settings.filetxt, true)
    reaper.SetExtState(LAx_ProductData.name, "ConsiderExisting", Settings.considerExisting and "1" or "0", true)
    reaper.SetExtState(LAx_ProductData.name, "SortOrder", tostring(Settings.sortOrder), true)
    reaper.SetExtState(LAx_ProductData.name, "DeleteNonMatching", tostring(Settings.deleteNonMatching), true)
    reaper.SetExtState(LAx_ProductData.name, "AllowEmpty", Settings.allowEmpty and "1" or "0", true)
    reaper.SetExtState(LAx_ProductData.name, "CloseOnRun", Settings.closeOnRun and "1" or "0", true)
    reaper.SetExtState(LAx_ProductData.name, "EnableParenting", Settings.enableParenting and "1" or "0", true)
    reaper.SetExtState(LAx_ProductData.name, "ParentHeaderIDX", tostring(Settings.parentHeaderIDX), true)
    reaper.SetExtState(LAx_ProductData.name, "TrackHeaderIDX", tostring(Settings.trackHeaderIDX), true)
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
	getHeaderString:
--]]
function getHeaderString()
    local headerString = ""
    for i, str in ipairs(Data.headers) do
        headerString = headerString .. str .. "\0"
    end

    Data.headerString = headerString
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[
	updateHeaderInfo:
--]]
function updateHeaderInfo()
    Data.headers = getHeaders(Settings.filetxt)
    getHeaderString()
end
