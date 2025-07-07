-- @noindex
local M = {}

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[ 
    getRenderTargetPaths: Returns a table of all render targets of current settings
	@return1: Table of render target filepaths (strings) [Table]
--]]
function M.getRenderTargetPaths()
    local retval, renderTargets = reaper.GetSetProjectInfo_String(0, "RENDER_TARGETS", "", false)

    if renderTargets == "" then
        return nil
    end

    local filePaths = {}

    for filePath in string.gmatch(renderTargets, "[^;]+") do
        table.insert(filePaths, filePath)
    end

    return filePaths
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[ 
    doRenderTargetsExist: Check if render targets with current settings exist
	@return1: Whether or not at least one render target already exists [Bool]
	@return2: RenderTarget list [Bool]
--]]
function M.doRenderTargetsExist()
    local filePaths = M.getRenderTargetPaths()

    if not filePaths then
        return false, nil
    end

    local doTargetsExist = false

    for i, file in ipairs(filePaths) do
        if reaper.file_exists(file) then
            return true, filePaths
        end
    end

    return false, nil
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[ 
    deleteExistingRenderTargets: 
		Deletes previous files before rendering new ones (prevents "Do you want to overwrite" dialogue from appearing)
--]]
function M.deleteExistingRenderTargets(autoFileOverwrite)
    local filePaths = M.getRenderTargetPaths()

    if filePaths then
        for i, file in ipairs(filePaths) do
            os.remove(file)
        end
    end
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--[[ 
    forceRenderDialogueUpdate: Forces an update of the render dialogue by re-setting the current render pattern.
--]]
function M.forceRenderDialogueUpdate()
    local _, renderName = reaper.GetSetProjectInfo_String(0, "RENDER_PATTERN", "", false)
    reaper.GetSetProjectInfo_String(0, "RENDER_PATTERN", renderName, true)
end

return M
