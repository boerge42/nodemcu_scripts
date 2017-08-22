-- **********************************************************
--                      mqttoled.lua
--                    ================
--                    Uwe Berger; 2017
--
-- * alle Stunde RTC via NTP synchronisieren
-- * Telnet-Server an Port 8266 bereitstellen, welcher
--   "ts=UNIX-Zeit|stat=Status|temp=Temperatur|Hum=Luftfeuchtigkeit|
--   heap=freier dyn. Speicher"
--   sendet und dann die Verbindung beendet
-- * Nachrichten an einen MQTT-Broker senden:
--   ** ohne Anmeldung und unverschluesselt 
--   ** Sensorstatus via Topic sensors/<wifi.sta.gethostname()>/status
--      *** on  --> Sensor ist aktiv
--      *** off --> Sensor ist nicht aktiv --> wird als MQTT-Testament 
--                  bei Start des Sensors gesetzt
--   ** zyklisch jede Minute an einen MQTT-Broker folgendes publizieren:
--      *** sensors/<wifi.sta.gethostname()>/unixtime
--      *** sensors/<wifi.sta.gethostname()>/temperature
--      *** sensors/<wifi.sta.gethostname()>/humidity
--      *** sensors/<wifi.sta.gethostname()>/heap
--      *** sensors/<wifi.sta.gethostname()>/readable_timestamp
--      *** sensors/<wifi.sta.gethostname()>/lua_list
--   ** saemtliche MQTT-Telegramme werden mit gesetztem Retain-Flag 
--      an den Broker gesendet
-- * ...und das Wichtigste :-): 
--          ==============
--   ** Empfang folgender MQTT-Topics
--      *** sensors/+/lua_list
--      *** myweather/lua_list
--      *** weatherforecast/lua_list
--   ** Ausgabe von:
--      *** Datum/Uhrzeit
--      *** Messwerte Sensoren
--      *** aktuelle Messerte meiner Wetterstation
--      *** Wettervorhersage
--      *** Systeminformationen
--      auf einem OLED, umschaltbar ueber zwei Taster
--
-- ---------
-- Have fun!
--
-- **********************************************************

-- MQTT-Zeugs
local mqtt_broker = "10.1.1.82"
local mqtt_port = 1883

local client_name = wifi.sta.gethostname()
local mqtt_topic = "sensors/"..client_name.."/"

-- I2C fuer OLED
local pin_sda = 2
local pin_scl = 3

local dht_pin = 1

local ts, stat, temp, hum = 0, -1, "xx", "xx"
local old_temp, old_hum = 0, 0

local mode = 1

-- MQTT-Daten plus ein paar Steuervariable...
values={
	nodes    = {},
	sensors  = {},
	nodenames = {},
	weather  = {},
	forecast = {},
	sensors_idx = 1,
	forecast_idx = 1,
	tz_offset = 2
}



-- **********************************************************************
-- entsprechenden Bildschirm laden und zyklisch ausfuehren
local function switch_display()
	-- altes Display entladen und Speicher freigeben
	if oled ~= nil then oled.display_destroy(2) end
	oled = nil
	collectgarbage()
	-- neues Display laden
	if mode==1 then 
		oled=require "display_clock"
	elseif mode==2 then 
		oled=require "display_sensors"
	elseif mode==3 then 
		oled=require "display_myweather"
	elseif mode==4 then 
		oled=require "display_forecast"
	elseif mode==5 then 
		oled=require "display_sysinfo"
	else                
		oled=require "display_clock"
	end
	oled.display(values)
	-- ggf. Display-Refresh-Timer starten
	oled.display_refresh_init(2)
end

-- **********************************************************************
-- Sommerzeit?
-- Quelle: 
-- https://github.com/maciejmiklas/NodeMCUUtils/blob/master/dateformatEurope.lua
-- ts --> UTC-Zeit (...aus rtctime.get())
local function is_summertime(ts)
	if ts.mon < 3 or ts.mon > 10 then 
		return false 
	end
	if ts.mon > 3 and ts.mon < 10 then 
		return true 
	end
	local prev_sunday = ts.day - ts.wday
	if ts.mon == 3 then
		if ts.day >= 25 and ts.wday == 1 and ts.hour == 0 then 
			return false 
		end
		return prev_sunday > 23
	end
	if ts.mon == 10 then
		if ts.day >= 25 and ts.wday == 1 and ts.hour == 0 then 
			return true 
		end
		return prev_sunday < 24
	end
