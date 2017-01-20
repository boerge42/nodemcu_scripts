-- **********************************************************************
-- Lua-Modul: display_clock.lua
-- ============================
--       Uwe Berger; 2016
--
-- Interface:
-- ----------
--     display() --> Darstellung einer analogen und digitalen Uhr
-- ...entspr. Parameter siehe weiteren Quelltext...
--
--
-- ---------
-- Have fun!
--
-- **********************************************************************

local M = {}

-- Sinustabelle fuer 0., 1., 2., ..., 15.Minute mit Skalierungsfaktor=1024
local sin_tab_factor = 1024
local sin_tab = {0,107,213,316,416,512,602,685,761,828,887,935,974,1002,1018,1024}

local tz         = 1         -- Offset Zeitzone
local dst        = true      -- mit Sommerzeit ja/nein --> true/false

-- **********************************************************************
local function clock2sin(v)
	if ((v==0) or (v==60))  then return 0 end
	if  (v<=15)             then return (sin_tab[v+1]) end
	if ((v>15) and (v<=30)) then return sin_tab[30 - v+1] end
	if ((v>30) and (v<=45)) then return (-1) * sin_tab[v+1 - 30] end
	if ((v>45) and (v<60))  then return (-1) * sin_tab[60 - v+1] end
	return 0
end

-- **********************************************************************
local function clock2cos(v)
	if ((v==0) or (v==60))  then return sin_tab_factor end
	if  (v<=15)             then return (sin_tab[15 - v+1]) end
	if ((v>15) and (v<=30))	then return (-1) * sin_tab[v+1 - 15] end
	if ((v>30) and (v<=45))	then return (-1) * sin_tab[45 - v+1] end
	if ((v>45) and (v<60))	then return sin_tab[v+1 - 45] end
	return sin_tab_factor;
end


-- **********************************************************************
-- x_mp, y_mp  --> Koordinaten Mittelpunkt des Ziffernblattes
-- r           --> Radius des Ziffernblattes
-- v           --> (Minuten-)Wert
-- Returnwerte --> x-, y-Koordinate des gesuchten Punktes
local function clock_face_point(x_mp, y_mp, r, v)
	local x = x_mp + r*clock2sin(v)/sin_tab_factor
	local y = y_mp - r*clock2cos(v)/sin_tab_factor
	return x, y
end

-- **********************************************************************
-- berechnet die Koordinaten eines dreieckigen Zeigers
-- --> x_mp, y_mp: Mittelpunkt (Ursprung) des Zeigers
-- --> 2 * r0 = Dicke des Zeigers im Ursprung des Ziffernblattes
-- --> Laenge des Zeigers
-- --> (Minuten-)Wert des Zeigers
-- Return: xy-Paar der Dreieckskoordinaten
local function clock_fat_hand(x_mp, y_mp, r0, r, v)
	local v0 = v - 15
	if v0 < 0 then v0 = v + 45 end
	local v1 = v + 15 
	if v > 60 then v1 = v - 45 end
	local x0, y0 = clock_face_point(x_mp, y_mp, r0, v0)
	local x1, y1 = clock_face_point(x_mp, y_mp, r, v)
	local x2, y2 = clock_face_point(x_mp, y_mp, r0, v1)
	return x0, y0, x1, y1, x2, y2
end

-- **********************************************************************
-- UNIX-Sekunden in Stunde, Minute, Sekunde, Tag, ... umrechnen 
-- Parameter tz_offset --> Zeitzone in Stunden
-- Parameter with_dst --> true/false --> mit/ohne Sommerzeit
local function unix2datetime(t, tz_offset, with_dst)
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
        if (wt > 7) then wt = 1 end
        if (day == DayOfMonth[m]) then
            d = 0;
            m = m + 1
        end
        d = d + 1
    end
    return hour, minute, second, y, m, d, wt
end

-- **********************************************************************
function M.display(d)
	local wt_names = {"Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"}
    local dt_h, dt_m, dt_s, dt_y, dt_mo, dt_d, dt_wt = unix2datetime(rtctime.get(), tz, dst)
    local date_str = string.format("%02d.%02d.%04d", dt_d, dt_mo, dt_y)
    local time_str = string.format("%02d:%02d", dt_h, dt_m)
    local wt_str   = string.format("%s", wt_names[dt_wt])
	local std = dt_h
	if std >= 12 then std = (std-12) end
	std=std*5 + dt_m/12
	--Ausgabe auf OLED
    disp:firstPage()
	repeat
		-- Datum/Uhrzeit digital...
		disp:setFont(u8g.font_10x20)
		disp:drawStr(127-string.len(time_str)*10, 15, time_str)
		disp:setFont(u8g.font_6x10)
		disp:drawStr(127-string.len(wt_str)*6, 50, wt_str)
		disp:drawStr(127-string.len(date_str)*6, 63, date_str)
		-- ... Uhrzeit analog
		-- Ziffernblatt...
		local x0 = 31
		local y0 = 31
		-- Ziffenblatt (5min-Punkte) erzeugen
		for i=0, 59, 5 do
			disp:drawPixel(clock_face_point(x0,y0,30,i))
		end
		-- Sekundenzeiger
		disp:drawLine(x0, y0, clock_face_point(x0,y0,28,dt_s))
		-- Minutenzeiger
		disp:drawTriangle(clock_fat_hand(x0,y0,3,28,dt_m))
		-- Stundenzeiger
		disp:drawTriangle(clock_fat_hand(x0,y0,3,18,std))
	until disp:nextPage() == false
end

return M
