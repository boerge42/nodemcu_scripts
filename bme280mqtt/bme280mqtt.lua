-- *********************************************************************
--
--                     bme280mqtt.lua
--                    ================
--                    Uwe Berger; 2017
--
--
-- * alle Stunde RTC via NTP synchronisieren
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
--      *** sensors/<wifi.sta.gethostname()>/pressure_rel
--      *** sensors/<wifi.sta.gethostname()>/drew_point
--      *** sensors/<wifi.sta.gethostname()>/heap
--      *** sensors/<wifi.sta.gethostname()>/readable_timestamp
--      *** sensors/<wifi.sta.gethostname()>/lua_list
--      *** sensors/<wifi.sta.gethostname()>/json
--   ** saemtliche MQTT-Telegramme werden mit gesetztem Retain-Flag 
--      an den Broker gesendet
-- * mqtt_cmd: siehe mqtt_cmd.lua
-- * Variablen node_alias/altitude aus Datein nodealias/altitude 
--   ermitteln
--
-- ---------
-- Have fun!
--
-- *********************************************************************

mc=require "mqtt_cmd"

altitude = 39 -- altitude of the measurement place

sda, scl = 3, 4

ntp_server = "de.pool.ntp.org"
ntp_refresh = 3600000      -- ms -> 1h

mqtt_broker = "10.1.1.82"
client_name = wifi.sta.gethostname()
mqtt_topic = "sensors/"..client_name.."/"
node_type = "bme280"

node_alias=""

mqtt_interval = 300000     -- ms -> 5min 



-- **********************************************************************
-- dofile mit vorheriger Existenzpruefung
function my_dofile(name)
	if file.exists(name) then
		dofile(name)
	end
end

-- **********************************************************************
-- Sommerzeit?
-- Quelle: https://github.com/maciejmiklas/NodeMCUUtils/blob/master/dateformatEurope.lua
-- ts --> UTC-Zeit (...aus rtctime.get())
function is_summertime(ts)
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

-- *********************************************************************
-- UNIX-Sekunde in lokale Zeit umrechnen und in "lesbaren" String 
-- umwandeln
function get_readable_local_datetime(tz_offset, dst)
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
-- momentane UNIX-Sekunde von einem NTP-Server holen und RTC setzen
function read_ntp()
	net.dns.resolve(ntp_server, 
					function(sk, ip)
						if (ip == nil) then 
							print("DNS failed!") 
							-- nach 5 Sekunden naechster Versuch...
							tmr.alarm(1, 5000, 1, function() read_ntp() end)
						else
        					sntp.sync(ip,
            							function(sec,usec,server)
                							print('sync', sec, usec, server)
                							rtctime.set(sec, usec)
											-- in einer Stunde wieder synchronisieren
											tmr.alarm(1, ntp_refresh, 1, function() read_ntp() end)
            							end,
            							function()
											print('NTP sync failed!')
											-- nach 5 Sekunden neachster Versuch
											tmr.alarm(1, 5000, 1, function() read_ntp() end)
            							end)
        				end
    				end) 
end

-- *********************************************************************
function read_bme280()
	local t, p, h, qnh = bme280.read(altitude)
	local d = bme280.dewpoint(h, t)
	t   = (t/100)   .."."..((t%100)/10)
	p   = (p/1000)  .."."..((p%1000)/100)
	h   = (h/1000)  .."."..((h%1000)/100)
	qnh = (qnh/1000).."."..((qnh%1000)/100)
	d   = (d/100)   .."."..((d%100)/10)
	return t, p, h, qnh, d
end

