-- **********************************************************************
-- Lua-Modul: display_forecast.lua
-- ===============================
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
M.display_name = "display_forecast"

-- **********************************************************************
function M.display_destroy(timer)
	tmr.unregister(timer)
	package.loaded.display_forecast = nil
end

-- **********************************************************************
function M.display_refresh_init(timer)
end

-- **********************************************************************
function M.display(d)
	local s = ""
	if d.forecast.fc ~= nil then
	    if file.open("mono_48x48/"..string.format("%02d", d.forecast.fc[d.forecast_idx].code)..".mono", "r") == nil then
        	file.open("mono_48x48/na.mono", "r")
        end
        local xbm_data = file.read()
        file.close()
        
        disp:firstPage()
        repeat
        	disp:drawXBM(0, 0, 48, 48, xbm_data)
           	disp:setFont(u8g.font_9x15)
           	disp:drawStr(50, 10, d.forecast.fc[d.forecast_idx].day)
           	disp:setFont(u8g.font_6x10)
           	disp:drawStr(50, 20, d.forecast.fc[d.forecast_idx].date)
           	disp:setFont(u8g.font_9x15)
           	disp:drawStr(50, 36, ""..d.forecast.fc[d.forecast_idx].temp_low.."/"..d.forecast.fc[d.forecast_idx].temp_high..string.char(0xB0).."C")
           	disp:setFont(u8g.font_6x10)
           	-- Text eventuell wortweise auf mehrere Zeilen verteilen
           	local x, y= 50, 49
           	for s in string.gmatch(d.forecast.fc[d.forecast_idx].text, "%a+") do
           	    if (x+string.len(s)*6) > 128 then x, y= 50, y+10 end
           	    disp:drawStr(x, y, ""..s.."")
           	    x=x+(string.len(s)*6)+6
           	end        	
        	-- Tagesposition in der Vorhersage anzeigen
            	local dx = 128/#d.forecast.fc
            x, y = dx/2, 63
            for i=1, #d.forecast.fc, 1 do
                if i == d.forecast_idx then
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
			s = "forecast..."
			disp:drawStr(64-string.len(s)*10/2, 25, s)
		until disp:nextPage() == false
	end
end


return M
