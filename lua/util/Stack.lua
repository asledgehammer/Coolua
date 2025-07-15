---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local cool = require 'cool';
local newClass = cool.newClass;

local Stack = newClass({
    scope = 'public',
});

Stack:addField({
    scope = 'private',
    name = 'stack',
    type = 'table',
    value = {},
});

Stack:addConstructor({
    scope = 'public',
});

Stack:addMethod({
    scope = 'public',
    name = 'push',
    parameters = {
        { name = 'item', type = 'any' }
    },
    returnTypes = 'any',

    --- @param self Stack<any>
    --- @param item any
    ---
    --- @return any
    body = function(self, item)
        table.insert(self.stack, item);
        return item;
    end
});

Stack:addMethod({
    scope = 'public',
    name = 'peek',
    returnTypes = 'any',

    --- @param self Stack
    body = function(self)
        local stack = self.stack;
        return stack[#stack];
    end
});

Stack:addMethod({
    scope = 'public',
    name = 'pop',
    parameters = {},
    returnTypes = 'any',
    --- @param self Stack
    body = function(self)
        local stack = self.stack;
        return table.remove(stack, #stack);
    end
});

Stack:addMethod({
    scope = 'public',
    name = 'isEmpty',
    parameters = {},
    returnTypes = 'boolean',

    --- @param self Stack
    body = function(self)
        return #self.stack ~= 0;
    end
});

Stack:addMethod({
    scope = 'public',
    name = 'search',
    parameters = {
        { name = 'item', type = 'any' }
    },
    returnTypes = 'number',

    --- @param self Stack
    --- @param item any
    body = function(self, item)
        local stack = self.stack;
        local stackLen = #stack;
        if stackLen == 0 then return 0 end
        for i = 1, #stack do
            if stack[i] == item then return i end
        end
        return 0;
    end
});

Stack:finalize();

return Stack;
