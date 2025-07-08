---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local dump = require 'dump'.any;

local LVM = require 'LVM';
local newClass = LVM.class.newClass;

local StackTraceElement = newClass({ scope = 'public' });

StackTraceElement:addField({
    scope = 'private',
    final = true,
    type = 'string',
    name = 'path'
});

StackTraceElement:addField({
    scope = 'private',
    final = true,
    type = 'number',
    name = 'line'
});

StackTraceElement:addField({
    scope = 'private',
    final = true,
    type = 'any',
    name = 'class'
});

StackTraceElement:addField({
    scope = 'private',
    final = true,
    type = 'string',
    name = 'context'
});

StackTraceElement:addField({
    scope = 'private',
    final = true,
    type = 'any',
    name = 'element'
});

StackTraceElement:addConstructor({

    scope = 'public',
    parameters = {
        { name = 'path',    type = 'string' },
        { name = 'line',    type = 'number' },
        { name = 'class',   type = 'any' },
        { name = 'context', type = 'string' },
        { name = 'element', type = 'any' }
    },

    --- @param self StackTraceElement
    super = function(self)
        self:super();
    end,

    --- @param self StackTraceElement
    --- @param path string
    --- @param line number
    --- @param class any
    --- @param context string
    --- @param element FieldDefinition|ConstructorDefinition|MethodDefinition
    body = function(self, path, line, class, context, element)
        self.path = path;
        self.line = line;
        self.class = class;
        self.context = context;
        self.element = element;
    end
});

StackTraceElement:addMethod({
    scope = 'public',
    type = 'string',
    name = 'toString',

    --- @param self StackTraceElement
    ---
    --- @return string
    body = function(self)
        local path, line, context, element = self.path, self.line, self.context, self.element;
        if element then
            if element.__type__ == 'MethodDefinition' then
                local callSyntax;
                if element.static then
                    callSyntax = '.';
                else
                    callSyntax = ':';
                end
                return string.format('%s:%s: calling %s%s%s(%s)',
                    path,
                    line,
                    element.class.name,
                    callSyntax,
                    element.name,
                    dump(element.parameters)
                );
            elseif element.__type__ == 'ConstructorDefinition' then
                return string.format('%s:%s: calling %s.new(%s)',
                    path,
                    line,
                    element.class.name,
                    dump(element.parameters)
                );
            elseif element.__type__ == 'FieldDefinition' then
                if context == 'field-get' then
                    return string.format('%s:%s: accessing field %s.%s',
                        path,
                        line,
                        element.class.name,
                        element.name
                    );
                elseif context == 'field-set' then
                    return string.format('%s:%s: assigning field %s.%s',
                        path,
                        line,
                        element.class.name,
                        element.name
                    );
                end
            end
        end
        return string.format('%s:%s:',
            tostring(path),
            tostring(line)
        );
    end
})

StackTraceElement:addMethod({
    scope = 'public',
    final = true,
    name = 'getPath',
    type = 'string',

    body = function(self)
        return self.path;
    end
});

StackTraceElement:addMethod({
    scope = 'public',
    final = true,
    name = 'getLine',
    type = 'number',

    body = function(self)
        return self.line;
    end
});

StackTraceElement:addMethod({
    scope = 'public',
    final = true,
    name = 'getCallingClass',
    type = 'any',

    body = function(self)
        return self.class;
    end
});

StackTraceElement:addMethod({
    scope = 'public',
    final = true,
    name = 'getContext',
    type = 'string',

    body = function(self)
        return self.context;
    end
});

StackTraceElement:addMethod({
    scope = 'public',
    final = true,
    name = 'getElement',
    parameters = {},
    type = 'any',

    body = function(self)
        return self.element;
    end
});

StackTraceElement:finalize();

--- @cast StackTraceElement StackTraceElementDefinition

return StackTraceElement;
