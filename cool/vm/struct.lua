---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local PrintPlus = require 'cool/print';
local errorf = PrintPlus.errorf;
local debugf = PrintPlus.debugf;

local DebugUtils = require 'cool/debug';

local bypassFields = {
    '__type__',
    '__class__',
    '__struct__',
    '__readonly__',
    'super'
};

local function isBypassField(name)
    for i = 1, #bypassFields do
        if bypassFields[i] == name then return true end
    end
    return false;
end

--- Converts the first character to upper. (Used for get-set shorthand)
---
--- @param str string
---
--- @return string firstCharUpperString
local function firstCharToUpper(str)
    return string.upper(string.sub(str, 1, 1)) .. string.sub(str, 2);
end

--- @type VM
local vm;

--- @type VMStructModule
local API = {

    __type__ = 'VMModule',

    -- Method(s)
    --- @param _vm VM
    setVM = function(_vm)
        vm = _vm;
        vm.moduleCount = vm.moduleCount + 1;
    end
};

--- Defined for all classes so that __eq actually fires.
--- Reference: http://lua-users.org/wiki/MetatableEvents
---
--- @param a Object
--- @param b any
---
--- @return boolean result
function API.equals(a, b)
    vm.stepIn();
    local result = a.__struct__.methods['equals']['equals(any)'].body(a, b);
    vm.stepOut();
    return result;
end

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

        -- Some fields needs bypassing.
        if isBypassField(field) then
            return fields[field];
        end

        local fieldStruct = cd:getField(field);
        if not fieldStruct then
            errorf(2, 'FieldNotFoundException: Field doesn\'t exist: %s.%s',
                cd.path, field
            );
            return;
        end

        local callInfo = vm.scope.getRelativeCall();

        vm.stack.pushContext({
            struct = cd,
            element = fieldStruct,
            context = 'field-get',
            line = callInfo.currentLine,
            path = callInfo.path,
            file = callInfo.file
        });

        if vm.flags.ENABLE_SCOPE then
            local scopeAllowed = vm.scope.getScopeForCall(fieldStruct.struct, callInfo);
            if not vm.flags.bypassFieldSet and not vm.scope.canAccessScope(fieldStruct.scope, scopeAllowed) then
                local errMsg = string.format(
                    'IllegalAccessException: The field %s.%s is set as "%s" access level. (Access Level from call: "%s")\n%s',
                    cd.name, fieldStruct.name,
                    fieldStruct.scope, scopeAllowed,
                    vm.stack.printStackTrace()
                );
                vm.stack.popContext();
                print(errMsg);
                error('', 2);
                return;
            end
        end

        vm.stack.popContext();

        -- Get the value.
        if fieldStruct.static then
            return fieldStruct.struct[field];
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

        local fieldStruct = cd:getField(field);
        if not fieldStruct then
            errorf(2, 'FieldNotFoundException: Field doesn\'t exist: %s.%s',
                cd.path, field
            );
            return;
        end

        local callInfo = vm.scope.getRelativeCall();

        vm.stack.pushContext({
            struct = cd,
            element = fieldStruct,
            context = 'field-set',
            line = callInfo.currentLine,
            path = callInfo.path,
            file = callInfo.file
        });

        if vm.flags.ENABLE_SCOPE then
            local scopeAllowed = vm.scope.getScopeForCall(fieldStruct.struct, callInfo);

            if not vm.flags.bypassFieldSet and not vm.scope.canAccessScope(fieldStruct.scope, scopeAllowed) then
                local errMsg = string.format(
                    'IllegalAccessException: The field %s.%s is set as "%s" access level. (Access Level from call: "%s")\n%s',
                    cd.name, fieldStruct.name,
                    fieldStruct.scope, scopeAllowed,
                    vm.stack.printStackTrace()
                );
                vm.stack.popContext();
                print(errMsg);
                error('', 2);
                return;
            end
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

        if fieldStruct.final then
            if not ste then
                vm.stack.popContext();
                errorf(2, '%s Attempt to assign final field %s outside of Class scope.', cd.printHeader, field);
                return;
            end

            if ste:getCallingStruct() ~= cd then
                vm.stack.popContext();
                errorf(2, '%s Attempt to assign final field %s outside of Class scope.', cd.printHeader, field);
                return;
            elseif context ~= 'constructor' then
                vm.stack.popContext();
                errorf(2, '%s Attempt to assign final field %s outside of constructor scope.', cd.printHeader, field);
                return;
            elseif fieldStruct.assignedOnce then
                vm.stack.popContext();
                errorf(2, '%s Attempt to assign final field %s. (Already defined)', cd.printHeader, field);
                return;
            end
        end

        -- Set the value.
        if fieldStruct.static then
            fieldStruct.struct[field] = value;
        else
            fields[fieldStruct.struct.path .. '@' .. field] = value;
        end

        vm.stack.popContext();

        -- Apply forward the value metrics.
        fieldStruct.assignedOnce = true;
        fieldStruct.value = value;
    end

    mt.__eq = vm.struct.equals;

    --- @return string text
    mt.__tostring = function()
        return o:toString();
    end

    setmetatable(o, mt);
