-- **********************************************************
--                     dht_telnet.lua
--                    ================
--                    Uwe Berger; 2016
--
--
-- * alle 10s einen angeschlossenen DHTxx-Sensor und RTC auslesen
-- * alle Stunde RTC via NTP synchronisieren
-- * via Port 8266 (;-)) einen Telnet-Server bereitstellen, welcher
--
--   ts=UNIX-Zeit|stat=Status|temp=Temperatur|Hum=Luftfeuchtigkeit
--
--   sendet und dann die Verbindung beendet
--   (Status == 0 --> alles gut!)
--
-- ---------
-- Have fun!
--
-- **********************************************************

dht_pin  = 4
ntp_server = "de.pool.ntp.org"

stat="xx"
ts="42"
hum="xx"
temp="xx"

-- **********************************************************************
-- DHT und RTC auslesen
function read_values()
	stat, temp, hum, temp_dec, hum_dec = dht.read(dht_pin)
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

-- RTC via NTP einmal synchronisieren
read_ntp()

-- alle Werte einmal auslesen
read_values()

-- RTC alle Stunde via NTP synchronisieren
tmr.alarm(1, 3600000, 1, function() read_ntp() end)

-- alle Werte zyklisch jede Sekunde auslesen 
tmr.alarm(2, 1000, 1, function() read_values() end)

-- Telnet-Server auf Port 8266...
srv=net.createServer(net.TCP) 
srv:listen(8266,function(conn) 
        local buf="ts="..ts.."|stat="..stat.."|temp="..temp.."|hum="..hum..""
        conn:send(buf)
        conn:close()
		end)

