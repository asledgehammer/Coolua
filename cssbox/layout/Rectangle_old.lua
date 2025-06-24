-- local class = require 'asledgehammer/util/class';

-- -- MARK: - Constructors

-- --- @param o Rectangle
-- local function constructorEmpty(o)
--     o.x = 0;
--     o.y = 0;
--     o.width = 0;
--     o.height = 0;
-- end

-- --- @param o Rectangle
-- --- @param src Rectangle
-- local function constructorOther(o, src)
--     o.x = src.x;
--     o.y = src.y;
--     o.width = src.width;
--     o.height = src.height;
-- end

-- --- @param o Rectangle
-- --- @param src Dimension
-- local function constructorDimension(o, src)
--     o.x = 0;
--     o.y = 0;
--     o.width = src.width;
--     o.height = src.height;
-- end

-- --- @param o Rectangle
-- --- @param width number
-- --- @param height number
-- local function constructorWidthHeight(o, width, height)
--     o.x = 0;
--     o.y = 0;
--     o.width = width;
--     o.height = height;
-- end

-- --- @param o Rectangle
-- --- @param x number
-- --- @param y number
-- --- @param width number
-- --- @param height number
-- local function constructorXYWidthHeight(o, x, y, width, height)
--     o.x = x;
--     o.y = y;
--     o.width = width;
--     o.height = height;
-- end

-- local function constructorError(arg1, arg2, arg3, arg4)
--     error(
--         string.format(
--             'Unknown Rectangle constructor: (arg1={type=%s,value=%s},arg1={type=%s,value=%s},arg1={type=%s,value=%s},arg1={type=%s,value=%s})',
--             type(arg1), tostring(arg1),
--             type(arg2), tostring(arg2),
--             type(arg3), tostring(arg3),
--             type(arg4), tostring(arg4)
--         ), 2
--     );
-- end

-- local Rectangle = class(
-- --- @param o Rectangle
-- --- @param arg1 Rectangle|Dimension|number
-- --- @param arg2 number?
-- --- @param arg3 number?
-- --- @param arg4 number?
--     function(o, arg1, arg2, arg3, arg4)
--         o.type = 'Rectangle';
--         if type(arg1) == 'table' then
--             if o.type == 'Rectangle' then
--                 --- @cast arg1 Rectangle
--                 constructorOther(o, arg1);
--             elseif o.type == 'Dimension' then
--                 --- @cast arg1 Dimension
--                 constructorDimension(o, arg1);
--             else
--                 constructorError(arg1, arg2, arg3, arg4);
--             end
--         else
--             if arg1 ~= nil and arg2 ~= nil and arg3 ~= nil and arg4 ~= nil then
--                 --- @cast arg1 number
--                 constructorXYWidthHeight(o, arg1, arg2, arg3, arg4);
--             elseif arg1 ~= nil and arg2 ~= nil and arg3 == nil and arg4 == nil then
--                 --- @cast arg1 number
--                 constructorWidthHeight(o, arg1, arg2);
--             elseif arg1 == nil and arg2 == nil and arg3 == nil and arg4 == nil then
--                 constructorEmpty(o);
--             else
--                 constructorError(arg1, arg2, arg3, arg4);
--             end
--         end
--     end
-- );

-- -- MARK: - Methods

-- function Rectangle:getX()
--     return self.x;
-- end

-- function Rectangle:setX(x)
--     self.x = x;
-- end

-- function Rectangle:getY()
--     return self.y;
-- end

-- function Rectangle:setY(x)
--     self.y = y;
-- end

-- function Rectangle:getWidth()
--     return self.width;
-- end

-- function Rectangle:setWidth(width)
--     self.width = width;
-- end

-- function Rectangle:getHeight()
--     return self.height;
-- end

-- function Rectangle:setHeight(height)
--     self.height = height;
-- end

-- --- @param x number
-- --- @param y number
-- function Rectangle:setLocation(x, y)
--     self.x = x;
--     self.y = y;
-- end

-- --- @param width number
-- --- @param height number
-- function Rectangle:setSize(width, height)
--     self.width = width;
--     self.height = height;
-- end

-- --- @return Dimension
-- function Rectangle:getSize()
--     return Dimension(self.width, self.height);
-- end

-- --- @param x number
-- --- @param y number
-- ---
-- --- @return boolean
-- function Rectangle:contains(x, y)
--     if self.width <= 0 or self.height <= 0 then
--         return false;
--     end
--     return x >= self.x and x < self.x + self.width and y >= self.y and y < self.y + self.height;
-- end

-- --- @param r Rectangle
-- ---
-- --- @returns boolean testResult
-- function Rectangle:intersects(r)
--     local tw = self.width;
--     local th = self.height;
--     local rw = r.width;
--     local rh = r.height;
--     if rw <= 0 or rh <= 0 or tw <= 0 or th <= 0 then
--         return false;
--     end
--     local tx = self.x;
--     local ty = self.y;
--     local rx = r.x;
--     local ry = r.y;
--     rw = rw + rx;
--     rh = rh + ry;
--     tw = tw + tx;
--     th = th + ty;
--     --      overflow || intersect
--     return ((rw < rx or rw > tx) or
--         (rh < ry or rh > ty) or
--         (tw < tx or tw > rx) or
--         (th < ty or th > ry));
-- end

-- --- @param r Rectangle
-- ---
-- --- @return Rectangle
-- function Rectangle:intersection(r)
--     local tx1 = self.x;
--     local ty1 = self.y;
--     local rx1 = r.x;
--     local ry1 = r.y;
--     local tx2 = tx1; tx2 = tx2 + self.width;
--     local ty2 = ty1; ty2 = ty2 + self.height;
--     local rx2 = rx1; rx2 = rx2 + r.width;
--     local ry2 = ry1; ry2 = ry2 + r.height;
--     if tx1 < rx1 then tx1 = rx1 end
--     if ty1 < ry1 then ty1 = ry1 end
--     if tx2 > rx2 then tx2 = rx2 end
--     if ty2 > ry2 then ty2 = ry2 end
--     tx2 = tx2 - tx1;
--     ty2 = ty2 - ty1;
--     return Rectangle(tx1, ty1, tx2, ty2);
-- end

-- function Rectangle:__tostring()
--     return string.format(
--         "Rectangle[x=%.4f, y=%.4f, width=%.4f, height=%.4f]",
--         self.x, self.y, self.width, self.height
--     );
-- end

-- return Rectangle;
