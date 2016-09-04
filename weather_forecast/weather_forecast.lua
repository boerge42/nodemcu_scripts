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
function display_forecast()
    if f ~= nil then
            -- Bilddaten laden
            print(f[idx].code)
            if file.open(""..f[idx].code..".mono", "r") == nil then
                file.open("na.mono", "r")
            end
            xbm_data = file.read()
            file.close()
            disp:firstPage()
            repeat
                disp:drawXBM(0, 0, 48, 48, xbm_data)
                disp:setFont(u8g.font_9x15)
                disp:drawStr(50, 10, ""..f[idx].day.."")
                disp:setFont(u8g.font_6x10)
                disp:drawStr(50, 20, ""..f[idx].date.."")
                disp:setFont(u8g.font_9x15)
                disp:drawStr(50, 36, ""..f[idx].low.."/"..f[idx].high.." C")
                disp:setFont(u8g.font_6x10)
                -- Text eventuell wortweise auf mehrere Zeilen verteilen
                --disp:drawStr(x, y, ""..idx.."")
                x, y= 50, 49
                for s in string.gmatch(f[idx].text, "%a+") do
                    if (x+string.len(s)*6) > 128 then x, y= 50, y+10 end
                    disp:drawStr(x, y, ""..s.."")
                    --y=y+10
                    x=x+(string.len(s)*6)+6
                end
                -- Tagesposition in der Vorhersage anzeigen
                local dx = 128/#f
                x, y = dx/2, 63
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
