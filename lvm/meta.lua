---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local PrintPlus = require 'PrintPlus';
local errorf = PrintPlus.errorf;

local DebugUtils = require 'DebugUtils';

--- @type LVM
local LVM;

local API = {

    __type__ = 'LVMModule',

    --- @param lvm LVM
    setLVM = function(lvm)
        LVM = lvm;
        LVM.moduleCount = LVM.moduleCount + 1;
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

        local level, relPath = LVM.scope.getRelativePath();

        LVM.stack.pushContext({
            class = cd,
            element = fd,
            context = 'field-get',
            line = DebugUtils.getCurrentLine(level),
            path = DebugUtils.getPath(level)
        });

        local callInfo = DebugUtils.getCallInfo(level, LVM.ROOT_PATH, true);
        -- callInfo.path = relPath;
        local scopeAllowed = LVM.scope.getScopeForCall(fd.class, callInfo);

        if not LVM.flags.bypassFieldSet and not LVM.scope.canAccessScope(fd.scope, scopeAllowed) then
            local errMsg = string.format(
                'IllegalAccessException: The field %s.%s is set as "%s" access level. (Access Level from call: "%s")\n%s',
                cd.name, fd.name,
                fd.scope, scopeAllowed,
                LVM.stack.printStackTrace()
            );
            LVM.stack.popContext();
            print(errMsg);
            error('', 2);
            return;
        end

        -- TODO: Implement generic type-cast checks.

        LVM.stack.popContext();

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
            if LVM.isOutside() then
                errorf(2, '%s Cannot set super(). (Reserved method)', cd.printHeader);
            end
            fields.super = value;
            return;
        elseif field == '__super__' then
            if LVM.isOutside() then
                errorf(2, '%s Cannot set __super__. (Internal field)', cd.printHeader);
            end
            fields.__super__ = value;
            return;
        elseif field == '__class__' then
            if LVM.isOutside() then
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

        local level, relPath = LVM.scope.getRelativePath();

        LVM.stack.pushContext({
            class = cd,
            element = fd,
            context = 'field-set',
            line = DebugUtils.getCurrentLine(level),
            path = DebugUtils.getPath(level)
        });

        local callInfo = DebugUtils.getCallInfo(level, LVM.ROOT_PATH, true);
        callInfo.path = relPath;
        local scopeAllowed = LVM.scope.getScopeForCall(fd.class, callInfo);

        if not LVM.flags.bypassFieldSet and not LVM.scope.canAccessScope(fd.scope, scopeAllowed) then
            local errMsg = string.format(
                'IllegalAccessException: The field %s.%s is set as "%s" access level. (Access Level from call: "%s")\n%s',
                cd.name, fd.name,
                fd.scope, scopeAllowed,
                LVM.stack.printStackTrace()
            );
            LVM.stack.popContext();
            print(errMsg);
            error('', 2);
            return;
        end

        -- (Just in-case)
        if value == LVM.constants.UNINITIALIZED_VALUE then
            local errMsg = string.format('%s Cannot set %s as UNINITIALIZED_VALUE. (Internal Error)\n%s',
                cd.printHeader, field, LVM.stack.printStackTrace()
            );
            LVM.stack.popContext();
            error(errMsg, 2);
            return;
        end

        local ste = LVM.stack.getContext();

        if not ste then
            LVM.stack.popContext();
            error('Context is nil.', 2);
            return;
        end

        local context = ste:getContext();

        if fd.final then
            if not ste then
                LVM.stack.popContext();
                errorf(2, '%s Attempt to assign final field %s outside of Class scope.', cd.printHeader, field);
                return;
            end

            if ste:getCallingClass() ~= cd then
                LVM.stack.popContext();
                errorf(2, '%s Attempt to assign final field %s outside of Class scope.', cd.printHeader, field);
                return;
            elseif context ~= 'constructor' then
                LVM.stack.popContext();
                errorf(2, '%s Attempt to assign final field %s outside of constructor scope.', cd.printHeader, field);
                return;
            elseif fd.assignedOnce then
                LVM.stack.popContext();
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

        LVM.stack.popContext();

        -- Apply forward the value metrics.
        fd.assignedOnce = true;
        fd.value = value;
    end

    mt.__eq = LVM.class.equals;

    --- @return string text
    mt.__tostring = function()
        return o:toString();
    end

    setmetatable(o, mt);
end

--- @cast API LVMMetaModule

return API;
