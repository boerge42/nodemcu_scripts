-- **********************************************************************
-- Lua-Modul: display_weather.lua
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
M.display_name = "display_myweather"

-- **********************************************************************
function M.display_destroy(timer)
	tmr.unregister(timer)
	package.loaded.display_myweather = nil
end

-- **********************************************************************
function M.display_refresh_init(timer)
end


-- **********************************************************************
function M.display(d)
	local s = ""
	local r = ""
	if d.weather.temperature_in ~= nil then
		disp:firstPage()
		repeat
			disp:setFont(u8g.font_6x10)
			disp:drawStr(0, 7, "current (out):")	
			disp:setFont(u8g.font_9x15)
			
			s = d.weather.temperature_out..string.char(0xB0).."C"
			disp:drawStr(64-string.len(s)*9/2, 25, s)
			
			s = d.weather.humidity_out.."%"
			disp:drawStr(64-string.len(s)*9/2, 40, s)
			
			s= d.weather.pressure_rel.."hPa"
			if (tonumber(d.weather.ressure_rising) == 1) then t = "2" else t = "<" end
			disp:drawStr(64-string.len(s)*9/2, 55, s)
			disp:setFont(u8g.font_9x15_75r)
			disp:drawStr(68 + string.len(s)*9/2, 55, t)
			
		until disp:nextPage() == false
	else 
		disp:firstPage()
		repeat
			disp:setFont(u8g.font_10x20)
			s = "weather..."
			disp:drawStr(64-string.len(s)*10/2, 25, s)
		until disp:nextPage() == false
	end
end


return M
