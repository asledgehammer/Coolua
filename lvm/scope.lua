---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local DebugUtils = require 'DebugUtils';

local LVMUtils = require 'LVMUtils';
local anyToString = LVMUtils.anyToString;
local debugf = LVMUtils.debugf;

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

--- @cast API LVMScopeModule

function API.getScopeForCall(struct, callInfo)
    local value = 'public';

    -- Classes are locked to their package path and name.
    local callStruct = LVM.forNameDef(callInfo.path);


    if callStruct then
        
        local ed = LVM.executable.getExecutableFromLine(struct, callInfo.path, callInfo.currentLine);
        if ed then
            -- Inside struct definition. Can access everything in struct.
            value = 'private';
        else
            -- Grab an executable definition that might be where the call comes from.
            --   NOTE: This allows private access to anonymous functions within the scope of a method.
            --         This is to mimic Java / C# lamda functions getting scoped access to private fields.
            -- local ed = cd:getExecutableFromLine(callInfo.currentLine);
            -- if ed then
            if callStruct.path == struct.path then
                -- The classes match. You have full access to everything.
                value = 'private'
            elseif struct:isAssignableFromType(callStruct) then
                -- The class calling the function is a sub-class and can access protected-scope properties.
                value = 'protected';
            elseif callStruct.pkg == struct.pkg then
                -- The class calling the function is in the same package and can access package-scope properties.
                value = 'package';
            end
        end

    end


    -- - If the class is nil, the call is coming from code outside of a class file entirely.
    -- - If the executable is nil, then the call is coming from code inside of a class but not in a defined method or
    --   constructor.
    if callStruct then
        -- Grab an executable definition that might be where the call comes from.
        --   NOTE: This allows private access to anonymous functions within the scope of a method.
        --         This is to mimic Java / C# lamda functions getting scoped access to private fields.
        -- local ed = cd:getExecutableFromLine(callInfo.currentLine);
        -- if ed then
        if callStruct.path == struct.path then
            -- The classes match. You have full access to everything.
            value = 'private'
        elseif struct:isAssignableFromType(callStruct) then
            -- The class calling the function is a sub-class and can access protected-scope properties.
            value = 'protected';
        elseif callStruct.pkg == struct.pkg then
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

    debugf(LVM.debug.scope, '[SCOPE] :: getScopeCall(%s, %s) = %s',
        struct.path, anyToString(callInfo), value
    );

    -- Nothing matches. Only public access.
    return value;
end

function API.canAccessScope(expected, given)
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

function API.getRelativePath()
    local level = 1;
    local relPath = DebugUtils.getPath(level, LVM.ROOT_PATH, true);

    while
        relPath == '[C]' or
        relPath == 'DebugUtils' or
        relPath == 'LVM' or
        relPath == 'LVMUtils' or
        relPath == 'LuaClass' or
        relPath == 'LuaClassBuilder' or
        relPath:startsWith('lvm.')
    do
        level = level + 1;
        relPath = DebugUtils.getPath(level, LVM.ROOT_PATH, true);
    end

    local testDot = string.find(relPath, '.', 1, true);
    
    if testDot == 1 then
        relPath = relPath:sub(2);
    end

    return level, relPath;
end

return API;
