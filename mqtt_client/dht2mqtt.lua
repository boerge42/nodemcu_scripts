-- **********************************************************
--                      dht2mqtt.lua
--                    ================
--                    Uwe Berger; 2017
--
--
-- * alle Stunde RTC via NTP synchronisieren
-- * Telnet-Server an Port 8266 bereitstellen, welcher
--   "ts=UNIX-Zeit|stat=Status|temp=Temperatur|Hum=Luftfeuchtigkeit|heap=freier dyn. Speicher"
--   sendet und dann die Verbindung beendet
-- * Nachrichten an einen MQTT-Broker senden:
--   ** ohne Anmeldung und unverschluesselt 
--   ** Sensorstatus via Topic sensors/<wifi.sta.gethostname()>/status
--      *** on  --> Sensor ist aktiv
--      *** off --> Sensor ist nicht aktiv --> wird als MQTT-Testament 
--                  bei Start des Sensors gesetzt
--   ** zyklisch jede Minute an einen MQTT-Broker folgendes publizieren:
--      *** sensors/<wifi.sta.gethostname()>/ts ...
--      *** sensors/<wifi.sta.gethostname()>/temperature ...
--      *** sensors/<wifi.sta.gethostname()>/humidity ...
--      *** sensors/<wifi.sta.gethostname()>/heap ...
--      *** sensors/<wifi.sta.gethostname()>/readable_timestamp ...
--   ** saemtliche MQTT-Telegramme werden mit gesetztem Retain-Flag 
--      an den Broker gesendet
--
-- ---------
-- Have fun!
--
-- **********************************************************

dht_pin  = 4
ts, stat, temp, hum = 0, -1, "xx", "xx"

ntp_server = "de.pool.ntp.org"

mqtt_broker = "10.1.1.82"
client_name = wifi.sta.gethostname()
mqtt_topic = "sensors/"..client_name.."/"

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

-- **********************************************************************
-- UNIX-Sekunde in lokale Zeit umrechnen und in "lesbaren" String umwandeln
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
-- DHT und RTC auslesen
function read_values()
	stat, temp, hum, temp_dec, hum_dec = dht.read(dht_pin)
	if stat == dht.OK then
		temp = temp.."."..temp_dec/100
		hum  = hum.."."..hum_dec/100
	end
	ts = rtctime.get()
end

-- **********************************************************************
-- Messwerte via MQTT publizieren
function publish_values()
	m:publish(mqtt_topic.."heap", node.heap(), 0, 1)
	m:publish(mqtt_topic.."temperature", temp, 0, 1)
	m:publish(mqtt_topic.."humidity", hum, 0, 1)
	m:publish(mqtt_topic.."unixtime", ts, 0, 1)
	m:publish(mqtt_topic.."readable_timestamp", get_readable_local_datetime(1, true), 0, 1)
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
-- **********************************************************************
-- **********************************************************************

-- aktuelle Zeit von einem ntp-Server holen und jede Stunde aktualisieren
read_ntp()
tmr.alarm(1, 3600000, 1, function() read_ntp() end)

-- mit MQTT-Client definieren
m = mqtt.Client(client_name, 120)

-- MQTT-Testament dieses Sensors festlegen...
m:lwt(mqtt_topic.."status", "off", 0, 1)

-- mit MQTT-broker verbinden
m:connect("10.1.1.82", 1883, 0, 0,
		-- Verbindung mit MQTT-Broker hergestellt
		function(conn) 
			print("connected!")
			-- Sensor online melden
			m:publish(mqtt_topic.."status", "on", 0, 1)
			-- jede Minute Messwerte via MQTT publizieren
			tmr.alarm(0,60000,1, function() 
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