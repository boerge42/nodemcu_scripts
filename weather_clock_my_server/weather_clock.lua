-- **********************************************************
--                    weather_clock.lua
--                   ===================
--                    Uwe Berger; 2017
--
-- * Zyklisch folgende Daten holen:
--   * NTP-Zeit
--   * Daten von meinem Wetterserver :-); momentane Werte und Vorhersage
--   * Temperatur/Luftfeuchtigkeit von einem direkt angeschlossenen DHT22
-- * Anzeige der Daten auf einem OLED; umschaltbar mit 2 Tastern
-- * Bereitstellung der DHT22-Werte auf TCP/IP-Port 8266
--
-- ---------
-- Have fun!
--
-- **********************************************************

-- Entprell-Pause Tasten (in ms)
local debounce_delay = 30

local counter=0

local mode=1

local data={
	dht={temp_str="XXX", hum_str="YYY", ts="42", dht_stat="9"},
	fc={{v={}},{v={}},{v={}},{v={}},{v={}},{v={}},{v={}},{v={}},{v={}},{v={}}},
	fc_count = 0,
	fc_count_max = 10,
	fc_idx = 1,
	cu={},
	cu_ok = 0;
}

-- **********************************************************************
function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- **********************************************************************
local function split_str(inputstr, sep)
	if sep == nil then sep = "%s" end
	local t={} ; i=1
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		t[i] = str
		i = i + 1
	end
	return t
end

-- **********************************************************************
-- momentane UNIX-Sekunde von einem NTP-Server holen und internen 
-- Zeitzaehler mit Ergebnis abgleichen
local function read_ntp()
    net.dns.resolve("de.pool.ntp.org", function(sk, ip)
    if (ip == nil) then print("DNS failed!") else
        sntp.sync(ip,
            function(sec,usec,server)
                --print('sync', sec, usec, server)
                rtctime.set(sec, usec)
            end,
            function()
                print('NTP sync failed!')
            end)
        end
    end) 
end

-- **********************************************************************
-- meinen Wetterserver auslesen
local function request_weather_svr ()
	
    local conn=net.createConnection(net.TCP, 0)
    conn:on("receive", function(conn, c)
					    	local reslist
							local res 
    						res=trim(c)
                            --print("\nreceive..."..res.."")
                            reslist = split_str(res, "@")
                            -- reslist[2] sind momentane Werte
                            data.cu_ok = 1
                 			data.cu = split_str(reslist[2], "|")
                 			-- ab reslist[3] stehen die forecast-Werte
                 			local idx = 3
                 			data.fc_count = 0
                 			while ((reslist[idx]~=nil) and (data.fc_count < data.fc_count_max)) do
                 				data.fc[idx-2].v=split_str(reslist[idx], "|")
                 				idx=idx+1
                 				data.fc_count=data.fc_count+1
                 			end
                            conn:close()
                            conn=nil
                       end)
    conn:on("connection", function()
    						data.fc_count = 0
    						data.cu_ok = 0
                            conn:send("get_weather_all\n")
                          end)
    conn:connect(12342, "10.1.1.82")

end

-- **********************************************************************
-- DHT auslesen
local function read_dht()
    local dht_stat, dht_temp, dht_hum, dht_temp_dec, dht_hum_dec = dht.read(1)
    if dht_stat == dht.OK then
    	data.dht.temp_str=""..dht_temp.."."..(dht_temp_dec/100)..""
    	data.dht.hum_str=""..dht_hum.."."..(dht_hum_dec/100)..""
    	data.dht.ts = rtctime.get()
    	data.dht.dht_stat=dht_stat
    end
end


-- **********************************************************************
-- alle Werte aktualisieren
local function update_values()
    counter=counter+1
    -- alle 2s
    if (counter%2)==0 then
        read_dht()
        if ((data.fc_count == 0) or (data.co_ok == 0)) then
        	request_weather_svr()
        end
    end
    -- alle 5min - 1s
    if (counter%299)==0 then
    	request_weather_svr()
    end
    -- alle 1h + 3s
    if (counter%3603)==0 then
        read_ntp()
    end
end

-- **********************************************************************
-- entsprechenden Bildschirm laden und zyklisch ausfuehren
local function switch_display(i)
	oled=nil
	package.loaded.display_clock = nil
	package.loaded.display_forecast = nil
	package.loaded.display_current = nil
	package.loaded.display_dht = nil
	collectgarbage()
	local cycle = 1000
	if mode==1 then 
		cycle=1000
		oled=require "display_clock"
	elseif mode==2 then 
		cycle=60000
		oled=require "display_forecast"
	elseif mode==3 then 
		cycle=60000
		oled=require "display_current"
	elseif mode==4 then 
		cycle=2000
		oled=require "display_dht"
	else                
		cycle=1000
		oled=require "display_clock"
	end
	oled.display(data)
	tmr.unregister(2)
	tmr.alarm(2, cycle, 1, function() oled.display(data) end)
end

-- **********************************************************************
function switch6up()
	gpio.trig(6, "none")
	tmr.alarm(0, debounce_delay, tmr.ALARM_SINGLE, function()
										gpio.trig(6, "down", switch6down)
										end)
end

-- **********************************************************************
function switch7up()
	gpio.trig(7, "none")
	tmr.alarm(0, debounce_delay, tmr.ALARM_SINGLE, function()
										gpio.trig(7, "down", switch7down)
										end)
end

-- **********************************************************************
function switch6down()
	gpio.trig(6, "none")
	tmr.alarm(0, debounce_delay, tmr.ALARM_SINGLE, function()
										gpio.trig(6, "up", switch6up)
										if (mode==2) then
											data.fc_idx=data.fc_idx+1
											if data.fc_idx > data.fc_count then data.fc_idx=1 end
										else
											mode = 2
											data.fc_idx=1
										end
										switch_display(mode)
										--print(node.heap())
										end)
end

-- **********************************************************************
function switch7down()
	gpio.trig(7, "none")
	tmr.alarm(0, debounce_delay, tmr.ALARM_SINGLE, function()
										gpio.trig(7, "up", switch7up)
										mode=mode+1
										data.fc_idx=1
										if mode>4 then mode=1 end
										switch_display(mode)
										--print(node.heap())
										end)
end


-- **********************************************************************
-- **********************************************************************
-- **********************************************************************

-- Taster konfigurieren
gpio.mode(6, gpio.INT, gpio.PULLUP)
gpio.trig(6, "down", switch6down)
gpio.mode(7, gpio.INT, gpio.PULLUP)
gpio.trig(7, "down", switch7down)

-- I2C und OLED initialisieren
i2c.setup(0, 2, 3, i2c.SLOW)
disp = u8g.ssd1306_128x64_i2c(0x3c)

-- alle Werte einmal holen und Update-Timer starten
read_dht()
read_ntp()
--request_weather_svr()
tmr.alarm(1, 1000, 1, function() update_values() end)

-- Bildschirmanzeige...
switch_display(mode)

-- Telnet-Server auf Port 8266...
local srv=net.createServer(net.TCP) 
srv:listen(8266,function(svr_conn) 
        svr_conn:send("ts="..data.dht.ts.."|stat="..data.dht.dht_stat.."|temp="..data.dht.temp_str.."|hum="..data.dht.hum_str.."|heap="..node.heap().."|count="..counter.."")
        svr_conn:close()
        --print("--> send\n")
        buf=nil
end)
