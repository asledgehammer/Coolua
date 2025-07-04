local function class(t)
    t.__type__ = 'ClassTable';
    return t;
end

local function static(t)
    t.__type__ = 'StaticTable';
    return t;
end

local function field(t)
    t.__type__ = 'FieldTable';
    return t;
end

local function method(t)
    t.__type__ = 'MethodTable';
    return t;
end

local function constructor(t)
    t.__type__ = 'ConstructorTable';
    return t;
end

local Rectangle = class {

    field {
        scope = 'private',
        type = 'number',
        name = 'x',
        value = 0,

        get = { scope = 'public' },
        set = { scope = 'public' }
    },

    field {
        scope = 'private',
        type = 'number',
        name = 'y',
        value = 0,

        get = { scope = 'public' },
        set = { scope = 'public' }
    },

    constructor {
        scope = 'public',

        --- @param o Rectangle
        body = function(o)
            o.x = 0;
            o.y = 0;
        end
    },

    constructor {
        scope = 'public',

        parameters = {
            { name = 'x',      type = 'number' },
            { name = 'y',      type = 'number' },
            { name = 'width',  type = 'number' },
            { name = 'height', type = 'number' }
        },

        --- @param super SuperTable
        --- @param width number
        --- @param height number
        super = function(super, _, _, width, height)
            super(width, height);
        end,

        --- @param self Rectangle
        --- @param x number
        --- @param y number
        --- @param width number
        --- @param height number
        body = function(self, x, y, width, height)
            self:super(width, height);
            self.x = x;
            self.y = y;
        end
    },

    method {
        scope = 'public',
        name = 'toString',
        returns = 'string',

        --- @param self Rectangle
        body = function(self)
            return self:getX() .. ', ' .. self:getY() .. ', ' .. self:super();
        end
    }
};

---
--- @param e any
--- @param level? number
local function stepPrint(e, level)
    level = level or 0;
    local indent = string.rep('  ', level);
    local indent1 = string.rep('  ', level + 1);
    local s = e.__type__ .. ' {';
    if #e ~= 0 then
        for _, f in ipairs(e) do
            s = s .. '\n' .. indent1 .. stepPrint(f, level + 1) .. ',';
        end
        s = string.sub(s, 1, #s - 1);
        return s .. '\n' .. indent .. '}';
    else
        return s .. '}';
    end
end

print(stepPrint(Rectangle));
