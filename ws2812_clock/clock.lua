-- *********************************************************************
--
--                      ws2812-Clock
--                    =================
--                    Uwe Berger; 2018
--
-- Darstellung einer Uhr auf einem Ring mit 60 WS2812-LEDs. Die anzuzei-
-- gende Uhrzeit wird von einem NTP-Server im Netz ermittelt.
--
-- Weiterin meldet sich die Uhr bei einem MQTT-Broker (Konfiguration: 
-- siehe mqtt_config.lua) an es wird eine einfache Kommando-Shell 
-- (siehe mqtt_cmd.lua) zur Verfuegung gestellt.
--
-- ---------
-- Have fun!
--
-- *********************************************************************

mc=require "mqtt_cmd"

dofile("mqtt_config.lua")

ntp_server      = "de.pool.ntp.org"		-- NTP-Server
tz_offset       = 1                     -- Stundenoffset der Zeitzone
with_summertime = true                  -- Sommerzeit beachten?

client_name = wifi.sta.gethostname()
mqtt_topic = client_name.."/"


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
-- UNIX-Sekunde in lokale Zeit umrechnen 
function get_local_time(tz_offset, dst)
	-- UTC
	local utc = rtctime.get()
    local tm  = rtctime.epoch2cal(utc)
    -- Sommerzeit?
    if dst == true and is_summertime(tm) then
    	utc = utc + 3600
    end
    -- Zeitzone noch einrechnen
    tm = rtctime.epoch2cal(utc + tz_offset * 3600)
	return tm.sec, tm.min, tm.hour, tm.day, tm.mon, tm.year
end

-- **********************************************************************
-- momentane UNIX-Sekunde von einem NTP-Server holen und RTC setzen
function read_ntp()
    net.dns.resolve(ntp_server, function(sk, ip)
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
-- wenn Problem mit MQTT-Broker, dann nach 10s Verbindungsaufbau erneut versuchen...
function mqtt_error_handle() 
	tmr.alarm(2, 10000, tmr.ALARM_SINGLE, mqtt_connect())
end

-- **********************************************************************
-- mit MQTT-Broker verbinden etc. ...
function mqtt_connect()
	-- MQTT-Testament festlegen...
	m:lwt(mqtt_topic.."status", "off", 0, 1)
	-- ...wenn eine MQTT-Nachricht ueber die abonnierten Kanaele kommt
	m:on("message", function(client, topic, data) 
					-- MQTT-Kommandozeile...
					mc.mqtt_cmd_message(topic, data)
					end)
	-- mit MQTT-broker verbinden
	m:connect(mqtt_broker, mqtt_port, 0, 0,
			-- Verbindung mit MQTT-Broker hergestellt
			function(conn) 
				print("connected!")
				-- was passiert, wenn keine Verbindung mehr zum Broker...
				m:on("offline", function() mqtt_connect() end)
				-- online melden
				m:publish(mqtt_topic.."status", "on", 0, 1)
				-- MQTT-Kommandozeile initialisieren
				mc.mqtt_cmd_setup(m, client_name, 1, 1)
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

-- MQTT-Client definieren
m = mqtt.Client(client_name, 120, mqtt_user, mqtt_pwd)

-- mit MQTT-Broker verbinden
mqtt_connect()

-- aktuelle Zeit von einem ntp-Server holen und jede Stunde aktualisieren
read_ntp()
tmr.alarm(1, 3600000, 1, function() read_ntp() end)

-- Initialisierung LED-Strip
ws2812.init(ws2812.MODE_SINGLE)

-- einen entsprechenden Buffer reservieren
buffer = ws2812.newBuffer(60, 3); 

-- jede Sekunde die Uhr aktualisieren
tmr.alarm(2, 1000, 1, function()
	s, m, h = get_local_time(tz_offset, with_summertime)
	-- alle LEDs loeschen
	buffer:fill(0, 0, 0)
	-- 5min-Raster setzen
	for i=1, 60, 5 do
		buffer:set(i, 1, 0, 0)
	end	
	-- Sekunde setzen
	g, r, b = buffer:get(s+1)
	buffer:set(s+1, 32,  r,  b)
	-- Minute setzen
	g, r, b = buffer:get(m+1)
	buffer:set(m+1,  g, 32,  b)
	-- Stunde setzen
	if h >= 12 then h = (h-12) end
	h = h*5 + m/12	
	g, r, b = buffer:get(h+1)
	buffer:set(h+1,  g,  r, 32)
	-- und rausschreiben	
	ws2812.write(buffer)
end)
