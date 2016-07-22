--
--
--
my_clock = require "my_clock_functions"

p = {}

--**********************************************************
function toint(n)
    local s = tostring(n)
    local i, j = s:find('%.')
    if i then
        return tonumber(s:sub(1, i-1))
    else
        return n
    end
end

--**********************************************************
--**********************************************************
--**********************************************************

local x0 = 31
local y0 = 31

--Mittelpunkt
p[""..x0..","..y0..""] = 1

-- Ziffenblatt-Punkte erzeugen
for i=0, 59, 1 do
	local x, y = my_clock.clock_face_point(x0,y0,30,i)
	x = toint(x)
	y = toint(y)
	p[""..x..","..y..""] = 1
	if ((i % 5)==0) then
		x, y = my_clock.clock_face_point(x0,y0,28,i)
		x = toint(x)
		y = toint(y)
		p[""..x..","..y..""] = 1
	end
end

-- Ziffernball ausgeben (in "ASCII-Art"...)
for y=0, 63, 1 do
	line = "   "
	for x=0, 63, 1 do
		if p[""..x..","..y..""] then
			line = line.."0"
		else
			line = line.." "
		end
	end
	print(line)
end







