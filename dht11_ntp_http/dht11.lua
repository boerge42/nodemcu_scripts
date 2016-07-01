-- **********************************************************
--                        dht11.lua
--                    ================
--                    Uwe Berger; 2016
--
-- > stuendlich aktuelle Zeit von einem NTP-Server holen
-- > minuetlich einen DHT11 auslesen
-- > Bereitstellung eines HTTP-Severs auf Port 80, welcher
--   Temperatur, Luftfeuchtigkeit und Datum/Uhrzeit zurueck-
--   gibt
--
-- ---------
-- Have fun!
--
-- **********************************************************

-- Konfiguration...
ntp_server = "de.pool.ntp.org"
dht11_pin  = 4
tz         = 1         -- Offset Zeitzone
dst        = true      -- mit Sommerzeit ja/nein --> true/false

humi="XX"
temp="XX"
dt_str="XX"

-- **********************************************************************
-- momentane UNIX-Sekunde von einem NTP-Server holen und internen 
-- Zeitzaehler mit Ergebnis abgleichen
function ReadNTP(tz)
    net.dns.resolve(ntp_server, function(sk, ip)
    if (ip == nil) then print("DNS failed!") else
        sntp.sync(ip,
            function(sec,usec,server)
                print('sync', sec, usec, server)
                rtctime.set(sec, usec)
                ReadRTC()
                print(unix2datetime(rtctime.get(), tz, dst))
            end,
            function()
                print('NTP sync failed!')
            end)
        end
    end) 
end

-- **********************************************************************
-- DHT11 auslesen
function ReadDHT11()
    status, temp, humi, temp_dec, humi_dec = dht.read(dht11_pin)
    print("DHT11: "..humi.."%, "..temp.." deg C")
end

-- **********************************************************************
-- RTC auslesen und formatieren
function ReadRTC()
    local dt_h, dt_m, dt_s, dt_y, dt_mo, dt_d, dt_wt = unix2datetime(rtctime.get(), tz, dst)
    dt_str = string.format("%02d.%02d.%04d, %02d:%02d:%02d", 
                           dt_d, dt_mo, dt_y, dt_h, dt_m, dt_s)
    print(dt_str)
end


-- **********************************************************************
-- UNIX-Sekunden in Stunde, Minute, Sekunde, Tag, ... umrechnen 
-- Parameter tz_offset --> Zeitzone in Stunden
-- Parameter with_dst --> true/false --> mit/ohne Sommerzeit
function unix2datetime(t, tz_offset, with_dst)
    local jd, f, e, h, y, m, d, hour, minute, second, wt
    local DayOfMonth = {31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
    -- Zeitzone
    t = t + (tz_offset * 3600)
    -- Datum/Uhrzeit berechnen
    jd = t / 86400 + 2440588
    f = jd + 1401 + (((4 * jd + 274277) / 146097) * 3) / 4 - 38
    e = 4 * f + 3
    h = 5 * ((e % 1461) / 4) + 2
    d = (h % 153) / 5 + 1
    m = (h / 153 + 2) % 12 + 1
    y = e / 1461 - 4716 + (14 - m) / 12
    hour = (t%86400/3600)
    minute = (t%3600/60)
    second = (t%60)
    wt = (jd%7+1)
    -- Sommerzeit?
    if (with_dst ~= true) then return hour, minute, second, y, m, d, wt end
    -- letzter Sonntag im Maerz 02:00 bis letzter Sonntag im Oktober 03:00 --> plus 1h
    if ((m < 3) or (m > 10)) then return hour, minute, second, y, m, d, wt end 
    if( ((d - wt) >= 25) and (wt or (hour >= 2)) ) then
        if( m == 10 ) then return hour, minute, second, y, m, d, wt end
    else
        if( month == 3 ) then return hour, minute, second, y, m, d, wt end
    end
    hour = hour + 1
    if (hour == 24) then
        hour = 0;
        wt = wt + 1
        if (wt == 7) then wt = 0 end
        if (day == DayOfMonth[m]) then
            d = 0;
            m = m + 1
        end
        d = d + 1
    end
    return hour, minute, second, y, m, d, wt
end



-- **********************************************************************
-- **********************************************************************
-- **********************************************************************

-- Zeit von einem NTP-Server alle Stunde holen
ReadNTP(tz)
tmr.alarm(1, 3600000, 1, function() ReadNTP(tz) end)

-- DHT11 einmal auslesen
ReadDHT11()

-- DHT11/RTC zyklisch jede 10s auslesen 
tmr.alarm(2, 10000, 1, function() 
                           ReadDHT11()
                           ReadRTC() 
                        end)

-- HTTP-Server
srv=net.createServer(net.TCP) 
srv:listen(80,function(conn) 
    conn:on("receive",function(conn,request) 
        --print(request)
        local buf=""
        buf=buf.."<h1>Uwes DHT11-Server!</h1>"
        buf=buf.."<table>"
        buf=buf.."<tr><td>Temperatur:</td><td>"..temp.."&deg;C</td></tr>"
        buf=buf.."<tr><td>Luftfeuchtigkeit:</td><td>"..humi.."%</td></tr>"
        buf=buf.."<tr><td>Zeitstempel:</td><td>"..dt_str.."</td></tr>"
        buf=buf.."</table>"
        conn:send(buf)
        conn:close()
        end) 
end)
