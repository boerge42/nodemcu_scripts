-- **********************************************************
--                    weather_client.lua
--                    ==================
--                     Uwe Berger; 2016
--
-- send...: get_weather_current
--                    |
--                    v
--            (weather_server.tcl)
--                    |
--                    v	
-- receive: get_weather_current|03.06.2016, 22:14:20|20.2|58.9|1012.1|1
--                                |                    |    |      |  |
-- Timestamp ---------------------|                    |    |      |  |
--     ...-Temperatur ---------------------------------|    |      |  |
--         ...-Luftfeuchtigkeit ----------------------------|      |  |
--             ...-Luftdruck --------------------------------------|  |
--                 ...-Luftdrucktendenz ------------------------------|
--
--
-- ---------
-- Have fun!
--
-- **********************************************************

weather_svr_ip   = "10.1.1.82"
weather_svr_port = 12342


-- **********************************************************************
function init_i2c_display()
    i2c.setup(0, 4, 3, i2c.SLOW)
    disp = u8g.ssd1306_128x64_i2c(0x3c)
end

-- **********************************************************************
function split_str(inputstr, sep)
	if sep == nil then sep = "%s" end
	local t={} ; i=1
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		t[i] = str
		i = i + 1
	end
	return t
end

-- **********************************************************************
function display_oled(s)
	local v = split_str(s, "|")
    disp:firstPage()
	repeat
		if v[1] == "get_weather_current" then
			-- Groesse 9x15
			disp:setFont(u8g.font_9x15)
			disp:drawStr(72-string.len(v[3])*9, 15,  ""..v[3])		
			disp:drawStr(80, 15, "°C")
			disp:drawStr(72-string.len(v[4])*9, 30, ""..v[4])
			disp:drawStr(80, 30, "%")
			disp:drawStr(72-string.len(v[5])*9, 45, ""..v[5])
			disp:drawStr(80, 45, "hPa")
			-- Groesse 9x15
			disp:setFont(u8g.font_9x15_75r)
			if (tonumber(v[6]) == 1) then
				-- steigender Luftdruck
				disp:drawStr(111, 45, "2")
			else
				-- sinkender Luftdruck
				disp:drawStr(111, 45, "<")
			end
			-- Groesse 6x10
			disp:setFont(u8g.font_6x10)
			disp:drawStr(128/2 - ((string.len(v[2])-1)*6)/2, 63, ""..v[2])
		elseif v[1] == "get_weather_forecast" then
			print("get_weather_forecast")
		else
			print("unbekannt...")
		end
	until disp:nextPage() == false
end

-- **********************************************************************
function request_weather_svr ()
	local conn=net.createConnection(net.TCP, 0)
	conn:on("receive", function(conn, c)
							print("\nreceive..."..c.."")
							display_oled(c)
							conn:close()
							conn=nil
					   end)
	conn:on("connection", function()
							conn:send("get_weather_current\n")
						  end)
	conn:connect(weather_svr_port, weather_svr_ip)
end

-- **********************************************************************
-- **********************************************************************
-- **********************************************************************
init_i2c_display()

request_weather_svr()

-- Daten holen...(alle 60s)
tmr.alarm(1, 60000, 1, function() request_weather_svr() end)
