--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @class Readonly
--- @field __readonly__ boolean

--- @class LVMUtils
local API = {};

--- @param t table
--- 
--- @return Readonly
function API.readonly(t) end

--- Tests if: 
--- - The name isn't empty.
--- - The first character of the name has numbers or any illegal characters.
--- - The name has any illegal characters.
--- - The name contains spaces.
--- 
--- Legal characters: `[A-Z, a-z, 0-9, _]`
--- 
--- @param name string The name to test.
--- 
--- @return boolean result
function API.isValidName(name) end

--- @param o any
---
--- @return string typeValueString
function API.typeValueString(o) end

function API.clone(tbl) end

function API.arrayContains(tbl, e) end

function API.arrayContainsDuplicates(tbl) end

--- @param t any
--- 
--- @return boolean result
function API.isArray(t) end

--- @param lvm LVM
function API.setLVM(lvm) end
