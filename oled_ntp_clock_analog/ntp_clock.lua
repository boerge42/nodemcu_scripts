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

my_clock = require "my_clock_functions"


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
                print(my_clock.unix2datetime(rtctime.get(), tz, dst))
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
    local dt_h, dt_m, dt_s, dt_y, dt_mo, dt_d, dt_wt = my_clock.unix2datetime(rtctime.get(), tz, dst)
    date_str = string.format("%02d.%02d.%04d", dt_d, dt_mo, dt_y)
    time_str = string.format("%02d:%02d:%02d", dt_h, dt_m, dt_s)
    wt_str   = string.format("%s", wt_names[dt_wt])
    --print ("-->"..dt_wt)
	local std = dt_h
	if std >= 12 then std = (std-12) end
	std=std*5 + dt_m/12
	--Ausgabe auf OLED
    disp:firstPage()
	repeat
		-- Datum/Uhrzeit digital...
		disp:drawStr(127-string.len(time_str)*6, 10, time_str)
		disp:drawStr(127-string.len(wt_str)*6, 50, wt_str)
		disp:drawStr(127-string.len(date_str)*6, 63, date_str)
		-- ... Uhrzeit analog
		-- Ziffernblatt...
		local x0 = 31
		local y0 = 31
		-- Ziffenblatt (5min-Punkte) erzeugen
		for i=0, 59, 5 do
			disp:drawPixel(my_clock.clock_face_point(x0,y0,30,i))
		end
		-- Sekundenzeiger
		disp:drawLine(x0, y0, my_clock.clock_face_point(x0,y0,28,dt_s))
		-- Minutenzeiger
		disp:drawTriangle(my_clock.clock_fat_hand(x0,y0,3,28,dt_m))
		-- Stundenzeiger
		disp:drawTriangle(my_clock.clock_fat_hand(x0,y0,3,18,std))
	until disp:nextPage() == false
end


-- **********************************************************************
function init_i2c_display()
    i2c.setup(0, 4, 3, i2c.SLOW)
    disp = u8g.ssd1306_128x64_i2c(0x3c)
	disp:setFont(u8g.font_6x10)
end


-- **********************************************************************
-- **********************************************************************
-- **********************************************************************

-- I2C und OLED initialisieren
init_i2c_display()

-- Zeit von einem NTP-Server alle Stunde holen
ReadNTP(tz)
tmr.alarm(1, 3600000, 1, function() ReadNTP(tz) end)


ReadRTC()
-- jede Sekunde Display aktualisieren
tmr.alarm(2, 1000, 1, function() ReadRTC() end)

