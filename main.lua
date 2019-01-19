
local floorImage = love.graphics.newImage("Floor.png")		 -- Pure grass tile	
local autotileImage = love.graphics.newImage("Autotile.png") -- Autotile image
local width = autotileImage:getWidth()		-- Image width
local height = autotileImage:getHeight()	-- Image height
local size = 32								-- Tile size
local hsize = math.floor(size/2)			-- Half tile size

-- Chunk arrays
local chunk = {TL={}, TR={}, BL={}, BR={}}

-- Island tile
chunk.island = love.graphics.newQuad(0, 0, size, size, width, height)

-- This cuts a tile into chunks
local function cutTile(x,y)
	local TL = love.graphics.newQuad(x, y, hsize, hsize, width, height)
	local TR = love.graphics.newQuad(x+hsize, y, hsize, hsize, width, height)
	local BL = love.graphics.newQuad(x, y+hsize, hsize, hsize, width, height)
	local BR = love.graphics.newQuad(x+hsize, y+hsize, hsize, hsize, width, height)
	return TL,TR,BL,BR
end

-- Cut out the chunks and index them by their adjacent tile value
chunk.TL[3], chunk.TR[3], chunk.BL[3], chunk.BR[3] = cutTile(size,0)
chunk.TL[0], chunk.TR[2], chunk.BL[1], chunk.BR[4] = cutTile(0,size)
chunk.TL[1], chunk.TR[0], chunk.BL[4], chunk.BR[2] = cutTile(size, size)
chunk.TL[2], chunk.TR[4], chunk.BL[0], chunk.BR[1] = cutTile(0, size*2)
chunk.TL[4], chunk.TR[1], chunk.BL[2], chunk.BR[0] = cutTile(size, size*2)

-- A 2-d grid used to represent connected tiles. Values can either contain true for
-- connected tiles or nil for unconnected tiles.
local grid = {}

-- This function calculates the adjacent tile values and draws the autotile
function drawAutotile(x,y)

	-- Calculate the adjacent tile values for each chunk
	local val = {TL=0, TR=0, BL=0, BR=0}

	if grid[x] and grid[x][y-1] then val.TL = val.TL + 2; val.TR = val.TR + 1 end	-- top
	if grid[x] and grid[x][y+1] then val.BL = val.BL + 1; val.BR = val.BR + 2 end	-- bottom
	if grid[x-1] and grid[x-1][y] then val.TL = val.TL + 1; val.BL = val.BL + 2 end -- left
	if grid[x+1] and grid[x+1][y] then val.TR = val.TR + 2; val.BR = val.BR + 1 end	-- right
	if grid[x-1] and grid[x-1][y-1] and val.TL == 3 then val.TL = 4 end	-- topleft
	if grid[x+1] and grid[x+1][y-1] and val.TR == 3 then val.TR = 4 end	-- topright
	if grid[x-1] and grid[x-1][y+1] and val.BL == 3 then val.BL = 4 end	-- bottomleft
	if grid[x+1] and grid[x+1][y+1] and val.BR == 3 then val.BR = 4 end	-- bottomright
	
	-- If isolated then draw the island.
	if val.TL == 0 and val.TR == 0 and val.BL == 0 and val.BR == 0 then
		love.graphics.draw(autotileImage, chunk.island, x*size,y*size)
	
	-- Otherwise, draw the chunks
	else
		love.graphics.draw(autotileImage, chunk.TL[val.TL], x*size,y*size)
		love.graphics.draw(autotileImage, chunk.TR[val.TR], x*size+hsize,y*size)
		love.graphics.draw(autotileImage, chunk.BL[val.BL], x*size,y*size+hsize)
		love.graphics.draw(autotileImage, chunk.BR[val.BR], x*size+hsize,y*size+hsize)
	end
	
end
 
 
function love.update()

	-- If a tile is leftclicked then make it an autotile
	if love.mouse.isDown(1) then
		local x,y = math.floor(love.mouse.getX()/size), math.floor(love.mouse.getY()/size)
		if not grid[x] then grid[x] = {} end
		grid[x][y] = true
	end
	
	-- If a tile is rightclicked then erase the autotile
	if love.mouse.isDown(2) then
		local x,y = math.floor(love.mouse.getX()/size), math.floor(love.mouse.getY()/size)
		if grid[x] then grid[x][y] = nil end
	end
	
end

 function love.draw()
 
	-- Draw the autotiles
	local endx = math.ceil(love.graphics.getWidth() /size)
	for x = 0, math.ceil(love.graphics.getWidth() /size) do
		for y = 0, math.ceil(love.graphics.getHeight() /size) do
			if grid[x] and grid[x][y] then
				drawAutotile(x,y)
			else
				love.graphics.draw(floorImage, x*size, y*size)
			end
		end
	end
    
    --Draw the cursor
    local mx, my = love.mouse.getPosition()
    love.graphics.setColor(0,0,0,255)
    love.graphics.rectangle("line", mx+1 - mx % size, my+1 - my % size, size, size)
    love.graphics.setColor(255,255,255,255)
    love.graphics.rectangle("line", mx - mx % size, my - my % size, size, size)
	
	-- Instructions
	love.graphics.setColor(0,0,0,100)
	love.graphics.rectangle('fill',0,0,350,20)
	love.graphics.setColor(255,255,255,255)
	love.graphics.print("Left click to place tiles. Right click to delete them",5,5)

 end
