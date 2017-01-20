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
    if d.cu_ok == 1 then
		local t
		-- Tendenz Luftdruck
		if (tonumber(d.cu[5]) == 1) then
			-- steigender Luftdruck
			t = string.char(0xBB)
		else
			-- sinkender Luftdruck
			t = string.char(0xAB)
		end
        -- Bildschirm ausgeben
        disp:firstPage()
        repeat
			disp:setFont(u8g.font_6x10)
			disp:drawStr(0, 12, "my (temp./hum./pres.)")			
			disp:setFont(u8g.font_9x15)
			disp:drawStr(72-string.len(d.cu[2])*9, 30,  ""..d.cu[2].." "..string.char(0xB0).."C")		
			disp:drawStr(72-string.len(d.cu[3])*9, 45, ""..d.cu[3].." %")
			disp:drawStr(72-string.len(d.cu[4])*9, 60, ""..d.cu[4].." hPa "..t)
        until disp:nextPage() == false
    else    
        disp:firstPage()
        repeat
			disp:setFont(u8g.font_9x15)
            disp:drawStr(0, 30, "No data (cu)!")        
        until disp:nextPage() == false
    end
end


return M
