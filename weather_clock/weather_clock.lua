-- **********************************************************
--                    weather_clock.lua
--                   ===================
--                    Uwe Berger; 2016
--
-- * Zyklisch folgende Daten holen:
--   * NTP-Zeit
--   * Wettervorhersage von Yahoo
--   * Daten von meinem Wetterserver :-)
--   * Temperatur/Luftfeuchtigkeit von einem angeschlossenen DHT22
-- * Anzeige der Daten auf einem OLED; umschaltbar mit 2 Tastern
-- * Bereitstellung der DHT22-Werte auf TCP/IP-Port 8266
--
-- ---------
-- Have fun!
--
-- **********************************************************

-- Zeitserver
local ntp_server = "de.pool.ntp.org"

-- URL fuer Wettervorhersage von Yahoo
local woeid = 640720
local url = "http://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20%20weather.forecast%20where%20woeid%20%3D%20"..woeid.."%20and%20u%3D%20%22c%22&format=json"

-- Entprell-Pause Tasten (in ms)
local debounce_delay = 30


local counter=0

local mode=1

local data={
	dht={temp_str="XXX", hum_str="YYY", ts="42", dht_stat="9"},
	fc={f={}, idx=1},
	con={}
}

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
    net.dns.resolve(ntp_server, function(sk, ip)
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
-- DHT auslesen
local function read_dht()
    local dht_stat, dht_temp, dht_hum, dht_temp_dec, dht_hum_dec = dht.read(1)
    data.dht.temp_str=""..dht_temp.."."..(dht_temp_dec/100)..""
    data.dht.hum_str=""..dht_hum.."."..(dht_hum_dec/100)..""
    data.dht.ts = rtctime.get()
    data.dht.dht_stat=dht_stat
end


-- **********************************************************************
-- Wettervorhersage holen
local function get_weather_forecast ()
    http.get(url, nil, function(code, json_data)
        if (code < 0) then
            print("HTTP request failed")
        else
            local dd = cjson.decode(json_data)
            pcall(function() data.fc.f = dd.query.results.channel.item.forecast end)
            pcall(function() data.con  = dd.query.results.channel.item.condition end)
        end
    end)
end

-- **********************************************************************
-- alle Werte aktualisieren
local function update_values()
    counter=counter+1
    -- alle 2s
    if (counter%2)==0 then
        read_dht()
    end
    -- alle 1min
    if (counter%60)==0 then
        --collectgarbage()    
    end
    -- alle 15min
    if (counter%900)==0 then
        get_weather_forecast()
    end
    -- alle 1h
    if (counter%3600)==0 then
        read_ntp()
        --counter=0
    end
end

-- **********************************************************************
-- entsprechenden Bildschirm laden und zyklisch ausfuehren
local function switch_display(i)
	oled=nil
	collectgarbage()
	local cycle = 1000
	if mode==1 then 
		cycle=1000
		oled=require "display_clock"
	elseif mode==2 then 
		cycle=900000
		oled=require "display_forecast"
	elseif mode==3 then 
		cycle=900000
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
										if #data.fc.f > 0 then
											if (mode==2) then
												data.fc.idx=data.fc.idx+1
												if data.fc.idx > #data.fc.f then data.fc.idx=1 end
											else
												mode=2
												data.fc.idx=1
											end
											switch_display(mode)
										end
										print(node.heap())
										end)
end

-- **********************************************************************
function switch7down()
	gpio.trig(7, "none")
	tmr.alarm(0, debounce_delay, tmr.ALARM_SINGLE, function()
										gpio.trig(7, "up", switch7up)
										mode=mode+1
										if mode>4 then mode=1 end
										switch_display(mode)
										print(node.heap())
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
get_weather_forecast()
tmr.alarm(1, 1000, 1, function() update_values() end)

-- Bildschirmanzeige...
switch_display(mode)

-- Telnet-Server auf Port 8266...
local srv=net.createServer(net.TCP) 
srv:listen(8266,function(svr_conn) 
        local buf="ts="..data.dht.ts.."|stat="..data.dht.dht_stat.."|temp="..data.dht.temp_str.."|hum="..data.dht.hum_str.."|heap="..node.heap().."|count="..counter..""
        svr_conn:send(buf)
        svr_conn:close()
        buf=nil
end)
