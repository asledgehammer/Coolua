--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @class PackageDefinition: ClassStructDefinition
local PackageDefinition = {};

--- @param path string
function PackageDefinition.new(path) end

--- @class Package: Object
local Package = {};

-- --- @return Class[]
-- function Package:getClasses() end

--- @return string path
function Package:getPath() end

--- @return string name
function Package:getName() end
