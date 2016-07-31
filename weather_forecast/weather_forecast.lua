-- **********************************************************************
--   weather_forecast.lua
--   ====================
--     Uwe Berger; 2016
--
-- Wettervorhersage jede Stunde fuer woeid=xxx von Yahoo (im JSON-Format)
-- holen und entsprechend auf einem OLED (128x64) anzeigen --> Anzeige 
-- automatisch alle 5s tageweise rollierend
--
--
-- ---------
-- Have fun!
--
-- **********************************************************************

local woeid = 640720
local url = "http://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20%20weather.forecast%20where%20woeid%20%3D%20"..woeid.."%20and%20u%3D%20%22c%22&format=json"

local f = nil
local idx = 1

-- **********************************************************************
function init_i2c_display()
    i2c.setup(0, 4, 3, i2c.SLOW)
    disp = u8g.ssd1306_128x64_i2c(0x3c)
end

-- **********************************************************************
function split_str(inputstr, sep)
    if sep == nil then sep = "%s" end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end

-- **********************************************************************
function display_forecast()
    if f ~= nil then
        disp:firstPage()
        repeat
            disp:setFont(u8g.font_9x15)
            disp:drawStr(0, 10, ""..f[idx].day.."")
            disp:drawStr(0, 25, ""..f[idx].date.."")
            disp:drawStr(0, 40, ""..f[idx].low.."/"..f[idx].high.."")
            disp:setFont(u8g.font_6x10)
            -- Text eventuell auf mehrere Zeilen verteilen
            s=split_str(f[idx].text, " ")
            local x=0
            local y=52
            local i=1
            for i=1, #s, 1 do
                if (x+string.len(s[i])*6) < 128 then
                    disp:drawStr(x, y, ""..s[i].."")
                    x=x+(string.len(s[i])*6)+6
                else
                    x=0
                    y=y+10
                    disp:drawStr(x, y, ""..s[i].."")
                end
            end
            -- Tagesposition in der Vorhersage anzeigen
            local dx = 128/#f
            x=dx/2
            y=63
            for i=1, #f, 1 do
                if i == idx then
                    disp:drawHLine(x-2, y, 5)
                else 
                    disp:drawHLine(x, y, 1)
                end
                x=x+dx
            end
        until disp:nextPage() == false
        idx = idx + 1
        if idx > #f then idx = 1 end
    end
end

-- **********************************************************************
function get_weather_forecast ()
    http.get(url, nil, function(code, data)
        if (code < 0) then
            print("HTTP request failed")
        else
            local t = cjson.decode(data)
            f = t.query.results.channel.item.forecast
        end
    end)
end
   

-- *********************************************************************
-- *********************************************************************
-- *********************************************************************

-- jede Stunde Wettervorhersage von Yahoo holen
get_weather_forecast()
tmr.alarm(1, 360000, 1, function() get_weather_forecast() end)

-- I2C-OLED initialisieren
init_i2c_display()

-- alle 5s Tag der Wettervorhersage "durchschalten" und entsprechend anzeigen
display_forecast()
tmr.alarm(2, 5000, 1, function() display_forecast() end)
