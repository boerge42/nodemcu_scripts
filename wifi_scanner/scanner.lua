-- **********************************************************
--                    wifi_scanner.lua
--                    ================
--                    Uwe Berger; 2016
--
-- > alle 3 Sekunden WLAN nach APs scannen und entsprechende Informationen
--   zu den gefundenen APs ausgeben
--
-- ---------
-- Have fun!
--
-- **********************************************************

--Wifi-Mode STATION, um SSID-Broadcast empfangen zu koennen
wifi.setmode(wifi.STATION) 


tmr.alarm(0,3000,1,function() --A timer, which used to run the following program 
    wifi.sta.getap(function(t) 
			for ssid,v in pairs(t) do
				local authmode, rssi, bssid, channel = string.match(v, "([^,]+),([^,]+),([^,]+),([^,]+)")
				print(""..ssid..", "..bssid..", "..rssi.."db, "..authmode..", "..channel.."")
			end
            print("=======")
    end)
end)
