-- **********************************************************
--                     dht_telnet.lua
--                    ================
--                    Uwe Berger; 2016
--
--
-- * alle 10s einen angeschlossenen DHTxx-Sensor auslesen
-- * via Port 8266 (;-)) einen Telnet-Server bereitstellen, welcher
--
--   Status|Temperatur|Feuchtigkeit
--
--   sendet und dann die Verbindung beendet
--   (Status == 0 --> alles gut!)
--
-- ---------
-- Have fun!
--
-- **********************************************************

dht_pin  = 4

status="xx"
humi="XX"
temp="XX"

-- **********************************************************************
-- DHT auslesen
function ReadDHT()
	status, temp, humi, temp_dec, humi_dec = dht.read(dht_pin)
end


-- **********************************************************************
-- **********************************************************************
-- **********************************************************************

-- DHT einmal auslesen
ReadDHT()

-- DHT zyklisch jede 10s auslesen 
tmr.alarm(2, 10000, 1, function() 
                           ReadDHT()
                        end)

-- Telnet-Server auf Port 8266...
srv=net.createServer(net.TCP) 
srv:listen(8266,function(conn) 
        local buf=""..status.."|"..temp.."|"..humi..""
        conn:send(buf)
        conn:close()
end)

