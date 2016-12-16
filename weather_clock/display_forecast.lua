-- **********************************************************************
-- Lua-Modul: display_forecast.lua
-- ===============================
--         Uwe Berger; 2016
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
    if #d.fc.f > 0 then
		-- Bilddaten laden
        if file.open(""..d.fc.f[d.fc.idx].code..".mono", "r") == nil then
        	file.open("na.mono", "r")
        end
        local xbm_data = file.read()
        file.close()
        disp:firstPage()
        repeat
           disp:drawXBM(0, 0, 48, 48, xbm_data)
           disp:setFont(u8g.font_9x15)
           disp:drawStr(50, 10, ""..d.fc.f[d.fc.idx].day.."")
           disp:setFont(u8g.font_6x10)
           disp:drawStr(50, 20, ""..d.fc.f[d.fc.idx].date.."")
           disp:setFont(u8g.font_9x15)
           disp:drawStr(50, 36, ""..f2c(d.fc.f[d.fc.idx].low).."/"..f2c(d.fc.f[d.fc.idx].high)..string.char(0xB0).."C")
           disp:setFont(u8g.font_6x10)
           -- Text eventuell wortweise auf mehrere Zeilen verteilen
           local x, y= 50, 49
           for s in string.gmatch(d.fc.f[d.fc.idx].text, "%a+") do
               if (x+string.len(s)*6) > 128 then x, y= 50, y+10 end
               disp:drawStr(x, y, ""..s.."")
               x=x+(string.len(s)*6)+6
            end
            -- Tagesposition in der Vorhersage anzeigen
            local dx = 128/#d.fc.f
            x, y = dx/2, 63
            for i=1, #d.fc.f, 1 do
                if i == d.fc.idx then
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
            disp:drawStr(10, 30, "No data!")        
        until disp:nextPage() == false
    end
end


return M
