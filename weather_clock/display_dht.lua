-- **********************************************************************
-- Lua-Modul: display_dht.lua
-- ==========================
--      Uwe Berger; 2016
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
    disp:firstPage()
	repeat
		disp:setFont(u8g.font_6x10)
		disp:drawStr(0, 12, "intern (Temp./Humid.)")
		disp:setFont(u8g.font_10x20)
		disp:drawStr(72-string.len(d.dht.temp_str)*10, 35, d.dht.temp_str)
		disp:drawStr(80, 35, string.char(0xB0).."C")
		disp:drawStr(72-string.len(d.dht.hum_str)*10, 55, d.dht.hum_str)
		disp:drawStr(80, 55, "%")
	until disp:nextPage() == false
end

return M
