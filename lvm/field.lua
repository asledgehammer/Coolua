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
                if fieldDef.get.body then
                    if type(fieldDef.get.body) ~= 'function' then
                        errorf(2,
                            '%s The getter method definition for field "%s" is not a function; {type = %s, value = %s}',
                            self.printHeader,
                            name,
                            LVM.type.getType(fieldDef.get.body),
                            tostring(fieldDef.get.body)
                        );
                    end

                    fGet = fieldDef.get.body;
                else
                    fGet = function(ins)
                        return ins[name];
                    end;
                end
            end

            mGetDef.body = fGet;

            debugf(LVM.debug.method, '%s Creating auto-method: %s:%s()',
                self.printHeader,
                self.name, mGetDef.name
            );

            self:addMethod(mGetDef);
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
                if fieldDef.set.body then
                    if type(fieldDef.get.body) ~= 'function' then
                        errorf(2,
                            '%s The setter method definition for field "%s" is not a function; {type = %s, value = %s}',
                            self.printHeader,
                            name,
                            LVM.type.getType(fieldDef.get.body),
                            tostring(fieldDef.get.body)
                        );
                    end
                    fSet = fieldDef.set.body;
                else
                    fSet = function(ins, value)
                        ins[name] = value;
                    end;
                end
            end

            mSetDef.body = fSet;

            debugf(LVM.debug.method, '%s Creating auto-method: %s:%s',
                self.printHeader,
                self.name, mSetDef.signature
            );

            self:addMethod(mSetDef);
        end
    end
end

return API;
