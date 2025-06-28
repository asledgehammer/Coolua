--- @meta



---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @class StackDefinition: ObjectDefinition

--- @class Stack<E>: Object
--- 
--- @field stack E[]
local Stack = {};

--- @generic E: any
--- 
--- @return E itemRemoved
function Stack:pop() end

--- @generic E: any
--- 
--- @return E itemOnTop
function Stack:peek() end

--- @generic E: any
--- 
--- @param item E
--- 
--- @return E itemOnTop
function Stack:push(item) end

--- @return boolean isEmpty
function Stack:empty() end

--- @generic E: any
--- 
--- @param item E
--- 
--- @return integer index
function Stack:search(item) end
