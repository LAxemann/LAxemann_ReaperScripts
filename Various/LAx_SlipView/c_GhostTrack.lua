-- @noindex
----------------------------------------------------------------------------------------
-- Declaration + Constructor 
GhostTrack = {}
GhostTrack.__index = GhostTrack

function GhostTrack.new()
    local instance = setmetatable({}, GhostTrack)
    return instance
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[ 
    create: Creates a new track and registers as a Ghost Track
	@arg1: itemTrack below which the track will be created [Track]
	@return1: ToDo [Track]
--]]
function GhostTrack:create(itemTrack)
    local itemTrackHeight = reaper.GetMediaTrackInfo_Value(itemTrack, "I_TCPH")
    local itemTrackColor = reaper.GetMediaTrackInfo_Value(itemTrack, "I_CUSTOMCOLOR")
    local itemTrackIndex = reaper.GetMediaTrackInfo_Value(itemTrack, "IP_TRACKNUMBER")

    reaper.InsertTrackAtIndex(itemTrackIndex, true) -- Insert a new track below the original track

    local ghostTrack = reaper.GetTrack(0, itemTrackIndex) -- Get the newly created track
    reaper.GetSetMediaTrackInfo_String(ghostTrack, "P_NAME", State.ghostTrackName, true)
    reaper.SetMediaTrackInfo_Value(ghostTrack, "I_HEIGHTOVERRIDE", itemTrackHeight)
    reaper.SetMediaTrackInfo_Value(ghostTrack, "I_CUSTOMCOLOR", itemTrackColor)

    self.track = ghostTrack
    return self.track
end
