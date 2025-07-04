--- @meta

--- @class SimpleInterfaceDefinition: InterfaceStructDefinition
local SimpleInterfaceDefinition = {};
function SimpleInterfaceDefinition.aStaticMethod() end

--- @class SimpleInterface: InterfaceInstance
local SimpleInterface = {};

function SimpleInterface.aStaticMethod() end
function SimpleInterface:aMethod() end
function SimpleInterface:bMethod() end
