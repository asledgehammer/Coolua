---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @type PrintPlus
local API = {};

function API.printf(message, ...)
    print(string.format(message, ...));
end

function API.errorf(level, message, ...)
    level = level or 1;
    error(string.format(message, ...), level);
end

function API.debugf(flag, message, ...)
    if flag then API.printf(message, ...) end
end

return API;
