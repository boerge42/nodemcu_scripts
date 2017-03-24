-- **********************************************************
--                      mqttoled.lua
--                    ================
--                    Uwe Berger; 2017
--
-- Abonnieren eines (bestimmten) MQTT-Topic, deren Auswertung
-- und Anzeige auf einem OLED
-- 
-- MQTT-Topics
-- -----------
-- sensors/<node-name>/status
-- sensors/<node-name>/unixtime
-- sensors/<node-name>/temperature
-- sensors/<node-name>/humidity
-- sensors/<node-name>/heap
-- sensors/<node-name>/readable_timestamp
--
-- Innerhalb von zwei Listen werden die empfangenen Werte pro node-name
-- strukturiert abgelegt. Aus diesen Listen werden zyklisch die Ausgaben
-- auf das OLED gelesen.
--
--
-- ---------
-- Have fun!
--
-- **********************************************************

-- MQTT-Zeugs
mqtt_broker = "10.1.1.82"
mqtt_port = 1883
mqtt_topic = "sensors/#"
client_name = wifi.sta.gethostname()

-- I2C fuer OLED
pin_sda = 3
pin_scl = 4

-- intern...
nodes = {}
sensors = {}
idx = 1

-- **********************************************************************
function display()
	-- sind ueberhaupt Daten zum anzeugen da?
	if #nodes < 1 then return end
	disp:firstPage()
	repeat
		disp:setFont(u8g.font_6x10)
		disp:drawStr(0, 7, nodes[idx])
		disp:drawStr(0, 17, sensors[nodes[idx]]["status"].." ("..sensors[nodes[idx]]["heap"].."Byte)")
		disp:drawStr(0, 27, sensors[nodes[idx]]["readable_timestamp"])
		disp:setFont(u8g.font_9x15)
		disp:drawStr(35, 43, sensors[nodes[idx]]["temperature"]..string.char(0xB0).."C")
		disp:drawStr(35, 58, sensors[nodes[idx]]["humidity"].."%")
        -- Position anzeigen
        local dx = 128/#nodes
        x, y = dx/2, 63
		for i=1, #nodes, 1 do
			if i == idx then
				disp:drawHLine(x-2, y, 5)
			else 
				disp:drawHLine(x, y, 1)
			end
			x=x+dx
		end
	until disp:nextPage() == false
	-- naechstes Node...
	idx = idx + 1
	if idx > #nodes then idx = 1 end
end


-- **********************************************************************
function fill_lists(topic, data)
	if (topic ~= nil) and (data ~= nil) then
		-- topic auseinander nehmen
		local ts = {}
		for s in string.gmatch(topic, "([^/]+)") do
			table.insert(ts, s)
		end
		-- es sollten 3 Listenelemte entstanden sein (siehe oben)
		if #ts == 3 then
			-- wenn dieses Node noch nicht bekannt, dann Liste initialisieren
			if sensors[ts[2]] == nil then
				--nodes[#nodes+1]=ts[2]
				table.insert(nodes, ts[2])
				sensors[ts[2]]={}
			end
			-- Wert in entsprechende Struktur uebernehmen
			sensors[ts[2]][ts[3]] = data
		end
	end
end


-- **********************************************************************
-- **********************************************************************
-- **********************************************************************

-- OLED initialisieren
i2c.setup(0, pin_sda, pin_scl, i2c.SLOW)
disp = u8g.ssd1306_128x64_i2c(0x3c)

-- mit MQTT-Client definieren
m = mqtt.Client(client_name, 120)

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
			-- Topic abonnieren
			m:subscribe(mqtt_topic, 0,	function(client) 
											print("subscribe success") 
										end)
		end,
		-- keine Verbindung mit MQTT-Broker zustande gekommen
		function(conn, reason)
			print("MQTT-Connect failed: "..reason)
		end
)

tmr.alarm(0, 5000, 1, function() display() end)
