---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local PrintPlus = require 'cool/print';
local errorf = PrintPlus.errorf;

local DebugUtils = require 'cool/debug';

--- @type VM
local vm;

--- @type VMStructModule
local API = {

    __type__ = 'VMModule',

    -- Method(s)
    --- @param vm VM
    setVM = function(vm)
        vm = vm;
        vm.moduleCount = vm.moduleCount + 1;
    end
};

function API.createInstanceMetatable(cd, o)
    local mt = getmetatable(o) or {};

    local fields = {};

    -- Set all instanced classes for the metatable.

    local instancedStructs = {};
    local classChain = {};
    local next = cd;

    repeat
        table.insert(classChain, next);
        next = next.super;
    until not next;
    for i = #classChain, 1, -1 do
        for k, v in pairs(classChain[i].inner) do
            if not v.static then
                instancedStructs[k] = v;
            end
        end
    end

    -- Copy functions & fields.
    for k, v in pairs(o) do
        if k ~= '__index' then
            fields[cd.path .. '@' .. k] = v;
        end
    end

    fields.__class__ = cd;

    mt.__index = function(_, field)
        if not cd.__readonly__ then
            cd:finalize();
        end



        if instancedStructs[field] then
            return instancedStructs[field];
        end

        -- Super is to be treated differently / internally.
        if field == 'super' then
            return fields[field];
        elseif field == '__class__' then
            return fields[field];
        end

        local fd = cd:getField(field);
        if not fd then
            errorf(2, 'FieldNotFoundException: Field doesn\'t exist: %s.%s',
                cd.path, field
            );
            return;
        end

        local level, relPath = vm.scope.getRelativePath();

        vm.stack.pushContext({
            class = cd,
            element = fd,
            context = 'field-get',
            line = DebugUtils.getCurrentLine(level),
            path = DebugUtils.getPath(level)
        });

        local callInfo = DebugUtils.getCallInfo(level, vm.ROOT_PATH, true);
        -- callInfo.path = relPath;
        local scopeAllowed = vm.scope.getScopeForCall(fd.class, callInfo);

        if not vm.flags.bypassFieldSet and not vm.scope.canAccessScope(fd.scope, scopeAllowed) then
            local errMsg = string.format(
                'IllegalAccessException: The field %s.%s is set as "%s" access level. (Access Level from call: "%s")\n%s',
                cd.name, fd.name,
                fd.scope, scopeAllowed,
                vm.stack.printStackTrace()
            );
            vm.stack.popContext();
            print(errMsg);
            error('', 2);
            return;
        end

        -- TODO: Implement generic type-cast checks.

        vm.stack.popContext();

        -- Get the value.
        if fd.static then
            return fd.class[field];
        else
            return fields[cd.path .. '@' .. field];
        end
    end

    mt.__newindex = function(tbl, field, value)
        -- TODO: Visibility scope analysis.
        -- TODO: Type-checking.

        if not cd.__readonly__ then
            cd:finalize();
        end

        if field == 'super' then
            if vm.isOutside() then
                errorf(2, '%s Cannot set super(). (Reserved method)', cd.printHeader);
            end
            fields.super = value;
            return;
        elseif field == '__super__' then
            if vm.isOutside() then
                errorf(2, '%s Cannot set __super__. (Internal field)', cd.printHeader);
            end
            fields.__super__ = value;
            return;
        elseif field == '__class__' then
            if vm.isOutside() then
                errorf(2, '%s Cannot set __class__. (Internal field)', cd.printHeader);
            end
            fields.__class__ = value;
            return;
        end

        local fd = cd:getField(field);
        if not fd then
            errorf(2, 'FieldNotFoundException: Field doesn\'t exist: %s.%s',
                cd.path, field
            );
            return;
        end

        local level, relPath = vm.scope.getRelativePath();

        vm.stack.pushContext({
            class = cd,
            element = fd,
            context = 'field-set',
            line = DebugUtils.getCurrentLine(level),
            path = DebugUtils.getPath(level)
        });

        local callInfo = DebugUtils.getCallInfo(level, vm.ROOT_PATH, true);
        callInfo.path = relPath;
        local scopeAllowed = vm.scope.getScopeForCall(fd.class, callInfo);

        if not vm.flags.bypassFieldSet and not vm.scope.canAccessScope(fd.scope, scopeAllowed) then
            local errMsg = string.format(
                'IllegalAccessException: The field %s.%s is set as "%s" access level. (Access Level from call: "%s")\n%s',
                cd.name, fd.name,
                fd.scope, scopeAllowed,
                vm.stack.printStackTrace()
            );
            vm.stack.popContext();
            print(errMsg);
            error('', 2);
            return;
        end

        -- (Just in-case)
        if value == vm.constants.UNINITIALIZED_VALUE then
            local errMsg = string.format('%s Cannot set %s as UNINITIALIZED_VALUE. (Internal Error)\n%s',
                cd.printHeader, field, vm.stack.printStackTrace()
            );
            vm.stack.popContext();
            error(errMsg, 2);
            return;
        end

        local ste = vm.stack.getContext();

        if not ste then
            vm.stack.popContext();
            error('Context is nil.', 2);
            return;
        end

        local context = ste:getContext();

        if fd.final then
            if not ste then
                vm.stack.popContext();
                errorf(2, '%s Attempt to assign final field %s outside of Class scope.', cd.printHeader, field);
                return;
            end

            if ste:getCallingClass() ~= cd then
                vm.stack.popContext();
                errorf(2, '%s Attempt to assign final field %s outside of Class scope.', cd.printHeader, field);
                return;
            elseif context ~= 'constructor' then
                vm.stack.popContext();
                errorf(2, '%s Attempt to assign final field %s outside of constructor scope.', cd.printHeader, field);
                return;
            elseif fd.assignedOnce then
                vm.stack.popContext();
                errorf(2, '%s Attempt to assign final field %s. (Already defined)', cd.printHeader, field);
                return;
            end
        end

        -- TODO: Implement generic type-cast checks.

        -- Set the value.
        if fd.static then
            fd.class[field] = value;
        else
            fields[fd.class.path .. '@' .. field] = value;
        end

        vm.stack.popContext();

        -- Apply forward the value metrics.
        fd.assignedOnce = true;
        fd.value = value;
    end

    mt.__eq = vm.class.equals;

    --- @return string text
    mt.__tostring = function()
        return o:toString();
    end

    setmetatable(o, mt);
