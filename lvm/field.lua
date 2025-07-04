---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local LVMUtils = require 'LVMUtils';
-- local anyToString = LVMUtils.anyToString;
local arrayContainsDuplicates = LVMUtils.arrayContainsDuplicates;
local arrayToString = LVMUtils.arrayToString;
local debugf = LVMUtils.debugf;
local errorf = LVMUtils.errorf;
local isArray = LVMUtils.isArray;
local isValidName = LVMUtils.isValidName;
local firstCharToUpper = LVMUtils.firstCharToUpper;
local readonly = LVMUtils.readonly;

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

--- @cast API LVMFieldModule

--- @param self ClassStructDefinition|InterfaceStructDefinition
function API.compileFieldAutoMethods(self)
    for name, fieldDef in pairs(self.declaredFields) do
        local funcName = firstCharToUpper(fieldDef.name);
        local tGet = type(fieldDef.get);
        local tSet = type(fieldDef.set);

        --- @type function, function
        local fGet, fSet;

        if tGet ~= 'nil' then
            local mGetDef = {
                name = 'get' .. funcName,
                scope = fieldDef.scope,
                returns = fieldDef.types
            };

            if tGet == 'boolean' then

            elseif tGet == 'table' then
                if fieldDef.get.scope then
                    mGetDef.scope = fieldDef.get.scope;
                end
                if fieldDef.get.func then
                    if type(fieldDef.get.func) ~= 'function' then
                        errorf(2,
                            '%s The getter method definition for field "%s" is not a function; {type = %s, value = %s}',
                            self.printHeader,
                            name,
                            LVM.type.getType(fieldDef.get.func),
                            tostring(fieldDef.get.func)
                        );
                    end

                    fGet = fieldDef.get.func;
                else
                    fGet = function(ins)
                        return ins[name];
                    end;
                end
            end

            debugf(LVM.debug.method, '%s Creating auto-method: %s:%s()',
                self.printHeader,
                self.name, mGetDef.name
            );

            self:addMethod(mGetDef, fGet);
        end

        if tSet ~= 'nil' then
            local mSetDef = {
                name = 'set' .. funcName,
                scope = fieldDef.scope,
                parameters = {
                    { name = 'value', types = fieldDef.types }
                }
            };

            if tSet == 'table' then
                if fieldDef.set.scope then
                    mSetDef.scope = fieldDef.set.scope;
                end
                if fieldDef.set.func then
                    if type(fieldDef.get.func) ~= 'function' then
                        errorf(2,
                            '%s The setter method definition for field "%s" is not a function; {type = %s, value = %s}',
                            self.printHeader,
                            name,
                            LVM.type.getType(fieldDef.get.func),
                            tostring(fieldDef.get.func)
                        );
                    end
                    fSet = fieldDef.set.func;
                else
                    fSet = function(ins, value)
                        ins[name] = value;
                    end;
                end
            end

            debugf(LVM.debug.method, '%s Creating auto-method: %s:%s',
                self.printHeader,
                self.name, mSetDef.signature
            );

            self:addMethod(mSetDef, fSet);
        end
    end
end

return API;