end

function API.compileFieldAutoMethods(struct)
    for _, fieldDef in pairs(struct.declaredFields) do
        local funcName = firstCharToUpper(fieldDef.name);
        local tGet = type(fieldDef.get);
        local tSet = type(fieldDef.set);

        --- @type function, function
        local fGet, fSet;

        if tGet ~= 'nil' then
            local name = fieldDef.get.name or ('get' .. funcName);
            local mGetDef = {
                name = name,
                scope = fieldDef.scope,
                returnTypes = fieldDef.types
            };

            -- (Instance getter method(s) passes their instance as the first argument)
            if not fieldDef.static then
                mGetDef.parameters = {
                    { name = 'self', type = struct }
                };
            end

            if tGet == 'boolean' then

            elseif tGet == 'table' then
                if fieldDef.get.scope then
                    mGetDef.scope = fieldDef.get.scope;
                end
                if fieldDef.get.body then
                    if type(fieldDef.get.body) ~= 'function' then
                        errorf(2,
                            '%s The getter method definition for field "%s" is not a function; {type = %s, value = %s}',
                            struct.printHeader,
                            name,
                            vm.type.getType(fieldDef.get.body),
                            tostring(fieldDef.get.body)
                        );
                    end

                    fGet = fieldDef.get.body;
                else
                    if fieldDef.static then
                        fGet = function()
                            return struct[fieldDef.name];
                        end
                    else
                        fGet = function(ins)
                            return ins[fieldDef.name];
                        end;
                    end
                end
            end

            mGetDef.body = fGet;

            debugf(vm.debug.method, '[METHOD] :: %s Creating auto-method: %s:%s()',
                struct.printHeader,
                struct.name, mGetDef.name
            );

            struct:addMethod(mGetDef);
        end

        if tSet ~= 'nil' then
            if fieldDef.final then
                errorf(2, '%s Cannot add setter to final field: %s',
                    struct.printHeader,
                    fieldDef.name
                );
            end
            local name = fieldDef.set.name or ('set' .. funcName);
            local mSetDef = {
                name = name,
                scope = fieldDef.scope,
                parameters = {
                    { name = 'value', types = fieldDef.types }
                }
            };

            -- (Instance setter method(s) passes their instance as the first argument)
            if not fieldDef.static then
                mSetDef.parameters = {
                    { name = 'self', type = struct }
                };
            end

            if tSet == 'table' then
                if fieldDef.set.scope then
                    mSetDef.scope = fieldDef.set.scope;
                end
                if fieldDef.set.body then
                    if type(fieldDef.get.body) ~= 'function' then
                        errorf(2,
                            '%s The setter method definition for field "%s" is not a function; {type = %s, value = %s}',
                            struct.printHeader,
                            name,
                            vm.type.getType(fieldDef.get.body),
                            tostring(fieldDef.get.body)
                        );
                    end
                    fSet = fieldDef.set.body;
                else
                    if fieldDef.static then
                        fSet = function()
                            return struct[fieldDef.name];
                        end
                    else
                        fSet = function(ins)
                            return ins[fieldDef.name];
                        end;
                    end
                end
            end

            mSetDef.body = fSet;

            debugf(vm.debug.method, '[METHOD] :: %s Creating auto-method: %s(...)',
                struct.printHeader,
                mSetDef.name
            );

            local md = struct:addMethod(mSetDef);

            debugf(vm.debug.method, '[METHOD] :: %s Created auto-method: %s',
                struct.printHeader,
                md.signature
            );
        end
    end
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
        local callInfo = vm.scope.getRelativeCall();

        -- path = DebugUtils.getPath(4, VM.ROOT_PATH, true);
        local split = callInfo.path:split('.');
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
    --     errorf(2, 'Struct is not initialized: %s', self.path);
    -- end,
    __newindex = function(self)
        errorf(2, 'Struct is not initialized: %s', self.path);
    end,
};

function API.newReference(path)
    return setmetatable({ __type__ = 'StructReference', path = path }, mt_reference);
end

return API;
