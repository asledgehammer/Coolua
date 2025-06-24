local readonly = require 'asledgehammer/util/readonly';

--- (Modified to work in a Project Zomboid environment)
--- From: http://lua-users.org/wiki/SimpleLuaClasses

--- Creates a class object that you can call to create instances.
---
--- @param base table|function
--- @param init function?
return function(base, init)
    local c = {} -- a new class instance
    if not init and type(base) == 'function' then
        init = base;
        base = nil;
    elseif type(base) == 'table' then
        -- our new class is a shallow copy of the base class!
        for i, v in pairs(base) do
            c[i] = v;
        end
        c._base = base;
    end
    -- the class will be the metatable for all its objects,
    -- and they will look up their methods in it.
    c.__index = c;

    -- expose a constructor which can be called by <classname>(<args>)
    local mt = {}
    mt.__call = function(class_tbl, ...)
        local obj = {};
        local readOnly = false;
        setmetatable(obj, c)
        if init then
            readOnly = init(obj, ...);
        else
            -- make sure that any stuff from the base class is initialized!
            if base and base.init then
                local readOnlyBase = base.init(obj, ...);
                if readOnlyBase then readOnly = readOnlyBase end
            end
        end
        if readOnly then obj = readonly(obj) end
        return obj;
    end
    c.init = init
    c.is_a = function(self, klass)
        local m = getmetatable(self)
        while m do
            if m == klass then return true end
            m = m._base
        end
        return false
    end
    setmetatable(c, mt)

    -- Add generic option to set class as readonly, but return a copy of it.
    --- @nodiscard
    --- @return any readOnlyCopy
    function c:asReadOnly()
        return readonly(c);
    end

    return c
end
