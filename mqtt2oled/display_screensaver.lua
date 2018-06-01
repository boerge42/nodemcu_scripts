-- **********************************************************************
-- Lua-Modul: display_screensaver.lua
-- ==================================
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
M.display_name = "display_screensaver"

-- **********************************************************************
function M.display_destroy(timer)
	tmr.unregister(timer)
	package.loaded.display_screensaver = nil
end

-- **********************************************************************
function M.display_refresh_init(timer)
end


-- **********************************************************************
function M.display(d)
		disp:firstPage()
		repeat
		-- nichts...
		until disp:nextPage() == false
end


return M
