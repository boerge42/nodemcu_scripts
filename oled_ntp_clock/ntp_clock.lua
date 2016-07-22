-- **********************************************************
--                     ntp_clock.lua
--                    ================
--                    Uwe Berger; 2016
--
-- > stuendlich aktuelle Zeit von einem NTP-Server holen
-- > jede Sekunde Datum/Zeit auf eibnem OLED ausgeben
--
-- ---------
-- Have fun!
--
-- **********************************************************

-- Konfiguration...
ntp_server = "de.pool.ntp.org"
tz         = 1         -- Offset Zeitzone
dst        = true      -- mit Sommerzeit ja/nein --> true/false

date_str="XX"
time_str="XX"
wt_str="XX"

wt_names = {"Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag", "Sonntag"}

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
-- RTC auslesen und formatieren
function ReadRTC()
    local dt_h, dt_m, dt_s, dt_y, dt_mo, dt_d, dt_wt = unix2datetime(rtctime.get(), tz, dst)
    date_str = string.format("%02d.%02d.%04d", dt_d, dt_mo, dt_y)
    time_str = string.format("%02d:%02d:%02d", dt_h, dt_m, dt_s)
    wt_str   = string.format("%s,", wt_names[dt_wt])
    disp:firstPage()
	repeat
		disp:drawStr(5, 20, wt_str)
		disp:drawStr(5, 40, date_str)
		disp:drawStr(5, 60, time_str)
	until disp:nextPage() == false
--    print(""..date_str..", "..time_str.."")
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
function init_i2c_display()
    i2c.setup(0, 4, 3, i2c.SLOW)
    disp = u8g.ssd1306_128x64_i2c(0x3c)
	disp:setFont(u8g.font_9x15)
end


-- **********************************************************************
-- **********************************************************************
-- **********************************************************************

-- I2C und OLED initialisieren
init_i2c_display()

-- Zeit von einem NTP-Server alle Stunde holen
ReadNTP(tz)
tmr.alarm(1, 3600000, 1, function() ReadNTP(tz) end)

-- jede Sekunde Display aktualisieren
tmr.alarm(2, 1000, 1, function() 
                           ReadRTC() 
                        end)

