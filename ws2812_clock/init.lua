-- *********************************************************************
--
--           init.lua fuer ws2812-Clock
--           ==========================
--               Uwe Berger; 2018
--
-- ...Quelltext lesen!
--
-- ---------
-- Have fun!
--
-- *********************************************************************

-- Da wir ja lustige LEDs zur Verfuegung haben, diese animieren (via 
-- Timer 5, der entsprechend (im Hauptprogramm und Erfolgsfall) wieder
-- gestoppt werden sollte..)
ws2812.init(ws2812.MODE_SINGLE)
local buf = ws2812.newBuffer(60, 3)
local i = 0
buf:fill(0, 0, 0)
ws2812.write(buf)
tmr.alarm(5, 10, 1,	function()
							i = i + 1
							buf:fade(2)
							buf:set(i % buf:size() + 1, 0, 0, 255)
							ws2812.write(buf)
						end)

-- WLAN-Konfiguration einlesen
dofile("wlan_config.lua")

-- Hostname setzen
node_hostname = "esp8266-"..node.chipid()

-- mit WLAN verbinden
print("Connecting to wifi...")
wifi.setmode(wifi.STATION)
wifi.sta.config(station_cfg)
wifi.sta.sethostname(node_hostname)
wifi.sta.connect()
-- zyklisch Status abfragen und im Erfolgsfall eigentliches Script
-- starten
tmr.alarm(0, 1000, 1, function()
    print(wifi.sta.status()) 
    ip = wifi.sta.getip()
    if ( ( ip ~= nil ) and  ( ip ~= "0.0.0.0" ) and (wifi.sta.status() == 5))then
        print("IP/Name: "..ip.." / "..wifi.sta.gethostname())
        tmr.unregister(0)
        tmr.unregister(5)
		dofile("clock.lua")
    end
end )


