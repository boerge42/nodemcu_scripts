-- **********************************************************************
--
--                     mqtt_cmd.lua
--                    ================
--                    Uwe Berger; 2017
--
-- ...quasi eine Kommando-Shell auf Basis MQTT

-- Shell-Input  MQTT-Topic: <mqtt_topic>/cmd...
-- Shell-Output MQTT-Topic: <mqtt_topic>/output
--
-- Zur Initialisierung sind folgende Funktionen in der eigentlichen
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
-- In der Methode der Lua-Anwendung, in der eingehende MQTT-Nachrichten 
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

local token = {}


-- **********************************************************************
-- Callback-Funktion zur Umlenkung der Ausgabe auf einen MQTT-Topic
-- 
local function mqtt_output(str)
	M.mqtt:publish(client_name.."/output", str, 0, 0)
end

-- **********************************************************************
-- ein Kommando loeschen
--
function M.mqtt_cmd_delcmd(c)
	if c ~= nil and token[c] ~= nil then token[c] = nil end
end

-- **********************************************************************
-- ein Kommando hinzufuegen --> geht noch nicht :-(
--
--function M.mqtt_cmd_addcmd(c, d)
--	if c ~= nil and token[c] == nil and d ~= nil then
--		local f = loadstring(d) 
--		token[c] = f()
--	end
--end

-- **********************************************************************
-- Implementierungen der Kommandos

-- ****** heap *******
token["heap"] =
function() mqtt_output(node.heap()) end

-- ****** restart *******
token["restart"] = 	
function() node.restart() end
				
-- ****** cat *******
token["cat"] =		
function(p)
	if file.open(p[2], "r") then
		mqtt_output(file.read())
		file.close()
	end
end
				
-- ****** ls *******
token["ls"] =
function()
	for k,v in pairs(file.list()) do mqtt_output(k..", "..v) end
end

-- ****** rm *******
token["rm"] =
function(p) file.remove(p[2]) end

-- ****** run *******
token["run"] =
function(p) dofile(p[2]) end
					
-- ****** compile *******
token["compile"] =
function(p) node.compile(p[2]) end

-- ****** delcmd *******
--token["delcmd"] =
--function (p) M.mqtt_cmd_delcmd(p[2]) end 

-- ****** .../cmd/interpr data *******
--token["interpr"] =
--function(p, d) 
--	if d ~= nil then node.input(d) end 
--end

-- ****** .../cmd/addcmd/<cmd> data *******
--token["addcmd"] =
--function(p, d) M.mqtt_cmd_addcmd(p[3], d) end

-- ****** .../cmd/write/<filename> data *******
token["write"] = 
function(p, d)
	if file.open(p[3], "w") then
		file.write(d)
		file.close()
	end
end

-- **********************************************************************
local function split(str, sep)
    local array = {}
    local reg = string.format("([^%s]+)",sep)
    for mem in string.gmatch(str,reg) do
        table.insert(array, mem)
    end
    return array
end

-- **********************************************************************
-- CMD-Kanal abbonieren
local function mqtt_cmd_subscribe()
	M.mqtt:subscribe(M.mqtt_topic.."/cmd/#", 0, 
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
	-- Topic splitten
	local ts = split(topic,"/")
	-- vorne in der Tabelle alles weg bis "cmd"
	while (#ts > 0) and (ts[1] ~= "cmd") do table.remove(ts, 1) end
	-- wenn noch Elemente in Tabelle, dann sind auch Kommandos dabei
	if #ts == 1 then
		-- Kommando befindet sich im Payload
		--if data ~= nil then	node.input(data) end
		if data ~= nil and #data > 0 then
			-- Payload splitten
			local ds = split(data, " ")
			if #ds > 0 then
				-- ein bekanntes Kommando?
				if token[ds[1]] == nil then
					mqtt_output(ds[1].." --> unknown command")
				else
					-- Kommando ausfuehren
					token[ds[1]](ds)
				end		
			end
		end
	elseif #ts > 1 then
		-- aus Topic zusammengesetztes Kommando
		-- ...ein bekanntes Kommando?
		if token[ts[2]] == nil then
			mqtt_output(ts[2].." --> unknown command")
		else
			-- Kommando ausfuehren
			token[ts[2]](ts, data)
		end
	end
end

return M
