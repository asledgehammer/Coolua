---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

-- GENERAL:
-- TODO: Cleanup Code.
-- TODO: (Future) Migrate StackTrace code to Class.

-- ENUM:
-- TODO: Implement.

-- INTERFACE:
-- TODO: Implement.
-- TODO: Implement default methods.
-- TODO: Implement static methods.

-- CLASS:
-- TODO: Implement visibility-scope.
-- TODO: Implement abstract flag.

-- FIELDS:
-- TODO: Implement static fields.

-- METHODS:
-- TODO: Make addMethod() check for override with flags like static, final, and visibility reduction.
-- TODO: Implement abstract flag.

-- CONSTRUCTORS:


local readonly = require 'asledgehammer/util/readonly';
local DebugUtils = require 'asledgehammer/util/DebugUtils';
local OOPUtils = require 'asledgehammer/util/OOPUtils';
local isArray = OOPUtils.isArray;
local anyToString = OOPUtils.anyToString;
local arrayToString = OOPUtils.arrayToString;
local arrayContainsDuplicates = OOPUtils.arrayContainsDuplicates;
local isValidName = OOPUtils.isValidName;
local arrayContains = OOPUtils.arrayContains;
local printf = OOPUtils.printf;
local debugf = OOPUtils.debugf;
local errorf = OOPUtils.errorf;

-- DEBUG FLAGS --
local DEBUG_INTERNAL = false;
local DEBUG_METHODS = false;
local DEBUG_SCOPE = false;
-- ----------- --

---
--- @type table
---
--- Internal value to process definitions not yet assigned.
local UNINITIALIZED_VALUE = { __X_UNIQUE_X__ = true };

--- @type boolean
---
--- This private switch flag helps shadow attempts to get super outside the class framework.
local canGetSuper = false;

--- @type boolean
---
--- This private switch flag helps shadow attempts to set super outside the class framework.
local canSetSuper = false;

--- @param params ParameterDefinition[]
---
--- @return string
local function paramsToString(params)
    local s = '';

    if not params or #params == 0 then return s end

    for i = 1, #params do
        local param = params[i];
        local sTypes = '';
        for j = 1, #param.types do
            if sTypes == '' then
                sTypes = param.types[j];
            else
                sTypes = sTypes .. '|' .. param.types[j];
            end
        end
        local sParam = string.format('%s: %s', param.name, sTypes);
        if s == '' then
            s = sParam;
        else
            s = s .. ', ' .. sParam;
        end
    end

    return s;
end

--- @type ClassContext[]
local ContextStack = {};

--- @param context ClassContext
local function printContext(context)
    if context.executable then
        if context.executable.__type__ == 'MethodDefinition' then
            local callSyntax;
            if context.executable.static then
                callSyntax = '.';
            else
                callSyntax = ':';
            end
            return string.format('%s:%s: calling %s%s%s(%s)',
                context.file,
                context.line,
                context.executable.class.name,
                callSyntax,
                context.executable.name,
                paramsToString(context.executable.parameters)
            );
        else
            return string.format('%s:%s: calling %s.new(%s)',
                context.file,
                context.line,
                context.executable.class.name,
                paramsToString(context.executable.parameters)
            );
        end
    elseif context.field then
        if context.context == 'field-get' then
            return string.format('%s:%s: accessing field %s.%s',
                context.file,
                context.line,
                context.field.class.name,
                context.field.name
            );
        elseif context.context == 'field-set' then
            return string.format('%s:%s: assigning field %s.%s',
                context.file,
                context.line,
                context.field.class.name,
                context.field.name
            );
        end
    end
    return string.format('%s:%s:',
        context.file,
        context.line
    );
end

--- @return string stackTrace
local function printStackTrace()
    local s = 'Class StackTrace:\n\t(Lua Script)';
    for i = 1, #ContextStack do
        s = s .. '\n\t' .. printContext(ContextStack[i]);
    end
    return s;
end

--- Grabs the current context.
local function getContext()
    local stackLen = #ContextStack;
    if stackLen == 0 then
        return nil;
    end
    return ContextStack[stackLen];
end

--- Adds a context to the stack. This happens when constructors or methods are invoked.
---
--- @param context ClassContext
local function pushContext(context)
    debugf(DEBUG_SCOPE, 'pushContext(%s)', printContext(context));
    table.insert(ContextStack, context);
end

local function popContext()
    debugf(DEBUG_SCOPE, 'popContext()');
    local stackLen = #ContextStack;
    if stackLen == 0 then
        error('The ContextStack is empty.', 2);
    end
    return table.remove(ContextStack, stackLen);
end

--- @type table<string, ClassDefinition>
---
--- Classes are stored as their path.
local CLASSES = {};

local function forName(path)
    return CLASSES[path];
end

--- @param val any
---
--- @return type|string
local function getType(val)
    local valType = type(val);

    -- Support for Lua-Class types.
    if valType == 'table' then
        if val.__type__ then
            valType = val.__type__;
        elseif val.type then
            valType = val.type;
        end
    end

    return valType;
end

--- @param class ClassDefinition The class called.
--- @param callInfo CallInfo
---
--- @return ClassScope
local function getScopeForCall(class, callInfo)
    local value = 'public';

    -- Classes are locked to their package path and name.
    local cd = forName(callInfo.path);

    -- - If the class is nil, the call is coming from code outside of a class file entirely.
    -- - If the executable is nil, then the call is coming from code inside of a class but not in a defined method or
    --   constructor.
    if cd then
        -- Grab an executable definition that might be where the call comes from.
        --   NOTE: This allows private access to anonymous functions within the scope of a method.
        --         This is to mimic Java / C# lamda functions getting scoped access to private fields.
        -- local ed = cd:getExecutableFromLine(callInfo.currentLine);
        -- if ed then
        if cd.path == class.path then
            -- The classes match. You have full access to everything.
            value = 'private'
        elseif class:isAssignableFromType(cd) then
            -- The class calling the function is a sub-class and can access protected-scope properties.
            value = 'protected';
        elseif cd.package == class.package then
            -- The class calling the function is in the same package and can access package-scope properties.
            value = 'package';
        end
        -- else
        --     -- We allow anonymous code outside the class system in-file to have package-level access.
        --     if cd.package == class.package then
        --         -- The class calling the function is in the same package and can access package-scope properties.
        --         value = 'package';
        --     end
        -- end
    end

    debugf(DEBUG_SCOPE, 'getScopeCall(%s, %s) = %s',
        class.path, anyToString(callInfo), value
    );

    -- Nothing matches. Only public access.
    return value;
