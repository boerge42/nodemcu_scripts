-- **********************************************************************
-- Lua-Modul: display_clock.lua
-- ============================
--       Uwe Berger; 2017
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
M.display_name = "display_clock"

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
	local sun = "sun: n/a"
	-- UTC
	local utc = rtctime.get()
    local tm  = rtctime.epoch2cal(utc)
    -- Sommerzeit?
    if d.dst == true and is_summertime(tm) then
    	utc = utc + 3600
    end
    -- Zeitzone noch einrechnen
    tm = rtctime.epoch2cal(utc + d.tz_offset * 3600)
	-- Ausgabestrings generieren
	local date = string.format("%04d/%02d/%02d", tm["year"], tm["mon"], tm["day"])
	local time = string.format("%02d:%02d:%02d", tm["hour"], tm["min"], tm["sec"])
	if d.forecast.sunrise ~= nil then
		sun = string.format("sun: %s - %s", d.forecast.sunrise, d.forecast.sunset)
	end
	-- ...und ausgeben
	disp:firstPage()
	repeat
		disp:setFont(u8g.font_10x20)
		disp:drawStr(64-string.len(date)*10/2, 20, date)
		disp:drawStr(64-string.len(time)*10/2, 40, time)
		disp:setFont(u8g.font_6x10)
		disp:drawStr(64-string.len(sun)*6/2, 60, sun)
	until disp:nextPage() == false
end


return M
