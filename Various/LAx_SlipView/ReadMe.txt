--[[
 Noindex: true
]]

SlipView
by Leon "LAxemann" Beilmann

Version 1.37

//====================================================================================================================================================
Summary:
	SlipView allows it to display the full waveform of one or multiple selected items when pressing a (bindable) key.
	This was meant with Slip Editing (using ALT to move the contents of an item without moving the item itself) in mind, 
	but can of course also be used to simply show the full waveforms whenever desired.

	Key features:
	- Shows the full waveform of a selected media item when pressing a (bindable) key or key combination.
	- The waveform preview will be created relative to the media item for quick orientation within the waveform.
	- It can be set so that the preview will either stop at neighboring items or ignore them.
	- If things get too cluttered, the preview can be created on an entirely new track.
	- If the timeline or a neighboring item is in the way in either direction, it'll compensate towards the other direction.
	- A "snap to transient" mode, including previewing the next transient(s) is available.
	- Supports multiple items VERTICALLY: The first selected item of each track will have its preview shown.
	- Supports multiple takes on one item. The selected take will have its preview shown.
	- An activation delay can be set; Only if the keys are pressed longer than the delay the waveform preview will show up.
	- The previews will automatically update if the selected items or takes change.
	- Comes with custom toolbar icons.
	- Supports free positioning and fixed lanes.


//====================================================================================================================================================
Installation:
	If you've downloaded SlipView via ReaPack, all actions should be available and you're ready to go, jump to step 4.
	Otherwise:
	
	1. Drag the contents of the .zip archive into AppData\Roaming\REAPER\Scripts
		(You can get to the REAPER folder by clicking on "Options > Show resource path in explorer/finder")
	
	2. Open the Actions List (Actions > Show actions list), click on "New action... > Load ReaScript..." and load all scripts named "LAx_SlipView - xyz.lua" this way.
		The scripts should now be in the Actions List as with their respective file names.
		
	3. (Optional) Configure the script by opening the Action "Script: LAx_SlipView - Settings.lua"
		See the "Settings" section for more info
		
	4. Open the Action "Script: LAx_SlipView - Main.lua". 
		Nothing should happen, it should show up in the list of running scripts when clicking on "Actions"
		
	5. (Optional, but highly recommended) Add the action to your global startup actions.
		There are multiple ways, I personally use the Action "SWS/S&M: Set global startup action"
		Tip: If you want to have multiple startup actions, just create your own custom action, 
		add your desired actions in there, and choose this custom action as the startup action.


//====================================================================================================================================================
Usage:
	- Simply select a media item and press the key(bindings) specified in the settings (more in the Settings section). 
	- If multiple items on multiple tracks are selected, only the first (=left) item of each track will create a preview.
	- The two "Toggle" actions can used to toggle their respective functionality.
		Note: The toggle state won't show unless they have been toggles once or their values have been changed in the settings.


//====================================================================================================================================================
Settings:
	The script's settings can be configured by opening the Action "Script: LAx_SlipView - Settings.lua"
		- Shortcut
			Allows you to set up to two keys as a shortcut
			
		- Restrict to neighbors [Default: Off]
			If checked, the waveform preview will not clip into the item's neighbors.
			
		- On new track [Default: Off]
			If checked, the waveform preview will be created on a new, separate track. 
			Can come in handy of the original track is very cluttered.
			
		- Only when dragging content [Default: Off]
			If checked, the preview will only show when holding the click on a selected item.
		
		- Delay [Default: 0]
			The time the key(bindings) must be held before the functionality triggers.
			Can be useful if you have other shortcuts using e.g. ALT and don't want to
			constantly trigger the waveform preview when only tapping the key.
			
		- Snap to transients [Default: Off]
			If checked, SlipView will snap to transients. The transient detection and
			its settings are done by the default Reaper transient detection settings.
			NOTE: Even with transient snapping enabled, you can still slip edit without
			snapping by moving the mouse outside the area of the preview item.
			
		- Show transient guides [Default: Off]
			If checked, SlipView will create Reaper's transient guides on the ghost items,
			allowing you to see all transients it will snap to.

		- Show take markers [Default: On]
			If checked, SlipView will show take markers in the preview item.

		- Don't disable auto-crossfade [Default: Off]
			If checked, SlipView will not disable auto-crossfade. 
			Do NOT check it unless you have a reason to do so.


//====================================================================================================================================================
Known issues:
	- If neighbor restriction is on and the waveform preview has to compensate to the left, the area behind the sample start might be blank.
		This can be fixed by sweeping the waveform around a bit. It's a "Reaper issue" and likely not really "fixable".
	- If neither a track nor an item have a custom color, the preview item's color will be brown.


//====================================================================================================================================================
Credits:
- Andrej Novosad for the initial idea of finding a way to "preview" a full waveform, as well as testing!
- Jamie Lee and Jon Kelliher for beta testing
- X-Raym for suggestions for and on improvements
- mcoyle for informing me about MAC case sensitivity (toolbar icons)
			
