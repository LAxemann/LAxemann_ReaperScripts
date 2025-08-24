--[[
 Noindex: true
]]

TableTracker
by Leon "LAxemann" Beilmann

Version 1.52

//====================================================================================================================================================
Summary:
	TableTracker allows it to import and continuously manage tracks in Reaper based on .CSV files encoded in plain UTF-8.
	
	Key features:
	- GUI-based as of version 1.50
	- Ability to import a .CSV file and automatically generate a track structure
	- Complex nested structures are no problem thanks to parenting support
	- Comfortable import and configuration via file selection and input fields
	- Ability to consider existing tracks in order to continuously update the track structure if the CSV updates
	- Even when adding own tracks, full folder structure support can be maintained
	- Ability to sort tracks like in the .csv, alphabetically or reverse alphabetically, with full support for sorting changes at any time
	- Ability to automatically delete tracks not present in the CSV
	- Custom toolbar icon


//====================================================================================================================================================
Installation:
	If you've downloaded SlipView via ReaPack, all actions should be available and you're ready to go.
	Otherwise:
	
	1. Drag the contents of the .zip archive into AppData\Roaming\REAPER\Scripts
	   (You can get to the REAPER folder by clicking on "Options > Show resource path in explorer/finder")
	
	2. Open the Actions List (Actions > Show actions list), click on "New action... > Load ReaScript..." and load the script this way.
	   The script should now be in the Actions List as with its filename.



//====================================================================================================================================================
Usage:
	1. Make sure your CSV is comma-separated and encoded in PLAIN UTF-8! (No UTF-8-BOM)
	
	2. Run the "LAx_TableTracker.lua" action 



//====================================================================================================================================================
Known issues:
	- The script expects each track to have a unique name. Having multiple tracks with the same name will very likely lead to issues and unexpected behavior.
	- Allowing empty track names is possible for convenience and/or one-time exports, but will likely break continuous imports.