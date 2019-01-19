
local Grid = require("Grid")
local grid = Grid:new()
local floorImage = love.graphics.newImage("Floor.png")

local image = love.graphics.newImage("Autotile.png")	-- Autotile image
local width = image:getWidth()		-- Image width
local height = image:getHeight()	-- Image height
local size = 32						-- Tile size
local hsize = math.floor(size/2)	-- Half tile size

-- Cut out the chunks. They are numbered like this:
-- 0		1	2
--			3	4
-- 5	6	9	10
-- 7	8	11	12
-- 13	14	17	18
-- 15	16	19	20

-- Cut out the chunks. They are numbered like this:
-- island	3	3
--  		3	3
-- 0	2	2	0
-- 2	4	4	2
-- 1	4	4	1
-- 0	1 	1	0


local chunk = {}

-- Island tile
chunk[0] = love.graphics.newQuad(0, 0, size, size, width, height)

-- Cross tile
chunk[1] = love.graphics.newQuad(size,0, hsize, hsize, width, height)
chunk[2] = love.graphics.newQuad(size+hsize,0, hsize, hsize, width, height)
chunk[3] = love.graphics.newQuad(size,hsize, hsize, hsize, width, height)
chunk[4] = love.graphics.newQuad(size+hsize, hsize, hsize, hsize, width, height)

-- Rest of the tiles
local x,y
for ix=0,1 do
	for iy=0,1 do
		x = size*ix
		y = size*(iy+1)
		chunk[5+ix*4+iy*8] = love.graphics.newQuad(x, y, hsize, hsize, width, height)
		chunk[6+ix*4+iy*8] = love.graphics.newQuad(x+hsize, y, hsize, hsize, width, height)
		chunk[7+ix*4+iy*8] = love.graphics.newQuad(x, y+hsize, hsize, hsize, width, height)
		chunk[8+ix*4+iy*8] = love.graphics.newQuad(x+hsize, y+hsize, hsize, hsize, width, height)
	end
end

function drawAutotile(x,y)

	-- Adjacent tile values for each quarter. Each corner is represented by 3 binary digits.
	-- 1-4 is the topleft, 8-32 is the topright, 64-256 bottomleft, 512-2048 is bottomright.
	-- The first digit represents the left tile, the second digit the right, third is the center.
	-- To understand what the center, left, and right tiles are imagine that each corner is facing 
	-- the direction that it is pointed in. There is a tile to the "left" and a tile to the "right" 
	-- which are directly adjacent to the tile that the corner belongs to. There is also a diagonal 
	-- "center" tile that the corner is directly pointing at.
	local val = 0
	
	-- Get adjacent tile value for each corner. This checks each surrounding tile and adds in the 
	-- appropriate binary digits. For example, the tile directly below the current one is "left" of
	-- the bottomleft (third) corner and to the right of the bottomright (fourth) corner. So if this
	-- tile connects to the bottom tile the value added would be 1024 + 64 = 1088
	if grid(x,y-1) then val = val + 10 end		-- top
	if grid(x,y+1) then val = val + 1088 end	-- bottom
	if grid(x-1,y) then val = val + 129 end 	-- left
	if grid(x+1,y) then val = val + 528 end		-- right
	if grid(x-1,y-1) then val = val + 4 end		-- topleft
	if grid(x+1,y-1) then val = val + 32 end	-- topright
	if grid(x-1,y+1) then val = val + 256 end	-- bottomleft
	if grid(x+1,y+1) then val = val + 2048 end	-- bottomright
	
	-- Get the quad from the adjacent tile value
	local quad = {0,0,0,0}
	local corner = val % 8
	quad[1] = (corner%4==0 and 5) or (corner%4==1 and 9) or (corner%4==2 and 13) or (corner==3 and 1) or 17
	corner = math.floor( (val % 64) / 8 )
	quad[2] = (corner%4==0 and 10) or (corner%4==1 and 18) or (corner%4==2 and 6) or (corner==3 and 2) or 14
	corner = math.floor( (val % 512) / 64 )
	quad[3] = (corner%4==0 and 15) or (corner%4==1 and 7) or (corner%4==2 and 19) or (corner==3 and 3) or 11
	corner = math.floor( (val % 4096) / 512 )
	quad[4] = (corner%4==0 and 20) or (corner%4==1 and 16) or (corner%4==2 and 12) or (corner==3 and 4) or 8
	
	-- Draw the quads
	love.graphics.drawq(image, chunk[quad[1]], x*size,y*size)
	love.graphics.drawq(image, chunk[quad[2]], x*size+hsize,y*size)
	love.graphics.drawq(image, chunk[quad[3]], x*size,y*size+hsize)
	love.graphics.drawq(image, chunk[quad[4]], x*size+hsize,y*size+hsize)
end
 
function love.update()
	if love.mouse.isDown('l') then
		grid:set(math.floor(love.mouse.getX()/size),math.floor(love.mouse.getY()/size),true)
	end
	if love.mouse.isDown('r') then
		grid:set(math.floor(love.mouse.getX()/size),math.floor(love.mouse.getY()/size),nil)
	end
end

 function love.draw()
	for x,y,v in grid:rectangle(0,0,math.ceil(love.graphics.getWidth()/size),math.ceil(love.graphics.getHeight()/size),true) do
		if v then drawAutotile(x,y)
		else love.graphics.draw(floorImage, x*size, y*size)
		end
	end
	love.graphics.setColor(0,0,0,100)
	love.graphics.rectangle('fill',0,0,350,20)
	love.graphics.setColor(255,255,255,255)
	love.graphics.print("Left click to place tiles. Right click to delete them",5,5)
	-- for k,v in pairs(chunk) do
		-- love.graphics.drawq(image, v, k*(size+2),0,0,2,2)
		-- love.graphics.print(tostring(k),k*(size+2),0,0,2,2)
	-- end
 end