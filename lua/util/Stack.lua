local LuaClass = require 'LuaClass';
local newClass = LuaClass.newClass;

local Stack = newClass({
    scope = 'public',
    generics = {
        E = 'any'
    }
});

Stack:addField({
    scope = 'private',
    name = 'stack',
    type = 'table',
    value = {},
});

Stack:addConstructor({
    scope = 'public',
    parameters = {},
});

Stack:addMethod({
        scope = 'public',
        name = 'push',
        parameters = { name = 'item', type = 'E' },
        returns = 'E'
    },
    --- @generic E: any
    ---
    --- @param self Stack<E>
    --- @param item E
    ---
    --- @return E
    function(self, item)
        table.insert(self.stack, item);
        return item;
    end
);

Stack:addMethod({
        scope = 'public',
        name = 'peek',
        parameters = {},
        returns = 'E'
    },
    function(self)
        local stack = self.stack;
        return stack[#stack];
    end
);

Stack:addMethod({
        scope = 'public',
        name = 'pop',
        parameters = {},
        returns = 'E'
    },
    --- @param self Stack
    function(self)
        local stack = self.stack;
        return table.remove(stack, #stack);
    end
);

Stack:addMethod({
        scope = 'public',
        name = 'isEmpty',
        parameters = {},
        returns = 'boolean'
    },
    function(self)
        return #self.stack ~= 0;
    end
);

Stack:addMethod({
        scope = 'public',
        name = 'search',
        parameters = {
            item = { name = 'item', type = 'E' }
        },
        returns = 'number'
    },
    function(self, item)
        local stack = self.stack;
        local stackLen = #stack;
        if stackLen == 0 then return 0 end
        for i = 1, #stack do
            if stack[i] == item then return i end
        end
        return 0;
    end
);

Stack:finalize();

return Stack;
