-- **********************************************************************
--
--                     mqtt_cmd.lua
--                    ================
--                    Uwe Berger; 2017
--
-- ...quasi eine Kommando-Shell auf Basis MQTT

-- Shell-Input  MQTT-Topic: <mqtt_topic>/cmd
-- Shell-Output MQTT-Topic: <mqtt_topic>/output
--
-- Zur Initialisierung sind folggende Funktionen in der eigentlichen
-- Lua-Anwendung aufzurufen:
--
-- Eigentliche Initialisierung nach erfolgreicher Verbindung zum
-- MQTT-Broker 
-- * mqtt_cmd_setup(mqtt, mqtt_topic, output2mqtt, debug_output)
--   ** mqtt --> MQTT-Verbindung
--   ** mqtt_topic --> MQTT-Topic-Teil vor cmd bzw. output
--   ** output2mqtt: 0 --> keine Ausgabe via MQTT 
--                   1 --> Ausgabe via MQTT (<mqtt_topic>/output)
--   ** debug_output --> ... node.output(mqtt_output, debug_output)
--                                                    ^^^^^^^^^^^^
--
-- In der Methode der Lua-AQnwendung, in der eingehende MQTT-Nachrichten 
-- behandelt werden
-- * mqtt_cmd_message()
--
-- ---------
-- Have fun!
--
-- *********************************************************************
 

local M = {}

M.debug_output = 0
M.output2mqtt  = 0
M.mqtt		   = 0         
M.mqtt_topic   = ""


-- **********************************************************************
-- Callback-Funktion zur Umlenkung der Ausgabe auf einen MQTT-Topic
-- ...
-- ...(intern) in mqtt_cmd_subscribe()
-- ...
local function mqtt_output(str)
	M.mqtt:publish(client_name.."/output", str, 0, 0)
end

-- **********************************************************************
-- CMD-Kanal abbonieren

local function mqtt_cmd_subscribe()
	M.mqtt:subscribe(M.mqtt_topic.."/cmd", 0, 
				function(conn) 
					if M.output2mqtt == 1 then 
						node.output(mqtt_output, M.debug_output)
					end
				end)
end

-- **********************************************************************
-- MQTT-CMD initialisieren
-- ...
-- ...wenn Verbindung zu MQTT-Broker erfolgreich...
-- ...
function M.mqtt_cmd_setup(mqtt, mqtt_topic, output2mqtt, debug_output)
	M.mqtt = mqtt
	if mqtt_topic   ~= nil then M.mqtt_topic = mqtt_topic end
	if output2mqtt  ~= nil then M.output2mqtt = output2mqtt end
	if debug_output ~= nil then M.debug_output = debug_output end
	mqtt_cmd_subscribe()
end


-- **********************************************************************
-- via MQTT empfangenes Kommando ausfuehren
-- ...
-- ...aufgerufen in --> m:on("message", ...
-- ...
function M.mqtt_cmd_message(topic, data)
	if topic == M.mqtt_topic.."/cmd" then 
		node.input(data)
	end
end


return M