-- **********************************************************************
-- Messwerte via MQTT publizieren
function publish_values(t, p, h, qnh, d)
	m:publish(mqtt_topic.."heap", node.heap(), 0, 1)
	m:publish(mqtt_topic.."status", "on", 0, 1)
	m:publish(mqtt_topic.."node_alias", node_alias, 0, 1)
	m:publish(mqtt_topic.."node_type", node_type, 0, 1)
	m:publish(mqtt_topic.."temperature", t, 0, 1)
	m:publish(mqtt_topic.."humidity", h, 0, 1)
	m:publish(mqtt_topic.."pressure_rel", qnh, 0, 1)
	m:publish(mqtt_topic.."drew_point", d, 0, 1)
	m:publish(mqtt_topic.."unixtime", rtctime.get(), 0, 1)
	m:publish(mqtt_topic.."readable_timestamp", get_readable_local_datetime(1, true), 0, 1)
	-- Lua-Liste
	local l="{"
	l=l.."heap=\""..node.heap()
	l=l.."\",temperature=\""..t
	l=l.."\",humidity=\""..h
	l=l.."\",pressure_rel=\""..qnh
	l=l.."\",drew_point=\""..d
	l=l.."\",unixtime=\""..rtctime.get()
	l=l.."\",node_name=\""..client_name
	l=l.."\",node_alias=\""..node_alias
	l=l.."\",node_type=\""..node_type
	l=l.."\",readable_ts=\""..get_readable_local_datetime(1, true)
	l=l.."\"}"
	m:publish(mqtt_topic.."lua_list", l, 0, 1)
	-- JSON
	l="{"
	l=l.."\"heap\":\""..node.heap()
	l=l.."\",\"temperature\":\""..t
	l=l.."\",\"humidity\":\""..h
	l=l.."\",\"pressure_rel\":\""..qnh
	l=l.."\",\"drew_point\":\""..d
	l=l.."\",\"unixtime\":\""..rtctime.get()
	l=l.."\",\"node_name\":\""..client_name
	l=l.."\",\"node_alias\":\""..node_alias
	l=l.."\",\"node_type\":\""..node_type
	l=l.."\",\"readable_ts\":\""..get_readable_local_datetime(1, true)
	l=l.."\"}"
	m:publish(mqtt_topic.."json", l, 0, 1)
end

-- **********************************************************************
-- wenn Problem mit MQTT-Broker, dann nach 10s Verbindungsaufbau erneut versuchen...
function mqtt_error_handle() 
	tmr.alarm(2, 10000, tmr.ALARM_SINGLE, mqtt_connect())
end

-- **********************************************************************
-- mit MQTT-Broker verbinden etc. ...
function mqtt_connect()
	-- MQTT-Testament dieses Sensors festlegen...
	m:lwt(mqtt_topic.."status", "off", 0, 1)
	-- ...wenn eine MQTT-Nachricht ueber die abonnierten Kanaele kommt
	m:on("message", function(client, topic, data) 
					-- MQTT-Kommandozeile...
					mc.mqtt_cmd_message(topic, data)
					end)
	-- mit MQTT-broker verbinden
	m:connect("10.1.1.82", 1883, 0, 0,
			-- Verbindung mit MQTT-Broker hergestellt
			function(conn) 
				print("connected!")
				-- was passiert, wenn keine Verbindung mehr zum Broker...
				m:on("offline", function() mqtt_connect() end)
				-- Sensor online melden
				m:publish(mqtt_topic.."status", "on", 0, 1)
				-- MQTT-Kommandozeile initialisieren
				mc.mqtt_cmd_setup(m, client_name, 1, 1)
				-- jede Minute Messwerte via MQTT publizieren
				tmr.alarm(3, mqtt_interval, 1, function() 
										publish_values(read_bme280())
									end) 
			end,
			-- keine Verbindung mit MQTT-Broker zustande gekommen
			function(conn, reason)
				print("MQTT-Connect failed: "..reason)
				mqtt_error_handle()
			end
	)
end


-- *********************************************************************
-- *********************************************************************
-- *********************************************************************

-- abweichende Werte einlesen
my_dofile("altitude")
my_dofile("nodealias")

-- aktuelle Zeit von einem ntp-Server holen und jede Stunde aktualisieren
read_ntp()

-- I2C und BME280 initialisieren
i2c.setup(0, sda, scl, i2c.SLOW)
bme280.setup()

-- MQTT-Client definieren
m = mqtt.Client(client_name, 120)

-- mit MQTT-Broker verbinden
mqtt_connect()

-- einmal BME280-Sensor auslesen und Werte ausgeben...
print(read_bme280())