end

--- @param expected ClassScope
--- @param given ClassScope
---
--- @return boolean evaluation
local function canAccessScope(expected, given)
    if expected == given then
        return true;
    else
        if expected == 'public' then
            return true;                  -- Everything allowed.
        elseif expected == 'package' then -- Only protected or private allowed.
            return given == 'protected' or given == 'private';
        else                              -- Only private allowed.
            return given == 'private';
        end
    end
end


local function isAssignableFromType(value, typeOrTypes)
    if getType(typeOrTypes) == 'table' then
        if isArray(typeOrTypes) then
            --- @cast typeOrTypes string[]
            for i = 1, #typeOrTypes do
                if typeOrTypes[i] == 'any' or typeOrTypes[i] == getType(value) then
                    return true;
                end
            end
            return false;
        end
    end
    --- @cast typeOrTypes string
    return getType(value) == typeOrTypes;
end

--- @param args any[]
---
--- @return string explodedArgsString
local function argsToString(args)
    local argsLen = #args;
    if argsLen == 0 then
        return '{}';
    end
    local s = '';
    for i = 1, argsLen do
        local argS = string.format('%i: %s', i, getType(args[i]));
        if s == '' then
            s = argS;
        else
            s = s .. ',\n\t' .. argS;
        end
    end
    return string.format('{\n\t%s\n}', s);
end

--- @param from string
--- @param to string
---
--- @return boolean
local function canCast(from, to)
    -- TODO: Implement inferred class cast type(s).
    return from == to;
end

--- @param from any[]
--- @param to any[]
---
--- @return boolean
local function anyCanCastToTypes(from, to)
    local fromLen = #from;
    local toLen = #to;
    for i = 1, fromLen do
        local a = from[i];
        for j = 1, toLen do
            local b = to[j];
            if canCast(a, b) then
                return true;
            end
        end
    end
    return false;
end

--- @param classDef ClassDefinition
---
--- @return string[] methodNames
local function getDeclaredMethodNames(classDef, array)
    --- @type string[]
    array = array or {};

    local decMethods = classDef.declaredMethods;
    for name, _ in pairs(decMethods) do
        if not arrayContains(array, name) then
            table.insert(array, name);
        end
    end

    return array;
end

--- @type function
local getMethodNames;

--- @param classDef ClassDefinition
--- @param methodNames string[]?
---
--- @return string[] methodNames
getMethodNames = function(classDef, methodNames)
    methodNames = methodNames or {};
    if classDef.superClass then
        getMethodNames(classDef.superClass, methodNames);
    end
    getDeclaredMethodNames(classDef, methodNames);
    return methodNames;
end

local EMPTY_TABLE = {};

--- Defined for all classes so that __eq actually fires.
--- Reference: http://lua-users.org/wiki/MetatableEvents
---
--- @param a Object
--- @param b any
---
--- @return boolean result
local function __class__eq(a, b)
    return a:getClass().__middleMethods['equals'](a, b);
end

--- @param cd ClassDefinition
--- @param o Object
local function createInstanceMetatable(cd, o)
    local mt = getmetatable(o) or {};

    local fields = {};

    -- Copy functions & fields.
    for k, v in pairs(o) do
        if k ~= '__index' then
            fields[k] = v;
        end
    end

    fields.__class__ = cd;

    mt.__index = function(_, field)
        -- Super is to be treated differently / internally.
        if field == '__super__' then
            if not canGetSuper then
                errorf(2, '%s Cannot get __super__. (Internal field)');
            end
            return fields[field];
        elseif field == 'super' then
            return rawget(o, '__super__');
        end

        local fd = cd:getField(field);
        if not fd then
            errorf(2, 'FieldNotFoundException: Field doesn\'t exist: %s.%s',
                cd.path, field
            );
            return;
        end

        local level = 0;
        local relPath = DebugUtils.getPath(level, true);

        while
            relPath == '[C]' or
            relPath == 'asledgehammer.util.DebugUtils' or
            relPath == 'class.ClassDefinition' or
            relPath == 'class.ClassDefinition.lua'
        do
            level = level + 1;
            relPath = DebugUtils.getPath(level, true);
        end

        pushContext({
            class = cd,
            field = fd,
            context = 'field-get',
            line = DebugUtils.getCurrentLine(level),
            file = DebugUtils.getPath(level)
        });

        local callInfo = DebugUtils.getCallInfo(level, true);
        -- callInfo.path = relPath;
        local scopeAllowed = getScopeForCall(fd.class, callInfo);

        if not canAccessScope(fd.scope, scopeAllowed) then
            local errMsg = string.format(
                'IllegalAccessException: The field %s.%s is set as "%s" access level. (Access Level from call: "%s")\n%s',
                cd.name, fd.name,
                fd.scope, scopeAllowed,
                printStackTrace()
            );
            popContext();
            print(errMsg);
            error('', 2);
            return;
        end

        popContext();

        local val = fields[field];
        return val;
    end

    mt.__newindex = function(tbl, field, value)
        -- TODO: Visibility scope analysis.
        -- TODO: Type-checking.

        if field == 'super' then
            if canSetSuper then
                fields.super = value;
            else
                errorf(2, '%s Cannot set super(). (Reserved method)', cd.printHeader);
            end
            return;
        elseif field == '__super__' then
            if canSetSuper then
                fields.__super__ = value;
            else
                errorf(2, '%s Cannot set __super__. (Internal field)', cd.printHeader);
            end
            return;
        end

        local fd = cd:getField(field);
        if not fd then
            errorf(2, 'FieldNotFoundException: Field doesn\'t exist: %s.%s',
                cd.path, field
            );
            return;
        end

        local level = 1;
        local relPath = DebugUtils.getPath(level, true);

        while
            relPath == '[C]' or
            relPath == 'asledgehammer.util.DebugUtils' or
            relPath == 'class.ClassDefinition'
        do
            level = level + 1;
            relPath = DebugUtils.getPath(level, true);
        end

        pushContext({
            class = cd,
            field = fd,
            context = 'field-set',
            line = DebugUtils.getCurrentLine(level),
            file = DebugUtils.getPath(level)
        });

        local callInfo = DebugUtils.getCallInfo(level, true);
        callInfo.path = relPath;
        local scopeAllowed = getScopeForCall(fd.class, callInfo);

        if not canAccessScope(fd.scope, scopeAllowed) then
            local errMsg = string.format(
                'IllegalAccessException: The field %s.%s is set as "%s" access level. (Access Level from call: "%s")\n%s',
                cd.name, fd.name,
                fd.scope, scopeAllowed,
                printStackTrace()
            );
            popContext();
            print(errMsg);
            error('', 2);
            return;
        end

        -- (Just in-case)
        if value == UNINITIALIZED_VALUE then
            local errMsg = string.format('%s Cannot set %s as UNINITIALIZED_VALUE. (Internal Error)\n%s',
                cd.printHeader, field, printStackTrace()
            );
            popContext();
            error(errMsg, 2);
            return;
        end

        local context = getContext();

        if fd.final then
            if not context or context.class ~= cd then
                errorf(2, '%s Attempt to assign final field %s outside of Class scope.', cd.printHeader, field);
            elseif not context or context.context ~= 'constructor' then
                errorf(2, '%s Attempt to assign final field %s outside of constructor scope.', cd.printHeader, field);
            elseif fd.assignedOnce then
                errorf(2, '%s Attempt to assign final field %s. (Already defined)', cd.printHeader, field);
            end
        end

        -- Set the value.
        fields[field] = value;

        -- Apply forward the value metrics.
        fd.assignedOnce = true;
        fd.value = value;
    end

    mt.__eq = __class__eq;

    --- @return string text
    mt.__tostring = function()
        return o:toString();
    end

    setmetatable(o, mt);
