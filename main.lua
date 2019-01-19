local autotile = require('autotile')

local floorImage = love.graphics.newImage("Floor.png")		 -- Pure grass tile
local autotileImage = love.graphics.newImage("Autotile.png") -- Autotile image
local size = 32								-- Tile size
local tiler = autotile(autotileImage, size)


-- A 2-d grid used to represent connected tiles. Values can either contain true for
-- connected tiles or nil for unconnected tiles.
local grid = {}


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
	for x = 0, math.ceil(love.graphics.getWidth() /size) do
		for y = 0, math.ceil(love.graphics.getHeight() /size) do
			if grid[x] and grid[x][y] then
				tiler:drawAutotile(grid,x,y)
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
