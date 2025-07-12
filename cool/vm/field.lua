---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local dump      = require 'cool/dump';
local PrintPlus = require 'cool/print';
local errorf    = PrintPlus.errorf;
local debugf    = PrintPlus.debugf;

--- Converts the first character to upper. (Used for get-set shorthand)
---
--- @param str string
---
--- @return string firstCharUpperString
local function firstCharToUpper(str)
    return string.upper(string.sub(str, 1, 1)) .. string.sub(str, 2);
end

--- @type VM
local VM;

local API = {

    __type__ = 'VMModule',

    --- @param vm VM
    setVM = function(vm)
        VM = vm;
        VM.moduleCount = VM.moduleCount + 1;
    end
};

--- @cast API VMFieldModule

--- @param self ClassStructDefinition|InterfaceStructDefinition
function API.compileFieldAutoMethods(self)
    for _, fieldDef in pairs(self.declaredFields) do
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
                            VM.type.getType(fieldDef.get.body),
                            tostring(fieldDef.get.body)
                        );
                    end

                    fGet = fieldDef.get.body;
                else
                    if fieldDef.static then
                        fGet = function()
                            return self[fieldDef.name];
                        end
                    else
                        fGet = function(ins)
                            return ins[fieldDef.name];
                        end;
                    end
                end
            end

            mGetDef.body = fGet;

            debugf(VM.debug.method, '[METHOD] :: %s Creating auto-method: %s:%s()',
                self.printHeader,
                self.name, mGetDef.name
            );

            self:addMethod(mGetDef);
        end

        if tSet ~= 'nil' then
            if fieldDef.final then
                errorf(2, '%s Cannot add setter to final field: %s',
                    self.printHeader,
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
                            VM.type.getType(fieldDef.get.body),
                            tostring(fieldDef.get.body)
                        );
                    end
                    fSet = fieldDef.set.body;
                else
                    if fieldDef.static then
                        fSet = function()
                            return self[fieldDef.name];
                        end
                    else
                        fSet = function(ins)
                            return ins[fieldDef.name];
                        end;
                    end
                end
            end

            mSetDef.body = fSet;

            debugf(VM.debug.method, '[METHOD] :: %s Creating auto-method: %s(...)',
                self.printHeader,
                mSetDef.name
            );

            local md = self:addMethod(mSetDef);

            debugf(VM.debug.method, '[METHOD] :: %s Created auto-method: %s',
                self.printHeader,
                md.signature
            );
        end
    end
end

return API;
