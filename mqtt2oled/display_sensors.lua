-- **********************************************************************
-- Lua-Modul: display_sensors.lua
-- ==============================
--         Uwe Berger; 2017
--
-- Interface:
-- ----------
--     display_name
--     display()
--     display_destroy()
--     display_refresh_init()
-- ...entspr. Parameter siehe weiteren Quelltext...
--
--
-- ---------
-- Have fun!
--
-- **********************************************************************

local M = {}

local display_cycle = nil
M.display_name = "display_sensors"

-- **********************************************************************
function M.display_destroy(timer)
	tmr.unregister(timer)
	package.loaded.display_sensors = nil
end

-- **********************************************************************
function M.display_refresh_init(timer)
end

-- **********************************************************************
function M.display(d)
	-- sind ueberhaupt Daten zum anzeigen da?
	if (d.nodes ~= nil) and (#d.nodes > 0) and (d.sensors[d.nodes[d.sensors_idx]]["heap"] ~= nil) then
		disp:firstPage()
		repeat
			disp:setFont(u8g.font_6x10)
			-- eventuell Alias ausgeben
			if d.nodenames[d.nodes[d.sensors_idx]]~= nil then
				disp:drawStr(0, 7, d.nodenames[d.nodes[d.sensors_idx]])
			else
				disp:drawStr(0, 7, d.nodes[d.sensors_idx])		
			end
			-- disp:drawStr(110, 7, d.sensors[d.nodes[d.sensors_idx]]["status"])
			if d.sensor_status[d.nodes[d.sensors_idx]] ~= nil then
				disp:drawStr(110, 7, d.sensor_status[d.nodes[d.sensors_idx]])
			end
			disp:drawStr(0, 17, d.sensors[d.nodes[d.sensors_idx]]["readable_ts"])
			disp:setFont(u8g.font_9x15)
			disp:drawStr(35, 38, d.sensors[d.nodes[d.sensors_idx]]["temperature"]..string.char(0xB0).."C")
			disp:drawStr(35, 53, d.sensors[d.nodes[d.sensors_idx]]["humidity"].."%")
       	 	-- Position anzeigen
       	 	local dx = 128/#d.nodes
       		x, y = dx/2, 63
			for i=1, #d.nodes, 1 do
				if i == d.sensors_idx then
					disp:drawHLine(x-2, y, 5)
				else 
					disp:drawHLine(x, y, 1)
				end
				x=x+dx
			end
		until disp:nextPage() == false
	else
		disp:firstPage()
		repeat
			disp:setFont(u8g.font_10x20)
			s = "sensors..."
			disp:drawStr(64-string.len(s)*10/2, 25, s)
		until disp:nextPage() == false	
	end
end


return M
