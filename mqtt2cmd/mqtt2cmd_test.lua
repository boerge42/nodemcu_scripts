-- *********************************************************************
--
--                    mqtt2cmd_test.lua
--                    =================
--                    Uwe Berger; 2018
--
-- Test fuer Modul mqtt2cmd.lua
--
-- ---------
-- Have fun!
--
-- *********************************************************************

mc=require "mqtt_cmd"

dofile("mqtt_config.lua")

client_name = wifi.sta.gethostname()
mqtt_topic = client_name.."/"

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
