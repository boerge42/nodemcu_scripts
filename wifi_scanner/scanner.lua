-- **********************************************************
--                       wifi_scanner.lua
--                    ======================
--                    Uwe Berger; 2016, 2017
--
-- > alle 3 Sekunden WLAN nach APs scannen und entsprechende Informationen
--   zu den gefundenen APs ausgeben (serielle Schnittstelle, OLED)
--
-- ---------
-- Have fun!
--
-- **********************************************************


scan = {}


-- **********************************************************************
function init_i2c_display()
    i2c.setup(0, 4, 3, i2c.SLOW)
    disp = u8g.ssd1306_128x64_i2c(0x3c)
    disp:setFont(u8g.font_6x10)
end

-- **********************************************************************
function oled_display()
    disp:firstPage()
        repeat
            local y = 7
            for i = 1, #scan do
                disp:drawStr(0, y, scan[i].val[1])
                y = y + 10
                disp:drawStr(5, y, scan[i].val[2].." "..scan[i].val[3].."dB "..scan[i].val[4].." "..scan[i].val[5])
                y = y + 11
            end
            
        until disp:nextPage() == false
end


-- **********************************************************************
-- **********************************************************************
-- **********************************************************************

-- I2C und OLED initialisieren
init_i2c_display()


--Wifi-Mode STATION, um SSID-Broadcast empfangen zu koennen
wifi.setmode(wifi.STATION) 


tmr.alarm(0,3000,1,function() --A timer, which used to run the following program 
    wifi.sta.getap(1, function(t)
        local i = 1
        scan = {}
        for bssid,v in pairs(t) do
            val = {bssid, string.match(v, "([^,]+),([^,]+),([^,]+),([^,]*)")}
            print(val[1].." "..val[3].."dB "..val[2].." "..val[4].." "..val[5])
            scan[i] = {}
            scan[i] = {val=val}
            i = i + 1
        end
        print("")
        oled_display()
    end)
end)