end

--- @param paramsA ParameterDefinition[]
--- @param paramsB ParameterDefinition[]
---
--- @return boolean
local methodParamsAreCompatable = function(paramsA, paramsB)
    if #paramsA ~= #paramsB then
        print(string.format('Params length mismatch: #a = %i, #b = %i', #paramsA, #paramsB));
        return false;
    end

    for i = 1, #paramsA do
        local a = paramsA[i];
        local b = paramsB[i];
        if not anyCanCastToTypes(a.types, b.types) then
            return false;
        end
    end

    return true;
end

--- @param cd ClassDefinition
--- @param name string
--- @param methods MethodDefinition[]
---
--- @return fun(o: ClassInstance, ...): (any?)
local function createMiddleMethod(cd, name, methods)
    -- TODO: Implement static invocation.
    return function(o, ...)
        local args = { ... };
        local argsLen = #args;

        --- @type MethodDefinition?
        local md = nil;
        for i = 1, #methods do
            if md then break end
            md = methods[i];
            local parameters = md.parameters or {};
            local paramLen = #parameters;
            if argsLen == paramLen then
                for p = 1, paramLen do
                    local arg = args[p];
                    local parameter = parameters[p];
                    if not isAssignableFromType(arg, parameter.types) then
                        md = nil;
                        break;
                    end
                end
            else
                md = nil;
            end
        end

        local errHeader = string.format('Class(%s):%s():', cd.name, name);

        if not md then
            errorf(2, '%s No method signature exists: %s', errHeader, argsToString(args));
            return;
        end

        pushContext({
            class = cd,
            executable = md,
            context = 'method',
            line = DebugUtils.getCurrentLine(3),
            file = DebugUtils.getPath(3)
        });

        local level = 2;
        local relPath = DebugUtils.getPath(1, true);

        while
            relPath == '[C]' or
            relPath == 'asledgehammer.util.DebugUtils' or
            relPath == 'class.ClassDefinition'
        do
            level = level + 1;
            relPath = DebugUtils.getPath(level, true);
        end

        local callInfo = DebugUtils.getCallInfo(3, true);
        callInfo.path = relPath;
        local scopeAllowed = getScopeForCall(md.class, callInfo);

        if not canAccessScope(md.scope, scopeAllowed) then
            local sParams;
            local callSyntax;
            if md.static then
                sParams = paramsToString(md.parameters);
                callSyntax = '.';
            else
                sParams = paramsToString(md.parameters);
                callSyntax = ':';
            end

            local errMsg = string.format(
                'IllegalAccessException: The method %s%s%s(%s) is set as "%s" access level. (Access Level from call: "%s")\n%s',
                cd.name, callSyntax, md.name, sParams,
                md.scope, scopeAllowed,
                printStackTrace()
            );
            popContext();
            print(errMsg);
            error('', 2);
            return;
        end

        local lastSuper;
        if o then
            --- Apply super.
            canGetSuper = true;
            canSetSuper = true;
            lastSuper = o.super;
            o.super = o.__super__;
            canGetSuper = false;
            canSetSuper = false;
        end

        local retVal = nil;
        local result, errMsg = xpcall(function()
            if md.static then
                retVal = md.func(unpack(args));
            else
                retVal = md.func(o, unpack(args));
            end
        end, debug.traceback);

        if o then
            --- Revert super.
            canSetSuper = true;
            o.super = lastSuper;
            canSetSuper = false;
        end

        -- Audit void type methods.
        if retVal ~= nil and md.returns == 'void' then
            local errMsg = string.format('Invoked Method is void and returned value: {type = %s, value = %s}',
                type(retVal),
                tostring(retVal)
            );
            print(errMsg);
            popContext();
            error('', 2);
            return;
        end

        popContext();

        -- Throw the error after applying context.
        if not result then error(tostring(errMsg) or '') end

        return retVal;
    end;
end

local function createMiddleConstructor(cd)
    return function(o, ...)
        local args = { ... } or {};
        local cons = cd:getDeclaredConstructor(args);

        if not cons then
            errorf(2, '%s No constructor signature exists: %s', cd.printHeader, argsToString(args));
        end

        pushContext({
            class = cd,
            executable = cons,
            context = 'constructor',
            line = DebugUtils.getCurrentLine(3),
            file = DebugUtils.getPath(3)
        });

        local level = 1;
        local relPath = DebugUtils.getPath(0, true);

        while
            relPath == '[C]' or
            relPath == 'asledgehammer.util.DebugUtils' or
            relPath == 'class.ClassDefinition'
        do
            level = level + 1;
            relPath = DebugUtils.getPath(level, true);
        end

        local callInfo = DebugUtils.getCallInfo(3, true);
        callInfo.path = relPath;
        local scopeAllowed = getScopeForCall(cons.class, callInfo);

        if not canAccessScope(cons.scope, scopeAllowed) then
            local errMsg = string.format(
                'IllegalAccessException: The constructor %s.new(%s) is set as "%s" access level. (Access Level from call: "%s")\n%s',
                cons.class.name, paramsToString(cons.parameters),
                cons.scope, scopeAllowed,
                printStackTrace()
            );
            popContext();
            print(errMsg);
            error('', 2);
            return;
        end

        --- Apply super.
        canGetSuper = true;
        canSetSuper = true;
        local lastSuper = o.super;
        o.super = o.__super__;
        canGetSuper = false;
        canSetSuper = false;

        local result, errMsg = xpcall(function()
            cons.func(o, unpack(args));
        end, debug.traceback);

        --- Revert super.
        canSetSuper = true;
        o.super = lastSuper;
        canSetSuper = false;

        popContext();
        if not result then error(errMsg) end
    end
end

--- MiddleSuper instances are created formatted the ClassInstance, not ClassDefinition. This simplifies calls providing
--- the instance as the first argument.
---
--- @param cd ClassDefinition
--- @param o ClassInstance
---
--- @return SuperTable
local function createSuperTable(cd, o)
    local super = {};
    local mt = getmetatable(super) or {};

    -- Assign all middle-functions for the super-class here.
    local properties = {};

    mt.__tostring = function()
        return string.format('SuperTable(%s)', cd.path);
    end

    mt.__index = function(_, key)
        if not properties.__middleMethods[key] then
            errorf(2, '%s No super-method exists: %s', cd.printHeader, tostring(key));
        end
        return properties.__middleMethods[key];
    end;

    -- Make SuperTables readonly.

    function mt.__newindex()
        errorf(2, '%s Cannot modify SuperTable. (readonly)', cd.printHeader);
    end

    local superClass = cd.superClass;
    -- This would only apply to `lua.lang.Object` and any modifications made to it.
    if not superClass then
        -- Nothing to call. Let the implementation know.
        function mt.__call()
            errorf(2, '%s No superclass.', cd.printHeader);
        end

        setmetatable(super, mt);
        return super;
    end

    -- Copy middle-constructor.
    properties.super = super;
    properties.__middleConstructor = cd.__middleConstructor;

    -- Copy middle-methods.
    properties.__middleMethods = {};
    local ssd = superClass;
    while ssd do
        for k, v in pairs(cd.superClass.__middleMethods) do
            properties.__middleMethods[k] = v;
        end
        ssd = ssd.superClass;
    end

    -- Assign / discover the inferred method in the super-class.

    local function __callConstructor(o, args)
        local constructorDefinition = superClass:getConstructor(args);
        if not constructorDefinition then
            errorf(2, '%s Unknown super-constructor: %s', cd.printHeader, argsToString(args));
            return;
        end

        pushContext({
            class = cd,
            executable = constructorDefinition,
            context = 'constructor',
            line = DebugUtils.getCurrentLine(3),
            file = DebugUtils.getPath(3)
        });

        local level = 2;
        local relPath = DebugUtils.getPath(level, true);

        while
            relPath == '[C]' or
            relPath == 'asledgehammer.util.DebugUtils' or
            relPath == 'class.ClassDefinition'
        do
            level = level + 1;
            relPath = DebugUtils.getPath(level, true);
        end

        local callInfo = DebugUtils.getCallInfo(3, true);
        callInfo.path = relPath;
        local scopeAllowed = getScopeForCall(constructorDefinition.class, callInfo);

        if not canAccessScope(constructorDefinition.scope, scopeAllowed) then
            local errMsg = string.format(
                'IllegalAccessException: The constructor %s.new(%s) is set as "%s" access level. (Access Level from call: "%s")\n%s',
                constructorDefinition.class.name, paramsToString(constructorDefinition.parameters),
                constructorDefinition.scope, scopeAllowed,
                printStackTrace()
            );
            popContext();
            print(errMsg);
            error('', 2);
            return;
        end

        local result, errMsg = xpcall(function()
            constructorDefinition.func(o, unpack(args))
        end, debug.traceback);

        popContext();
        if not result then error(errMsg) end
    end

    local function __callMethod(name, args)
        --- @type MethodDefinition|nil
        local md = superClass:getMethod(name, args);

        if not md then
            errorf(2, '%s Unknown super-method: %s %s', cd.printHeader, name, argsToString(args));
            return;
        end

        local level = 2;
        local relPath = DebugUtils.getPath(1, true);

        while
            relPath == '[C]' or
            relPath == 'asledgehammer.util.DebugUtils' or
            relPath == 'class.ClassDefinition'
        do
            level = level + 1;
            relPath = DebugUtils.getPath(level, true);
        end

        local callInfo = DebugUtils.getCallInfo(3, true);
        callInfo.path = relPath;
        local scopeAllowed = getScopeForCall(md.class, callInfo);

        if not canAccessScope(md.scope, scopeAllowed) then
            local sParams;
            local callSyntax;
            if md.static then
                sParams = paramsToString(md.parameters);
                callSyntax = '.';
            else
                sParams = paramsToString(md.parameters);
                callSyntax = ':';
            end

            local errMsg = string.format(
                'IllegalAccessException: The method %s%s%s(%s) is set as "%s" access level. (Access Level from call: "%s")\n%s',
                md.class.name, callSyntax, md.name, sParams,
                md.scope, scopeAllowed,
                printStackTrace()
            );
            popContext();
            print(errMsg);
            error('', 2);
            return;
        end

        local retVal;
        local result, errMsg = xpcall(function()
            if md.static then
                retVal = md.func(unpack(args));
            else
                retVal = md.func(o, unpack(args));
            end
        end, debug.traceback);

        popContext();
        if not result then error(errMsg) end

        return retVal;
    end

    function mt.__call(_, ...)
        local args = { ... };
        table.remove(args, 1);

        local context = getContext();

        -- Make sure that super can only be called in the context of the class.
        if not context then
            errorf(2, '%s No super context.', cd.printHeader);
        end

        if context.context == 'constructor' then
            __callConstructor(o, args);
        elseif context.context == 'method' then
            return __callMethod(context.executable.name, args);
        end
    end

    setmetatable(super, mt);
    return super;
end

--- @param definition ClassDefinitionParameter
local ClassDefinition = function(definition)
    -- Generate the path and name to use.
    local path = DebugUtils.getPath(3, true);
    local split = path:split('.');
    local inferredName = table.remove(split, #split);
    local package = string.join(split, '.');

    local cd = {
        __type__ = 'ClassDefinition',
        package = package,
        scope = definition.scope,
        name = definition.name or inferredName,
        superClass = definition.superClass,
        subClasses = {},
    };

    cd.path = cd.package .. '.' .. cd.name;

    -- Make sure that no class is made twice.
    if forName(cd.path) then
        errorf(2, 'Class is already defined: %s', cd.path);
        return cd; -- NOTE: Useless return. Makes sure the method doesn't say it'll define something as nil.
    end

    cd.type = 'class:' .. cd.path;
    cd.printHeader = string.format('Class(%s):', cd.path);
    cd.declaredFields = {};
    cd.declaredMethods = {};
    cd.declaredConstructors = {};
    cd.lock = false;

    cd.__middleConstructor = createMiddleConstructor(cd);

    if not cd.superClass and cd.path ~= 'lua.lang.Object' then
        cd.superClass = forName('lua.lang.Object');
        if not cd.superClass then
            errorf(2, '%s lua.lang.Object not defined!', cd.errorHeader);
        end
    end

    -- MARK: - new()

    function cd.new(...)
        local errHeader = string.format('Class(%s):new():', cd.name);

        if not cd.lock then
            errorf(2, '%s Cannot invoke constructor. (ClassDefinition is not finalized!)', errHeader);
        end

        -- TODO: Check if package-class exists.

        local o = { __class__ = cd, __type__ = cd.type };

        --- Assign the middle-functions to the object.
        for name, func in pairs(cd.__middleMethods) do
            o[name] = func;
        end

        -- for name, decField in pairs(cd.declaredFields) do
        --     o[name] = decField;
        -- end

        canSetSuper = true;
        o.__super__ = createSuperTable(cd, o);
        canSetSuper = false;

        createInstanceMetatable(cd, o);

        -- Invoke constructor context.
        local args = { ... };
        local result, errMsg = xpcall(function()
            cd.__middleConstructor(o, unpack(args));
        end, debug.traceback);

        if not result then error(errMsg, 2) end

        return o;
    end

    -- MARK: - Field

    --- @param fd FieldDefinitionParameter
    ---
    --- @return FieldDefinition
    function cd:addField(fd)
        -- Friendly check for implementation.
        if not self or not fd then
            error(
                'Improper method call. (Not instanced) Use MyClass:addField() instead of MyClass.addField()',
                2
            );
        end

        --- @type FieldDefinition
        local args = {
            __type__ = 'FieldDefinition',
            class = cd,
            types = fd.types,
            type = fd.type,
            name = fd.name,
            scope = fd.scope or 'package',
            static = fd.static or false,
            final = fd.final or false,
            value = fd.value or UNINITIALIZED_VALUE,
            assignedOnce = false,
        };

        local errHeader = string.format('Class(%s):addField():', cd.name);

        -- Validate name.
        if not args.name then
            error(
                'FieldDefinition: string property "name" is not provided.'
                , 2);
        elseif type(args.name) ~= 'string' then
            error(string.format(
                'FieldDefinition: property "name" is not a valid string. {type=%s, value=%s}',
                type(args.name),
                tostring(args.name)
            ), 2);
        elseif args.name == '' then
            error('FieldDefinition: property "name" is an empty string.');
        elseif not isValidName(args.name) then
            error(string.format(
                'FieldDefinition: property "name" is invalid. (value = %s) (Should only contain A-Z, a-z, 0-9, _, or $ characters)',
                args.name
            ), 2);
        elseif self.declaredFields[args.name] then
            error(string.format(
                'FieldDefinition: field already exists: %s',
                args.name
            ), 2);
        end

        -- Validate types:
        if not args.types and not args.type then
            error(
                'FieldDefinition: string[] property "types" or simplified string property "type" are not provided.'
                , 2);
        elseif args.types then
            if type(args.types) ~= 'table' or not isArray(args.types) then
                error(
                    string.format(
                        'FieldDefinition: property "types" is not a string[]. {type=%s, value=%s}',
                        type(args.types),
                        tostring(args.types)
                    ), 2);
            elseif #args.types == 0 then
                error('FieldDefinition: string[] property "types" is empty. (min=1)', 2);
            elseif arrayContainsDuplicates(args.types) then
                error('FieldDefinition: string[] property "types" contains duplicate types.', 2);
            end
        else
            if type(args.type) ~= 'string' then
                error(string.format(
                    'FieldDefinition: property "type" is not a string. {type=%s, value=%s}',
                    type(args.type),
                    tostring(args.type)
                ), 2);
            elseif args.type == '' then
                error('FieldDefinition: property "type" is an empty string.', 2);
            end
            -- Set the types array and remove the simplified form.
            args.types = { args.type };
            args.type = nil;
        end

        -- Validate value:
        if args.value ~= UNINITIALIZED_VALUE then
            if not isAssignableFromType(args.value, args.types) then
                error(string.format(
                    'FieldDefinition: property "value" is not assignable from "types". {types = %s, value = {type = %s, value = %s}}',
                    arrayToString(args.types),
                    type(args.value),
                    tostring(args.value)
                ), 2);
            end
            args.assignedOnce = true;
        else
            args.assignedOnce = false;
        end

        -- Validate scope:
        if args.scope ~= 'private' and args.scope ~= 'protected' and args.scope ~= 'package' and args.scope ~= 'public' then
            error(string.format(
                'FieldDefinition: ClassScope property "scope" given invalid: %s (Can only be: "private", "protected", "package", or "public")',
                args.scope
            ), 2);
        end

        -- Validate final:
        if type(args.final) ~= 'boolean' then
            error(string.format(
                'FieldDefinition: property "final" is not a boolean. {type = %s, value = %s}',
                getType(args.final),
                tostring(args.final)
            ), 2);
        end

        -- Validate static:
        if type(args.static) ~= 'boolean' then
            error(string.format(
                'FieldDefinition: property "static" is not a boolean. {type = %s, value = %s}',
                getType(args.static),
                tostring(args.static)
            ), 2);
        end

        self.declaredFields[args.name] = args;

        return args;
    end

    --- Attempts to resolve a FieldDefinition in the ClassDefinition. If the field isn't declared for the class level, the
    --- super-class(es) are checked.
    ---
    --- @param name string
    ---
    --- @return FieldDefinition? fieldDefinition
    function cd:getField(name)
        local fd = cd:getDeclaredField(name);
        if not fd and cd.superClass then
            return cd.superClass:getField(name);
        end
        return fd;
    end

    --- Attempts to resolve a FieldDefinition in the ClassDefinition. If the field isn't defined in the class, nil
    --- is returned.
    ---
    --- @param name string
    ---
    --- @return FieldDefinition? fieldDefinition
    function cd:getDeclaredField(name)
        return cd.declaredFields[name];
    end

    -- MARK: - Constructor

    --- @param constructorDefinition ConstructorDefinitionParameter
    --- @param func function
    ---
    --- @return ConstructorDefinition
    function cd:addConstructor(constructorDefinition, func)
        -- Friendly check for implementation.
        if not self or type(constructorDefinition) == 'function' then
            error(
                'Improper method call. (Not instanced) Use MyClass:addConstructor() instead of MyClass.addConstructor()',
                2
            );
        end

        local errHeader = string.format('ClassDefinition(%s):addConstructor():', cd.name);

        if not constructorDefinition then
            error(
                string.format(
                    '%s The constructor definition is not provided.',
                    errHeader
                ),
                2
            );
        end

        --- @type ConstructorDefinition
        local args = {
            __type__ = 'ConstructorDefinition',
            class = cd,
            scope = constructorDefinition.scope or 'package',
            final = constructorDefinition.final or false,
            parameters = constructorDefinition.parameters or {},
            func = func
        };

        if args.parameters then
            if type(args.parameters) ~= 'table' or not isArray(args.parameters) then
                error(
                    string.format(
                        '%s property "parameters" is not a ParameterDefinition[]. {type=%s, value=%s}',
                        errHeader,
                        getType(args.parameters),
                        anyToString(args.parameters)
                    ),
                    2
                );
            end

            -- Convert any simplified type declarations.
            local paramLen = #args.parameters;
            if paramLen then
                for i = 1, paramLen do
                    local param = args.parameters[i];

                    -- Validate parameter name.
                    if not param.name then
                        error(
                            string.format(
                                '%s Parameter #%i doesn\'t have a defined name string.',
                                errHeader,
                                i
                            ), 2
                        );
                    elseif param.name == '' then
                        error(
                            string.format(
                                '%s Parameter #%i has an empty name string.',
                                errHeader,
                                i
                            ),
                            2
                        );
                    end

                    -- Validate parameter type(s).
                    if not param.type and not param.types then
                        error(
                            string.format(
                                '%s Parameter #%i doesn\'t have a defined type string or types string[]. (name = %s)',
                                errHeader,
                                i,
                                param.name
                            ),
                            2
                        );
                    else
                        if param.type and not param.types then
                            param.types = { param.type };
                            param.type = nil;
                        end
                    end
                end
            end
        else
            args.parameters = {};
        end

        --- Validate function.
        if not args.func then
            error(string.format('%s function not provided.', errHeader), 2);
        elseif type(args.func) ~= 'function' then
            error(
                string.format(
                    '%s property "func" provided is not a function. {type = %s, value = %s}',
                    errHeader,
                    getType(args.func),
                    tostring(args.func)
                ), 2);
        end

        table.insert(self.declaredConstructors, args);

        return args;
    end

    --- @param args any[]
    ---
    --- @return ConstructorDefinition|nil constructorDefinition
    function cd:getConstructor(args)
        local cons = self:getDeclaredConstructor(args);
        if not cons and self.superClass then
            cons = self.superClass:getConstructor(args);
        end
        return cons;
    end

    --- @param args any[]
    ---
    --- @return ConstructorDefinition|nil constructorDefinition
    function cd:getDeclaredConstructor(args)
        args = args or EMPTY_TABLE;
        local argsLen = #args;
        local cons = nil;
        for i = 1, #cd.declaredConstructors do
            local decCons = cd.declaredConstructors[i];
            local consParameters = decCons.parameters;
            local consLen = #consParameters;
            if argsLen == consLen then
                cons = decCons;
                for j = 1, #consParameters do
                    local arg = args[j];
                    local parameter = consParameters[j];
                    if not isAssignableFromType(arg, parameter.types) then
                        cons = nil;
                        break;
                    end
                end
            end
        end
        return cons;
    end

    --- @param line integer
    ---
    --- @return ConstructorDefinition|nil method
    function cd:getConstructorFromLine(line)
        --- @type ConstructorDefinition
        local cons;
        for i = 1, #self.declaredConstructors do
            cons = self.declaredConstructors[i];
            if line >= cons.lineRange.start and line <= cons.lineRange.stop then
                return cons;
            end
        end
        return nil;
    end

    -- MARK: - Method

    --- @param methodDefinition MethodDefinitionParameter
    --- @param func function
    function cd:addMethod(methodDefinition, func)
        -- Friendly check for implementation.
        if not self or type(methodDefinition) == 'function' then
            error(
                'Improper method call. (Not instanced) Use MyClass:addMethod() instead of MyClass.addMethod()',
                2
            );
        end

        local errHeader = string.format('Class(%s):addMethod():', cd.name);

        local types = {};
        local returns = methodDefinition.returns;

        -- Validate name.
        if not methodDefinition.name then
            errorf(2, '%s string property "name" is not provided.', errHeader);
        elseif type(methodDefinition.name) ~= 'string' then
            errorf(2, '%s property "name" is not a valid string. {type=%s, value=%s}',
                errHeader, type(methodDefinition.name), tostring(methodDefinition.name)
            );
        elseif methodDefinition.name == '' then
            errorf(2, '%s property "name" is an empty string.', errHeader);
        elseif not isValidName(methodDefinition.name) then
            errorf(2,
                '%s property "name" is invalid. (value = %s) (Should only contain A-Z, a-z, 0-9, _, or $ characters)',
                errHeader, methodDefinition.name
            );
        elseif methodDefinition.name == 'super' then
            errorf(2, '%s cannot name method "super".', errHeader);
        end

        -- Validate parameter type(s).
        if not returns then
            types = { 'void' };
        elseif type(returns) == 'table' then
            --- @cast returns table
            if not isArray(returns) then
                errorf(2, '%s The property "returns" is not a string[] or string[]. {type = %s, value = %s}',
                    errHeader, getType(returns), tostring(returns)
                );
            end
            --- @cast returns string[]
            types = returns;
        elseif type(methodDefinition.returns) == 'string' then
            --- @cast returns string
            types = { returns };
        end

        -- TODO: Implement all definition property checks.

        local lineStart, lineStop = DebugUtils.getFuncRange(func);

        --- @type MethodDefinition
        local args = {
            __type__ = 'MethodDefinition',
            class = cd,
            scope = methodDefinition.scope or 'package',
            static = methodDefinition.static or false,
            final = methodDefinition.final or false,
            parameters = methodDefinition.parameters or {},
            name = methodDefinition.name,
            returns = types,
            override = false,
            super = nil,
            func = func,
            lineRange = { start = lineStart, stop = lineStop },
        };

        if args.parameters then
            if type(args.parameters) ~= 'table' or not isArray(args.parameters) then
                errorf(2, '%s property "parameters" is not a ParameterDefinition[]. {type=%s, value=%s}',
                    errHeader, getType(args.parameters), tostring(args.parameters)
                );
            end

            -- Convert any simplified type declarations.
            local paramLen = #args.parameters;
            if paramLen then
                for i = 1, paramLen do
                    local param = args.parameters[i];

                    -- Validate parameter name.
                    if not param.name then
                        errorf(2, '%s Parameter #%i doesn\'t have a defined name string.', errHeader, i);
                    elseif param.name == '' then
                        errorf(2, '%s Parameter #%i has an empty name string.', errHeader, i);
                    end

                    -- Validate parameter type(s).
                    if not param.type and not param.types then
                        errorf(2, '%s Parameter #%i doesn\'t have a defined type string or types string[]. (name = %s)',
                            errHeader, i, param.name
                        );
                    else
                        if param.type and not param.types then
                            param.types = { param.type };
                            param.type = nil;
                        end
                    end
                end
            end
        else
            args.parameters = {};
        end

        local name = args.name;
        local methodCluster = self.declaredMethods[name];
        if not methodCluster then
            methodCluster = {};
            self.declaredMethods[name] = methodCluster;
        end
        table.insert(methodCluster, args);

        return args;
    end

    function cd:compileMethods()
        debugf(DEBUG_METHODS, '%s Compiling method(s)..', self.printHeader);

        --- @type table<string, MethodDefinition[]>
        self.methods = {};

        local methodNames = getMethodNames(cd);
        for i = 1, #methodNames do
            self:compileMethod(methodNames[i]);
        end

        local keysCount = 0;
        for _, _ in pairs(self.methods) do
            keysCount = keysCount + 1;
        end

        debugf(DEBUG_METHODS, '%s Compiled %i method(s).', self.printHeader, keysCount);
    end

    function cd:compileMethod(name)
        local debugName = self.name .. '.' .. name .. '(...)';

        if not self.superClass then
            debugf(DEBUG_METHODS, '%s Compiling original method(s): %s', self.printHeader, debugName);
            self.methods[name] = OOPUtils.copyArray(self.declaredMethods[name]);
            return;
        end

        debugf(DEBUG_METHODS, '%s Compiling compound method(s): %s', self.printHeader, debugName);

        local decMethods = self.declaredMethods[name];

        -- The current class doesn't have any definitions at all.
        if not decMethods then
            debugf(DEBUG_METHODS, '%s \tUsing super-class array: %s', self.printHeader, debugName);

            -- Copy the super-class array.
            self.methods[name] = OOPUtils.copyArray(self.superClass.methods[name]);
            return;
        end

        -- In this case, all methods with this name are original.
        if not cd.superClass.methods[name] then
            debugf(DEBUG_METHODS, '%s \tUsing class declaration array: %s', self.printHeader, debugName);
            self.methods[name] = OOPUtils.copyArray(decMethods);
            return;
        end

        local methods = OOPUtils.copyArray(cd.superClass.methods[name]);

        if decMethods then
            for i = 1, #decMethods do
                local decMethod = decMethods[i];

                local isOverride = false;

                -- Go through each super-class method.
                for j = 1, #methods do
                    local method = methods[j];

                    if methodParamsAreCompatable(decMethod.parameters, method.parameters) then
                        debugf(DEBUG_METHODS, '%s \t\t@override detected: %s', self.printHeader, debugName);
                        isOverride = true;
                        decMethod.super = method;
                        decMethod.override = true;
                        methods[j] = decMethod;
                        break;
                    end
                end

                --- No overrided method. Add it instead.
                if not isOverride then
                    debugf(DEBUG_METHODS, '%s \t\tAdding class method: %s', self.printHeader, debugName);
                    table.insert(methods, decMethod);
                end
            end
        end
        self.methods[name] = methods;
    end

    --- Attempts to resolve a MethodDefinition in the ClassDefinition. If the method isn't defined in the class, nil
    --- is returned.
    ---
    --- @param name string
    ---
    --- @return MethodDefinition[]? methods
    function cd:getDeclaredMethods(name)
        return cd.declaredMethods[name];
    end

    --- @param name string
    --- @param args any[]
    ---
    --- @return MethodDefinition|nil methodDefinition
    function cd:getMethod(name, args)
        local method = self:getDeclaredMethod(name, args);
        if not method and self.superClass then
            method = self.superClass:getMethod(name, args);
        end
        return method;
    end

    --- @param name string
    --- @param args any[]
    ---
    --- @return MethodDefinition|nil methodDefinition
    function cd:getDeclaredMethod(name, args)
        local argsLen = #args;
        local methods = cd.declaredMethods[name];

        -- No declared methods with name.
        if not methods then
            return nil;
        end

        for i = 1, #methods do
            local method = methods[i];
            local methodParams = method.parameters;
            local paramsLen = #methodParams;
            if argsLen == paramsLen then
                --- Empty args methods.
                if argsLen == 0 then
                    return method;
                else
                    for j = 1, #methodParams do
                        local arg = args[j];
                        local parameter = methodParams[j];
                        if not isAssignableFromType(arg, parameter.types) then
                            method = nil;
                            break;
                        end
                    end
                    if method then return method end
                end
            end
        end
        return nil;
    end

    --- @param line integer
    ---
    --- @return MethodDefinition|nil method
    function cd:getMethodFromLine(line)
        --- @type MethodDefinition
        local md;
        for _, mdc in pairs(self.declaredMethods) do
            for i = 1, #mdc do
                md = mdc[i];
                if line >= md.lineRange.start and line <= md.lineRange.stop then
                    return md;
                end
            end
        end
        return nil;
    end

    -- MARK: - finalize()

    --- @return ClassDefinition class
    function cd:finalize()
        local errHeader = string.format('Class(%s):finalize():', cd.path);

        if self.lock then
            errorf(2, '%s Cannot finalize. (Class is already finalized!)', errHeader);
        elseif self.superClass and not self.superClass.lock then
            errorf(2, '%s Cannot finalize. (SuperClass %s is not finalized!)', errHeader, self.superClass.path);
        end

        -- TODO: Audit everything.

        -- Change methods.
        self.addMethod = function() errorf(2, '%s Cannot add methods. (Class is final!)', errHeader) end
        self.addField = function() errorf(2, '%s Cannot add fields. (Class is final!)', errHeader) end
        self.addConstructor = function() errorf(2, '%s Cannot add constructors. (Class is final!)', errHeader) end

        --- @type table<ParameterDefinition[], function>
        self.__constructors = {};

        --- @type table<string, MethodDefinition[]>
        self:compileMethods();

        -- Set all definitions as read-only.
        local constructorsLen = #self.declaredConstructors;
        if constructorsLen ~= 0 then
            for i = 1, constructorsLen do
                --- @type ConstructorDefinition
                local constructor = self.declaredConstructors[i];
                self.__constructors[constructor.parameters] = constructor.func;

                -- Set read-only.
                self.declaredConstructors[i] = readonly(constructor);
            end
        end

        self.__middleMethods = {};

        -- Insert boilerplate method invoker function.
        for name, methods in pairs(self.methods) do
            self.__middleMethods[name] = createMiddleMethod(cd, name, methods);
        end

        local mt = getmetatable(cd) or {};
        local __properties = {};
        for k, v in pairs(cd) do __properties[k] = v end
        mt.__metatable = false;
        mt.__index = __properties;
        mt.__tostring = function() return 'Class ' .. cd.path end
        mt.__newindex = function() errorf(2, '%s Cannot alter ClassDefinition. It is read-only!', self.errorHeader) end
        setmetatable(cd, mt);

        self.lock = true;
        CLASSES[cd.path] = cd;

        -- Set class as child.
        if cd.superClass then
            table.insert(cd.superClass.subClasses, cd);
        end

        return cd;
    end

    --- @param line integer
    ---
    --- @return ConstructorDefinition|MethodDefinition|nil method
    function cd:getExecutableFromLine(line)
        return self:getMethodFromLine(line) or self:getConstructorFromLine(line) or nil;
    end

    --- @param class ClassDefinition
    ---
    --- @return boolean
    function cd:isSuperClass(class)
        local next = self.superClass;
        while next do
            if next == class then return true end
            next = next.superClass;
        end
        return false;
    end

    --- (Handles recursively going through sub-classes to see if a class is a sub-class)
    ---
    --- @param subClass ClassDefinition
    --- @param classToEval ClassDefinition
    ---
    --- @return boolean result True if the class to evaluate is a super-class of the subClass.
    local function __recurseSubClass(subClass, classToEval)
        local subLen = #cd.subClasses;
        for i = 1, subLen do
            local next = cd.subClasses[i];
            if next:isAssignableFromType(classToEval) or __recurseSubClass(next, classToEval) then
                return true;
            end
        end
        return false;
    end

    --- @param class ClassDefinition The class to evaulate.
    ---
    --- @return boolean result True if the class to evaluate is a super-class of the subClass.
    function cd:isSubClass(class)
        if __recurseSubClass(cd, class) then
            return true;
        end
        return false;
    end

    --- @param class ClassDefinition
    ---
    --- @return boolean
    function cd:isAssignableFromType(class)
        -- TODO: Implement interfaces.
        return self == class or self:isSuperClass(class);
    end

    return cd;
end

return ClassDefinition;