end

-- **********************************************************************
-- UNIX-Sekunde in lokale Zeit umrechnen und in "lesbaren" String umwandeln
local function get_readable_local_datetime(tz_offset, dst)
	-- UTC
	local utc = rtctime.get()
    local tm  = rtctime.epoch2cal(utc)
    -- Sommerzeit?
    if dst == true and is_summertime(tm) then
    	utc = utc + 3600
    end
    -- Zeitzone noch einrechnen
    tm = rtctime.epoch2cal(utc + tz_offset * 3600)
    -- Ergebnis in String umwandeln
    return string.format("%04d/%02d/%02d %02d:%02d:%02d", 
                         tm["year"], tm["mon"], tm["day"], 
                         tm["hour"], tm["min"], tm["sec"])
end

-- **********************************************************************
-- DHT und RTC auslesen
function read_values()
	stat, temp, hum, temp_dec, hum_dec = dht.read(dht_pin)
	-- wenn Werte im zulaessigen Bereich liegen, dann diese uebernehmen
	-- ...ansonsten die Werte der vorherigen Messung
	if (stat == dht.OK) and 
	   (temp >= -40) and (temp <= 80) and
	   (hum >= 0) and (hum <= 100)
	then
		old_temp = temp
		old_hum = hum
		temp = temp.."."..temp_dec/100
		hum  = hum.."."..hum_dec/100
	else 
		temp = old_temp
		hum = old_hum
	end
	ts = rtctime.get()
end

-- **********************************************************************
local function fill_lists(topic, data)
	--print(topic.." --> "..data)
	if (topic ~= nil) and (data ~= nil) then
		-- topic auseinander nehmen
		local ts = {}
		for s in string.gmatch(topic, "([^/]+)") do
			table.insert(ts, s)
		end

		if ts[1] == "myweather" then
			-- meine Wetterwerte
			local f = assert(loadstring("return "..data))
			values.weather = f()
			if is_mode("display_myweather") then
				oled.display(values)
			end
			
		elseif ts[1] == "weatherforecast" then
			-- Wettervorhersage
			local f = assert(loadstring("return "..data))
			values.forecast = f()
			if is_mode("display_forecast") then
				oled.display(values)
			end
			
		else --if ts[1] == "sensors" then
			-- bleiben noch die Sensoren uebrig...
			-- ...es sollten 3 Listenelemte entstanden sein (siehe oben)
			if #ts == 3 then
				-- wenn dieses Node noch nicht bekannt, dann Listen initialisieren
				if values.sensors[ts[2]] == nil then
					--print(ts[2])
					table.insert(values.nodes, ts[2])
					values.sensors[ts[2]]={}
				end
				local f = assert(loadstring("return "..data))
				values.sensors[ts[2]] = f()
			end
			if is_mode("display_sensors") then
				oled.display(values)
			end
		end
	end
end

-- **********************************************************************
local function read_ntp()
    net.dns.resolve("de.pool.ntp.org", function(sk, ip)
    if (ip == nil) then print("DNS failed!") else
        sntp.sync(ip,
            function(sec,usec,server)
                print('sync', sec, usec, server)
                rtctime.set(sec, usec)
            end,
            function()
                print('NTP sync failed!')
            end)
        end
    end) 
end

-- **********************************************************************
-- Messwerte via MQTT publizieren
local function publish_values()
	m:publish(mqtt_topic.."heap", node.heap(), 0, 1)
	m:publish(mqtt_topic.."status", "on", 0, 1)
	m:publish(mqtt_topic.."temperature", temp, 0, 1)
	m:publish(mqtt_topic.."humidity", hum, 0, 1)
	m:publish(mqtt_topic.."unixtime", ts, 0, 1)
	m:publish(mqtt_topic.."readable_timestamp", get_readable_local_datetime(1, true), 0, 1)
	local l="{"
	l=l.."heap=\""..node.heap()
	l=l.."\",status=\"on"
	l=l.."\",temperature=\""..temp
	l=l.."\",humidity=\""..hum
	l=l.."\",unixtime=\""..ts
	l=l.."\",readable_ts=\""..get_readable_local_datetime(1, true)
	l=l.."\"}"
	m:publish(mqtt_topic.."lua_list", l, 0, 1)
