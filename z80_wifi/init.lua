-- *********************************************************************
--
--           init.lua fuer z80_wifi
--           ======================
--              Uwe Berger; 2018
--
-- ...Quelltext lesen!
--
-- ---------
-- Have fun!
--
-- *********************************************************************


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
local wifi_init_timer = tmr.create()
wifi_init_timer:register(1000, tmr.ALARM_AUTO, function() 
	print(wifi.sta.status()) 
    ip = wifi.sta.getip()
    if ( ( ip ~= nil ) and  ( ip ~= "0.0.0.0" ) and (wifi.sta.status() == 5))then
        print("IP/Name: "..ip.." / "..wifi.sta.gethostname())
        wifi_init_timer:unregister()
		dofile("z80_wifi.lua")
    end
end)
wifi_init_timer:start()
