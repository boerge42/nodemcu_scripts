-- *********************************************************************
--
--                      z80_wifi.lua
--                    =================
--                    Uwe Berger; 2020
--
--
-- ...Quelltext lesen!
--
-- ---------
-- Have fun!
--
-- *********************************************************************

--mc=require "mqtt_cmd"

-- Uhrzeitzeugs
ntp_server      = "de.pool.ntp.org"		-- NTP-Server
tz_offset       = 1                     -- Stundenoffset der Zeitzone
with_summertime = true                  -- Sommerzeit beachten?

--MQTT-Zeugs
mqtt_broker = "10.1.1.82"
client_name = wifi.sta.gethostname()
mqtt_topic = "sensors/"..client_name.."/"
node_type = "Z80"
mqtt_interval = 300000     -- ms -> 5min (300000)

node_alias=""
if file.exists("nodealias") then
	dofile("nodealias")
end

-- my2wire-Zeugs
pin_clock = 6
pin_data  = 7
my2w_read_data = false
ts, z80_temperature = 0, "xx"
my2w_value = 0
bit_idx = 0


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

-- *********************************************************************
function display_datetime()
	local second, minute, hour, day, month, year = get_local_time(tz_offset, with_summertime)
    date_str = string.format("%02d.%02d.%04d", day, month, year)
    time_str = string.format("%02d:%02d:%02d", hour, minute, second)
    print(""..date_str..", "..time_str.."")
end

-- **********************************************************************
-- momentane UNIX-Sekunde von einem NTP-Server holen und RTC setzen
function read_ntp()
    net.dns.resolve(ntp_server, 
    				function(sk, ip)
	    				if (ip == nil) then 
    						print("DNS failed!") 
							-- nach 5 Sekunden naechster Versuch...
							ntp_fail_timer = tmr.create()
							ntp_fail_timer:register(5000, tmr.ALARM_SINGLE, function() read_ntp() end)
							ntp_fail_timer:start()
							
					   	else
        					sntp.sync(ip,
            					function(sec,usec,server)
                					print('sync', sec, usec, server)
                					rtctime.set(sec, usec)
                					-- in einer Stunde Uhrzeit synchronisieren
									ntp_sync_timer = tmr.create()
									ntp_sync_timer:register(3600000, tmr.ALARM_SINGLE, function() read_ntp() end)
									ntp_sync_timer:start()
									display_datetime()
            					end,
            					function()
               						print('NTP sync failed!')
               						-- nach 5 Sekunden naechster Versuch...
									ntp_fail_timer = tmr.create()
									ntp_fail_timer:register(5000, tmr.ALARM_SINGLE, function() read_ntp() end)
									ntp_fail_timer:start()
            					end)
        				end
    				end) 
end

-- **********************************************************************
-- Messwerte via MQTT publizieren
function publish_values()
	
	ts = rtctime.get()
	
	m:publish(mqtt_topic.."heap", node.heap(), 0, 1)
	m:publish(mqtt_topic.."status", "on", 0, 1)
	m:publish(mqtt_topic.."node_alias", node_alias, 0, 1)
	m:publish(mqtt_topic.."node_type", node_type, 0, 1)
	m:publish(mqtt_topic.."temperature", z80_temperature, 0, 1)
	m:publish(mqtt_topic.."unixtime", ts, 0, 1)
	m:publish(mqtt_topic.."readable_timestamp", get_readable_local_datetime(1, true), 0, 1)
	-- Lua-List
	local l="{"
	l=l.."heap=\""..node.heap()
	--l=l.."\",status=\"on"
	l=l.."\",temperature=\""..z80_temperature
	l=l.."\",unixtime=\""..ts
	l=l.."\",node_name=\""..client_name
	l=l.."\",node_alias=\""..node_alias
	l=l.."\",node_type=\""..node_type
	l=l.."\",readable_ts=\""..get_readable_local_datetime(1, true)
	l=l.."\"}"
	m:publish(mqtt_topic.."lua_list", l, 0, 1)
	-- JSON
	l="{"
	l=l.."\"heap\":\""..node.heap()
	l=l.."\",\"temperature\":\""..z80_temperature
	l=l.."\",\"unixtime\":\""..ts
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
	mqtt_error_timer = tmr.create()
	mqtt_error_timer:register(10000, tmr.ALARM_SINGLE, mqtt_connect())
	mqtt_error_timer:start()
end

-- **********************************************************************
-- mit MQTT-Broker verbinden etc. ...
function mqtt_connect()
	-- MQTT-Testament dieses Sensors festlegen...
	m:lwt(mqtt_topic.."status", "off", 0, 1)
--	-- ...wenn eine MQTT-Nachricht ueber die abonnierten Kanaele kommt
--	m:on("message", function(client, topic, data) 
--					-- MQTT-Kommandozeile...
--					mc.mqtt_cmd_message(topic, data)
--					end)
	-- mit MQTT-broker verbinden
	m:connect(mqtt_broker, 1883, 0,
			-- Verbindung mit MQTT-Broker hergestellt
			function(conn) 
				print("mqtt connected!")
				-- was passiert, wenn keine Verbindung mehr zum Broker...
				m:on("offline", function() mqtt_connect() end)
				-- Sensor online melden
				m:publish(mqtt_topic.."status", "on", 0, 1)
--				-- MQTT-Kommandozeile initialisieren
--				mc.mqtt_cmd_setup(m, client_name, 1, 1)
				-- jede Minute Messwerte via MQTT publizieren
				mqtt_pub_timer = tmr.create()
				mqtt_pub_timer:register(mqtt_interval, tmr.ALARM_AUTO, function()
																			publish_values()
																		 end)
				mqtt_pub_timer:start()
			end,
			-- keine Verbindung mit MQTT-Broker zustande gekommen
			function(conn, reason)
				print("MQTT-Connect failed: "..reason)
				mqtt_error_handle()
			end
	)
end

-- *********************************************************************
function pin_clock_down()
	-- Bits lesen?
	if my2w_read_data == true then
		if gpio.read(pin_data) == 1 then 
			my2w_value = bit.set(my2w_value, bit_idx) 
		end
		bit_idx = bit_idx + 1
	end
end

-- *********************************************************************
function pin_data_up()
	-- Stopp-Bedingung?
	if gpio.read(pin_clock) == 1 then
		my2w_read_data = false
		gpio.trig(pin_clock, "none")
		gpio.trig(pin_data, "down", pin_data_down)
		print(my2w_value)
		z80_temperature = ""..my2w_value..""
		my2w_value = 0
		bit_idx = 0
	end
end

-- *********************************************************************
function pin_data_down()
	-- Start-Bedingung?
	if gpio.read(pin_clock) == 1 then
		my2w_read_data = true
		gpio.trig(pin_data, "up", pin_data_up)
		gpio.trig(pin_clock, "down", pin_clock_down)
	end
end


-- *********************************************************************
-- *********************************************************************
-- *********************************************************************

node.setcpufreq(node.CPU160MHZ)

-- aktuelle Zeit von einem ntp-Server holen und jede Stunde aktualisieren
read_ntp()

-- PINs 
gpio.mode(pin_clock, gpio.INT)
gpio.mode(pin_data, gpio.INT)

gpio.trig(pin_clock, "none")
gpio.trig(pin_data, "down", pin_data_down)

-- mit MQTT-Client definieren
m = mqtt.Client(client_name, 120)

-- mit MQTT-Broker verbinden
mqtt_connect()



