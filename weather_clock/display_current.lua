-- **********************************************************************
-- Lua-Modul: display_current.lua
-- ==============================
--         Uwe Berger; 2016
--
-- Interface:
-- ----------
--     display()
-- ...entspr. Parameter siehe weiteren Quelltext...
--
--
-- ---------
-- Have fun!
--
-- **********************************************************************

local M = {}

-- **********************************************************************
function f2c(f)
	return ((f-32)*50+5)/90
end

-- **********************************************************************
function m2km(m)
	return ((m*161)+50)/100
end

-- **********************************************************************
function split(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t={} ; i=1
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		t[i] = str
		i = i + 1
	end
	return t
end

-- **********************************************************************
function str2int(s)
	n=split(s, ".")
	return (n[1]*10+(n[2]+5))/10
end

-- **********************************************************************
function M.display(d)
    if d.lo.con.code ~= nil then
    	local xbm_data
		if (d.lo.idx==1) then
		    -- Bilddaten laden
            if file.open(""..d.lo.con.code..".mono", "r") == nil then
        	    file.open("na.mono", "r")
            end
            xbm_data = file.read()
            file.close()
        end
        -- Bildschirm ausgeben
        disp:firstPage()
        repeat
		   if (d.lo.idx==1) then
			  disp:drawXBM(0, 0, 48, 48, xbm_data)
              disp:setFont(u8g.font_6x10)
              disp:drawStr(50, 10, "condition...")
		      disp:setFont(u8g.font_10x20)
              disp:drawStr(70, 32, ""..f2c(d.lo.con.temp)..string.char(0xB0).."C")
              disp:setFont(u8g.font_6x10)
              -- Text eventuell wortweise auf mehrere Zeilen verteilen
              local x, y= 50, 49
              for s in string.gmatch(d.lo.con.text, "%a+") do
                  if (x+string.len(s)*6) > 128 then x, y= 50, y+10 end
                  disp:drawStr(x, y, ""..s.."")
                  x=x+(string.len(s)*6)+6
              end
           elseif (d.lo.idx==2) then
              disp:setFont(u8g.font_6x10)
              disp:drawStr(0, 10, "atmosphere...")
              disp:drawStr(0, 25, "humid.:")
              disp:drawStr(0, 40, "press.:")
              disp:drawStr(0, 55, "visib.:")
              disp:setFont(u8g.font_9x15)
              disp:drawStr(55, 25, d.lo.atm.humidity.."%")
              local rising
              if (d.lo.atm.rising==0) then
                  rising=string.char(0xAB)
              else 
                  rising=string.char(0XBB)
              end
              disp:drawStr(55, 40, str2int(d.lo.atm.pressure).."hPa"..rising)
              disp:drawStr(55, 55, m2km(str2int(d.lo.atm.visibility)).."km")
           elseif (d.lo.idx==3) then
              disp:setFont(u8g.font_6x10)
              disp:drawStr(0, 10, "wind...")
              disp:drawStr(0, 25, "chill  :")
              disp:drawStr(0, 40, "direct.:")
              disp:drawStr(0, 55, "speed  :")
              disp:setFont(u8g.font_9x15)
              disp:drawStr(55, 25, f2c(d.lo.wind.chill)..string.char(0xB0).."C")
              disp:drawStr(55, 40, d.lo.wind.direction..string.char(0xB0))
              disp:drawStr(55, 55, m2km(d.lo.wind.speed).."km/h")
           elseif (d.lo.idx==4) then
              disp:setFont(u8g.font_6x10)
              disp:drawStr(0, 10, "astronomy...")
              disp:drawStr(0, 25, "sunrise:")
              disp:drawStr(0, 40, "sunset :")
              disp:setFont(u8g.font_9x15)
              disp:drawStr(55, 25, d.lo.astro.sunrise)
              disp:drawStr(55, 40, d.lo.astro.sunset)
           end
           -- Bildschirmzaehler unten anzeigen
           local dx = 128/4
           x, y = dx/2, 63
           for i=1, 4, 1 do
               if i == d.lo.idx then
                   disp:drawHLine(x-2, y, 5)
               else 
                   disp:drawHLine(x, y, 1)
               end
               x=x+dx
           end
            
        until disp:nextPage() == false
    else    
        disp:firstPage()
        repeat
			disp:setFont(u8g.font_9x15)
            disp:drawStr(10, 30, "No data!")        
        until disp:nextPage() == false
    end
    xbm_data=nil
    collectgarbage()
end


return M
