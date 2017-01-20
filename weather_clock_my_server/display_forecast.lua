-- **********************************************************************
-- Lua-Modul: display_forecast.lua
-- ===============================
--         Uwe Berger; 2017
--
-- Interface:
-- ----------
--     display()
-- ...entspr. Parameter siehe weiteren Quelltext...
--
--
-- ---------
-- Have fun!
--
-- **********************************************************************

local M = {}

-- **********************************************************************
function M.display(d)
    if d.fc_count > 0 then
		-- Bilddaten laden
        if file.open(""..d.fc[d.fc_idx].v[5]..".mono", "r") == nil then
        	file.open("na.mono", "r")
        end
        local xbm_data = file.read()
        file.close()
        disp:firstPage()
        repeat
           disp:drawXBM(0, 0, 48, 48, xbm_data)
           disp:setFont(u8g.font_9x15)
           disp:drawStr(50, 10, ""..d.fc[d.fc_idx].v[1].."")
           disp:setFont(u8g.font_6x10)
           disp:drawStr(50, 20, ""..d.fc[d.fc_idx].v[2].."")
           disp:setFont(u8g.font_9x15)
           disp:drawStr(50, 36, ""..d.fc[d.fc_idx].v[3].."/"..d.fc[d.fc_idx].v[4]..string.char(0xB0).."C")
           disp:setFont(u8g.font_6x10)
           -- Text eventuell wortweise auf mehrere Zeilen verteilen
           local x, y= 50, 49
           for s in string.gmatch(d.fc[d.fc_idx].v[6], "%a+") do
               if (x+string.len(s)*6) > 128 then x, y= 50, y+10 end
               disp:drawStr(x, y, ""..s.."")
               x=x+(string.len(s)*6)+6
            end
            -- Tagesposition in der Vorhersage anzeigen
            local dx = 128/d.fc_count
            x, y = dx/2, 63
            for i=1, d.fc_count, 1 do
                if i == d.fc_idx then
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
			disp:setFont(u8g.font_9x15)
            disp:drawStr(0, 30, "No data (fc)!")        
        until disp:nextPage() == false
    end
end


return M
