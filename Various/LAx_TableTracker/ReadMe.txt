--[[
 Noindex: true
]]

TableTracker
by Leon "LAxemann" Beilmann

Version 1.00

//====================================================================================================================================================
Summary:
	TableTracker allows it to import and continuously manage tracks in Reaper based on .CSV files encoded in plain UTF-8.
	
	Key features:
	- Ability to import a .CSV file and automatically generate a track structure
	- Complex nested structures are no problem thanks to parenting support
	- Comfortable import and configuration via file selection and input fields
	- Ability to consider existing tracks in order to continuously update the track structure if the CSV updates
	- Even when adding own tracks, full folder structure support can be maintained
	- Ability to sort tracks like in the .csv, alphabetically or reverse alphabetically, with full support for sorting changes at any time
	- Ability to automatically delete tracks not present in the CSV
	- "Run with previous settings" script for rapid usage without re-configuring each time
	- Custom toolbar icons


//====================================================================================================================================================
Installation:
	If you've downloaded SlipView via ReaPack, all actions should be available and you're ready to go.
	Otherwise:
	
	1. Drag the contents of the .zip archive into AppData\Roaming\REAPER\Scripts
	   (You can get to the REAPER folder by clicking on "Options > Show resource path in explorer/finder")
	
	2. Open the Actions List (Actions > Show actions list), click on "New action... > Load ReaScript..." and load all scripts this way.
	   The scripts should now be in the Actions List as with their respective file names.



//====================================================================================================================================================
Usage:
	1. Make sure your CSV is comma-separated and encoded in PLAIN UTF-8! (No UTF-8-BOM)
	
	2. Run the "LAx_TableTracker.lua" action and select your .CSV file. The import settings box will open, with the following settings:
		- Parent header name: The header name of the column containing the parent of the row. 
		  If the field is left empty, no parenting will happen and all tracks will be created without a folder structure.
		  
		- Track header name: The header name of the column containing the track names.
		
		- Consider existing tracks: If 1, the script will check if tracks with matching names already exist and not create new ones if so.
		  If turned off (0), completely new tracks will be created no matter if matching tracks exist or not. On (1) by default.
		  
		- Sort alphabetically:
			0 = Keep order of CSV table
			1 = Sort alphabetically
			2 = Sort reverse alphabetically
		
		- Delete non-matching: Deletes tracks not present in the CSV if enabled.
			0 = Don't delete any tracks
			1 = Delete tracks that are not present in the CSV and have no media items
			2 = Delete tracks that are not present in the CSV, even if they contain media items
			
		- Allow empty tracknames: 
			0 = Rows with empty tracknames will be ignored. Recommended.
			1 = Rows with empty tracknames will be carried over into Reaper. Not recommended if you intend to re-import the CSV to update the track structure.
	
	3. You can run the "LAx_TableTracker - Run with previous settings.lua" in order to run the script with the previously used settings.



//====================================================================================================================================================
Known issues:
	- The script expects each track to have a unique name. Having multiple tracks with the same name will very likely lead to issues and unexpected behavior.
	- If the script deletes tracks (because they are no longer in the CSV or they were "user tracks", the nearest folders might become children. Re-running the script will fix this.
	- Allowing empty track names is possible for convenience and/or one-time exports, but will likely break continuous imports.