end


-- **********************************************************************
function is_mode(m)
	return (oled.display_name == m)
end

-- **********************************************************************
local function switch6up()
	gpio.trig(6, "none")
	tmr.alarm(0, 30, tmr.ALARM_SINGLE, 
				function()
					gpio.trig(6, "down", switch6down)
				end)
end

-- **********************************************************************
function switch7up()
	gpio.trig(7, "none")
	tmr.alarm(0, 30, tmr.ALARM_SINGLE, 
				function()
					gpio.trig(7, "down", switch7down)
				end)
end

-- **********************************************************************
function switch6down()
	gpio.trig(6, "none")
	tmr.alarm(0, 30, tmr.ALARM_SINGLE, 
				function()
					gpio.trig(6, "up", switch6up)
					if is_mode("display_sensors") then
						values.sensors_idx = values.sensors_idx + 1
						if values.sensors_idx > #values.nodes then 
							values.sensors_idx = 1 
						end
						oled.display(values)
					elseif is_mode("display_forecast") then
						values.forecast_idx = values.forecast_idx + 1
						if values.forecast_idx > #values.forecast.fc then 
							values.forecast_idx = 1 
						end
						oled.display(values)
					end
				end)
end

-- **********************************************************************
function switch7down()
	gpio.trig(7, "none")
	tmr.alarm(0, 30, tmr.ALARM_SINGLE, 
				function()
					gpio.trig(7, "up", switch7up)
					mode=mode+1
					if mode>5 then mode=1 end
					switch_display()
				end)
end


-- **********************************************************************
-- **********************************************************************
-- **********************************************************************

node.setcpufreq(node.CPU160MHZ)

-- aktuelle Zeit von einem ntp-Server holen und jede Stunde aktualisieren
read_ntp()
tmr.alarm(2, 3600000, 1, function() read_ntp() end)


-- Taster konfigurieren
gpio.mode(6, gpio.INT, gpio.PULLUP)
gpio.trig(6, "down", switch6down)
gpio.mode(7, gpio.INT, gpio.PULLUP)
gpio.trig(7, "down", switch7down)

-- OLED initialisieren
i2c.setup(0, pin_sda, pin_scl, i2c.SLOW)
disp = u8g.ssd1306_128x64_i2c(0x3c)
	
-- ggf. Datei nodenames mit Alias-Name einlesen
function namealias(name, alias)	values.nodenames[name] = alias end
if file.exists("nodenames") then
	dofile("nodenames")
end

-- initialer Screen
switch_display()

-- mit MQTT-Client definieren
m = mqtt.Client(client_name, 120)

-- MQTT-Testament dieses Sensors festlegen...
m:lwt(mqtt_topic.."status", "off", 0, 1)

-- ...wenn eine MQTT-Nachricht ueber den abonnierten kommt
m:on("message", function(client, topic, data) 
					-- Datenstrukturen mit MQTT-Werten befuellen
					fill_lists(topic, data)
				end)

-- mit MQTT-broker verbinden
m:connect(mqtt_broker, mqtt_port, 0, 0,
		-- Verbindung mit MQTT-Broker hergestellt
		function(conn) 
			print("connected!")
			-- Topics abonnieren
			m:subscribe(
						{
							["sensors/+/lua_list"]=0,
							["myweather/lua_list"]=0,
							["weatherforecast/lua_list"]=0
						})
			m:publish(mqtt_topic.."status", "on", 0, 1)
			tmr.alarm(3,60000,1, function() 
									read_values()
									publish_values()
								 end) 
		end,
		-- keine Verbindung mit MQTT-Broker zustande gekommen
		function(conn, reason)
			print("MQTT-Connect failed: "..reason)
		end
)	

-- Messwerte via Request auf Port 8266 ausliefern
srv=net.createServer(net.TCP) 
srv:listen(8266,function(conn) 
        read_values()
        local buf="ts="..ts.."|stat="..stat.."|temp="..temp.."|hum="..hum.."|heap="..node.heap()
        conn:send(buf)
        conn:close()
		end)
