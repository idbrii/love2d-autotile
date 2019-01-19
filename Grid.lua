
local Grid = {}
Grid.__index = Grid 

-- Creates and returns a new grid
function Grid:new()
	local grid = {}
	grid.cells = {}
	grid.cells.mt = {__mode = ""}
	return setmetatable(grid, Grid)
end

-- Weakens the grid's cells so the garbage collecter can delete their contents if they have no
-- other references.
function Grid:weaken()
	self.cells.mt.__mode = "v"
	for key,row in pairs(self.cells) do
		setmetatable(row,self.cells.mt)
	end
end

-- Unweakens the grid
function Grid:unweaken()
	self.cells.mt.__mode = ""
	for key,row in pairs(self.cells) do
		setmetatable(row,self.cells.mt)
	end
end

-- Gets the value of a single cell
function Grid:get(x,y)
	return self.cells[x] and self.cells[x][y] or nil
end

-- Sets the value of a single cell
function Grid:set(x,y,value)
	if not self.cells[x] then 
		self.cells[x] = setmetatable({}, self.cells.mt)
	end
	self.cells[x][y] = value
end

-- Sets all of the cells in an area to the same value
function Grid:setArea(startX, startY, endX, endY, value)
	for x = startX,endX do
		for y = startY,endY do
			self:set(x,y,value)
		end
	end
end

-- Iterate over all values
function Grid:iterate()
	local x, row = next(self.cells)
	local y, val
	return function()
		repeat
			y,val = next(row,y)
			if y == nil then x,row = next(self.cells, x) end
		until (val and x and y and type(x)=="number") or (not val and not x and not y)
		return x,y,val
	end
end

-- Iterate over a rectangle shape
function Grid:rectangle(startX, startY, endX, endY, includeNil)
	local x, y = startX, startY
	return function()
		while y <= endY do
			while x <=endX do
				x = x+1
				if self(x-1,y) ~= nil or includeNil then 
					return x-1, y, self(x-1,y)
				end
			end
			x = startX
			y = y+1
		end
		return nil
	end
end

-- Iterate over a line. Set noDiag to true to keep from traversing diagonally.
function Grid:line(startX, startY, endX, endY, noDiag, includeNil)	
    local dx = math.abs(endX - startX)
    local dy = math.abs(endY - startY)
    local x = startX
    local y = startY
    local incrX = endX > startX and 1 or -1 
    local incrY = endY > startY and 1 or -1 
    local err = dx - dy
	local err2 = err*2
	local i = 1+dx+dy
	local rx,ry,rv 
	local checkX = false
	return function()
		while i>0 do 
			rx,ry,rv = x,y,self(x,y)
			err2 = err*2
			while true do
				checkX = not checkX		
				if checkX == true or not noDiag then 
					if err2 > -dy then
						err = err - dy
						x = x + incrX
						i = i-1
						if noDiag then break end
					end
				end
				if checkX == false or not noDiag then
					if err2 < dx then
						err = err + dx
						y = y + incrY
						i = i-1
						if noDiag then break end
					end
				end
				if not noDiag then break end
			end
			if rx == endX and ry == endY then i = 0 end
			if rv ~= nil or includeNil then return rx,ry,rv end
		end
		return nil
	end
end
			
-- Iterates over a circle of cells
function Grid:circle(cx, cy, r, includeNil, outline)
	cx,cy,r = math.floor(cx), math.floor(cy), math.floor(r)
	local x, y = 0, r
	local err = 1 - r
	local errX = 1
	local errY = -2 * r
	local points = {}

	local function addPoint(x,y)
		if not points[x] then points[x] = {} end
		points[x][y] = true
	end
	
	if not outline then
		for i = cx-r, cx+r do
			addPoint(i, cy)
		end
	else
		addPoint(cx, cy + r)
		addPoint(cx, cy - r);
		addPoint(cx + r, cy);
		addPoint(cx - r, cy);
	end
	
	while(x < y) do
		if(err >= 0)  then
			y = y-1
			errY = errY + 2
			err = err + errY
		end
		x = x+1
		errX = errX + 2;
		err = err + errX;    
			
		if not outline then 
			for i = cx - x, cx + x do
				addPoint(i, cy + y)
				addPoint(i, cy - y)
			end
			for i = cx - y, cx + y do
				addPoint(i, cy + x)
				addPoint(i, cy - x)
			end
		else
			addPoint(cx + x, cy + y);
			addPoint(cx - x, cy + y);
			addPoint(cx + x, cy - y);
			addPoint(cx - x, cy - y);
			addPoint(cx + y, cy + x);
			addPoint(cx - y, cy + x);
			addPoint(cx + y, cy - x);
			addPoint(cx - y, cy - x);
		end
	end
	
	x = next(points)
	y = next(points[x])
	
	return function()
		while(x) do
			while(y) do
				cy = y
				y = next(points[x], y)
				print( "returning " .. x or "nil" .. "," .. y or "nil")
				if includeNil or self(x,cy) ~= nil then return x, cy, self(x,cy) end
			end
			x = next(points, x)
			y = next(points[x] or {})
		end
		return nil
	end
	
end

--[[
-- Tries to find the shortest path from (sx,sy) to (ex,ey) using an A* algorithm. 
function Grid:Astar(sx,sy,ex,ey,calcG,calcH)

	local G = Grid:new()	-- The cost it takes to get to a node from the starting node.
	local H = Grid:new()	-- The estimated cost it takes to get from a node to the ending node.
	
	-- The calcG function should return the cost of moving from one node to an adjacent node.
	-- It can return false is movement is not possible.
	--
	-- This default simply returns 1 if the nodes are horizontally or vertically adjacent. 
	-- If the nodes are diagonal from each other or the end node's value does not test true then 
	-- false is returned to show that movement is not possible.
	if not calcG then calcG = function(sx,sy,sv,ex,ey,ev)
		local adjacent = math.abs(sx-ex) + math.abs(sy+ey) == 1
		if adjacent and ev then return 1 else return false end
	end
	
	-- The calcH function returns the estimated cost of moving from a node to the 
	-- destination node. The more accurate the guess, the faster the overall algorithm will be.
	--
	-- This default uses the Manhatten method. It simply finds the distance from a node to the 
	-- desination node if it could only travel vertically or horizontally.
	if not calcH then calcH = function(sx,sy,sv,ex,ey,ev)
		return math.abs(sx-ex) + math.abs(sy+ey)
	end
	
end
--]]

-- Cleans the grid of empty rows. 
function Grid:clean()
	for key,row in pairs(self.cells) do
		if not next(row) then self.cells[key] = nil end
	end
end

-- This makes calling the grid as a function act like Grid.get.
Grid.__call = Grid.get

-- Returns the grid class
return Grid