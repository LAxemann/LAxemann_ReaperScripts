--[[
 Noindex: true
]]

SlipView
by Leon "LAxemann" Beilmann

Version 1.02

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
	- Supports multiple items VERTICALLY: The first selected item of each track will have its preview shown.
	- Supports multiple takes on one item. The selected take will have its preview shown.
	- An activation delay can be set; Only if the keys are pressed longer than the delay the waveform preview will show up.
	- The previews will automatically update if the selected items or takes change.


//====================================================================================================================================================
Installation:
	1. Drag the contents of the .zip archive into AppData\Roaming\REAPER\Scripts
		(You can get to the REAPER folder by clicking on "Options > Show resource path in explorer/finder")
	
	2. Open the Actions List (Actions > Show actions list), click on "New action... > Load ReaScript..." and load all scripts this way.
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
	The script can be configured by opening the Action "Script: LAx_SlipView - Settings.lua"
	Here is an overview of VK Code for keybindings: https://asawicki.info/nosense/doc/devices/keyboard/key_codes.html
		- Primary Key (VK Code) [Default: 18 (ALT)]
			The primariy key (as a VK Code) for triggering the functionality
			
		- Modifier Key (VK Code) [Default: none]
			The modifier key (as a VK Code) for triggering the functionality. If this one is set, both the primary and modifier
			keys must be pressed in order to trigger the functionality.
			
		- Restrict to neighbors [Default: 0 (off)]
			If set to 1, the waveform preview will not clip into the item's neighbors.
			
		- On new track [Default: 0 (off)]
			If set to 1, the waveform preview will be created on a new, separate track. 
			Can come in handy of the original track is very cluttered.
			
		- Only when dragging content [Default: 0 (off)]
			If set to 1, the preview will only show when holding the click on a selected item.
		
		- Delay [Default: 0]
			The time the key(bindings) must be held before the functionality triggers.
			Can be useful if you have other shortcuts using e.g. ALT and don't want to
			constantly trigger the waveform preview when only tapping the key.


//====================================================================================================================================================
Known issues:
	- If neighbor restriction is on and the waveform preview has to compensate to the left, the area behind the sample start might be blank.
		This can be fixed by sweeping the waveform around a bit. It's a "Reaper issue" and likely not really "fixable".
			
			
			
//====================================================================================================================================================
Credits:
- Andrej Novosad for the initial idea of finding a way to "preview" a full waveform, as well as testing!
- Jamie Lee and Jon Kelliher for beta testing
			
