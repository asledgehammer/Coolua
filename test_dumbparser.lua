local parser = require "dumbParser";

local tokens = parser.tokenizeFile("test_dumbparser_func.lua");
local ast    = parser.parse(tokens)

-- parser.simplify(ast)
-- parser.printTree(ast)

-- local lua = parser.toLua(ast, true)
-- print(lua)

local dump = require 'cool/dump';

-- for k,v in pairs(ast.statements[1].token) do
--     print(k, v);
-- end

-- print(dump.any(ast, {pretty = true}));

parser.traverseTree(ast, function (node, parent, container, key)
    if node.type == 'function' then
        print(dump.any(node));
    end
    
end);