end

function API.calcPathNamePackage(definition, enclosingDefinition)
    local _, path;
    local name;
    local pkg;

    if enclosingDefinition then
        path = enclosingDefinition.path .. '$' .. definition.name;
        pkg = definition.pkg or enclosingDefinition.pkg;
        if not definition.name then
            error('Name not defined for child class.', 3);
        end
        name = definition.name;
    else
        -- Generate the path to use.
        _, path = vm.scope.getRelativePath();

        -- path = DebugUtils.getPath(4, VM.ROOT_PATH, true);
        local split = path:split('.');
        name = table.remove(split, #split);
        pkg = table.concat(split, '.');

        if definition.pkg then pkg = definition.pkg end
        if definition.name then name = definition.name end

        path = pkg .. '.' .. name;
    end

    return {
        path = path,
        name = name,
        pkg = pkg
    };
end

local mt_reference = {
    __tostring = function(self)
        return string.format('Reference(%s)', self.path);
    end,
    -- __index = function(self)
    --     errorf(2, 'Definition is not initialized: %s', self.path);
    -- end,
    __newindex = function(self)
        errorf(2, 'Definition is not initialized: %s', self.path);
    end,
};

function API.newReference(path)
    return setmetatable({ __type__ = 'StructReference', path = path }, mt_reference);
end

return API;
