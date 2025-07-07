-- @noindex
----------------------------------------------------------------------------------------
-- Declaration + Constructor 
GhostTracks = {}
GhostTracks.__index = GhostTracks

function GhostTracks.new()
    local instance = setmetatable({}, GhostTracks)
    return instance
end

function GhostTracks:init()
    self.allGhostTracks = {}
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[     
	createGhostTrack: Creates a new Ghost Track and registers it
    @arg1: Track below which the Ghost Track will be created [Track]
    @arg2: Name of the created Ghost Track [String]
    @return1: The created track
--]]
function GhostTracks:createGhostTrack(track)
    local ghostTrackObject = GhostTrack:new()
    local ghostTrack = ghostTrackObject:create(track)
    self.allGhostTracks[ghostTrack] = true

    return ghostTrack
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[     
	clear: Clears the saved tracks
--]]
function GhostTracks:clear()
    self.allGhostTracks = {}
end
