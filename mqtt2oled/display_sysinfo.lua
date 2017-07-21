-- **********************************************************************
-- Lua-Modul: display_sysinfo.lua
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

local display_cycle = 1000
M.display_name = "display_sysinfo"

-- **********************************************************************
function M.display_destroy(timer)
	tmr.unregister(timer)
	package.loaded.display_clock = nil
end

-- **********************************************************************
function M.display_refresh_init(timer)
	tmr.alarm(timer, display_cycle, 1, function() M.display(values) end)
end

-- **********************************************************************
function M.display(d)
	local heap = node.heap()
	local ip   = wifi.sta.getip()
	local major, minor, dev, chipid = node.info()
	local rawcode, reason = node.bootreason()

	-- ...und ausgeben
	disp:firstPage()
	repeat
		disp:setFont(u8g.font_6x10)
		disp:drawStr(0, 7, "sysinfo:")
		disp:drawStr(0, 20, "nodemcu-ver.: "..major.."."..minor.."."..dev)
		disp:drawStr(0, 30, "chipid: "..chipid)
		disp:drawStr(0, 40, "bootreason: "..rawcode.."/"..reason)
		disp:drawStr(0, 50, "free heap: "..heap.."Byte")
		disp:drawStr(0, 60, "ip: "..ip)
	until disp:nextPage() == false
end


return M
