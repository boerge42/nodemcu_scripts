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

f = nil
idx = 1


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
            if (string.len(f[idx].text)*9) < 128 then
                disp:drawStr(0, 52, ""..f[idx].text.."")
            else 
                local s = split_str(f[idx].text, " ")
                disp:drawStr(0, 52, ""..s[1].."")
                disp:drawStr(0, 62, ""..s[2].."") 
            end
        until disp:nextPage() == false
        idx = idx + 1
        if idx > 10 then idx = 1 end
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
            --for i=1, 10, 1 do
            --    for k,v in pairs(f[i]) do print(k,v) end
            --end
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
