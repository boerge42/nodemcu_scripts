-- **********************************************************
--                      dht2mqtt.lua
--                    ================
--                    Uwe Berger; 2017
--
--
-- * alle Stunde RTC via NTP synchronisieren
-- * Telnet-Server an Port 8266 bereitstellen, welcher
--   "ts=UNIX-Zeit|stat=Status|temp=Temperatur|Hum=Luftfeuchtigkeit"
--   sendet und dann die Verbindung beendet
-- * zyklisch jede Minute an einen MQTT-Broker folgendes publizieren:
--   ** sensors/<wifi.sta.gethostname()>/ts ...
--   ** sensors/<wifi.sta.gethostname()>/temperature ...
--   ** sensors/<wifi.sta.gethostname()>/humidity ...
--   ** sensors/<wifi.sta.gethostname()>/heap ...
--   ** sensors/<wifi.sta.gethostname()>/readable_timestamp ...
--
-- ---------
-- Have fun!
--
-- **********************************************************

dht_pin  = 4
ntp_server = "de.pool.ntp.org"

mqtt_broker = "10.1.1.82"
client_name = wifi.sta.gethostname()
mqtt_topic = "sensors/"..client_name.."/"

ts 	 = 42
temp = 42
hum  = 42


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
	assert(false)
end

-- **********************************************************************
-- UNIX-Sekunde in lokale Zeit umrechnen und in "lesbaren" String 
function get_readable_local_datetime(tz_offset, dst)
	-- UTC
	ut = rtctime.get()
    tm = rtctime.epoch2cal(ut)
    -- Sommerzeit?
    if dst == true and is_summertime(tm) then
    	ut = ut + 3600
    end
    -- Zeitzone noch einrechnen
    tm = rtctime.epoch2cal(ut + tz_offset * 3600)
    -- Ergebnis in String umwandeln
    return string.format("%04d/%02d/%02d %02d:%02d:%02d", tm["year"], tm["mon"], tm["day"], tm["hour"], tm["min"], tm["sec"])
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

-- mit MQTT-broker verbinden
m = mqtt.Client(client_name, 120)
m:on("connect", function(con) print ("MQTT-Broker connected") end)
m:on("offline", function(con) print ("MQTT-Broker offline") end)
m:connect("10.1.1.82", 1883, 0, 0,
		function(conn) 
			print("connected!")
			-- jede Minute Messwerte via MQTT publizieren
			tmr.alarm(0,60000,1, function() 
									read_values()
									print(ts, client_name)
									m:publish(mqtt_topic.."heap", node.heap(), 0, 1)
									m:publish(mqtt_topic.."temperature", temp, 0, 1)
									m:publish(mqtt_topic.."humidity", hum, 0, 1)
									m:publish(mqtt_topic.."unixtime", ts, 0, 1)
									m:publish(mqtt_topic.."readable_timestamp", get_readable_local_datetime(1, true), 0, 1)
								end) 
		end,
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
