-- **********************************************************************
-- Lua-Modul: display_current.lua
-- ==============================
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
    if d.con.code ~= nil then
		-- Bilddaten laden
        if file.open(""..d.con.code..".mono", "r") == nil then
        	file.open("na.mono", "r")
        end
        local xbm_data = file.read()
        file.close()
        disp:firstPage()
        repeat
           disp:drawXBM(0, 0, 48, 48, xbm_data)
           disp:setFont(u8g.font_6x10)
           disp:drawStr(50, 10, "current:")
		   disp:setFont(u8g.font_10x20)
           disp:drawStr(70, 32, ""..d.con.temp..string.char(0xB0).."C")
           disp:setFont(u8g.font_6x10)
           -- Text eventuell wortweise auf mehrere Zeilen verteilen
           local x, y= 50, 49
           for s in string.gmatch(d.con.text, "%a+") do
               if (x+string.len(s)*6) > 128 then x, y= 50, y+10 end
               disp:drawStr(x, y, ""..s.."")
               x=x+(string.len(s)*6)+6
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
