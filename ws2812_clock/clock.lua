-- *********************************************************************
--
--                      ws2812-Clock
--                    =================
--                    Uwe Berger; 2018
--
-- Darstellung einer Uhr auf einem Ring mit 60 WS2812-LEDs. Die anzuzei-
-- gende Uhrzeit wird von einem NTP-Server im Netz ermittelt und jede 
-- Stunde synchronisiert.
--
-- ...Quelltext lesen!
--
-- ---------
-- Have fun!
--
-- *********************************************************************

ntp_server      = "de.pool.ntp.org"		-- NTP-Server
tz_offset       = 1                     -- Stundenoffset der Zeitzone
with_summertime = true                  -- Sommerzeit beachten?

-- via GPIO 0 wird ein Impulssignal eingespeist. Erst wenn dessen
-- Frequenz einen definierten Wert (ldr_limit) uebersteigt, werden
-- die LEDs auch tatsaechlich angesteuert. In meinem Fall verwende
-- ich diese Geschichte zum Dunkelschalten der LEDs bei Dunkelheit.
ldr_pin 		= 3		-- Pin, ueber den Impulssignal eingespeist wird
counter			= 0		-- Zwischenvariable zum Impulszaehlen
ldr_value		= 0		-- enthaelt den letzten ermittelten Wert
ldr_limit       = 27	-- Wert ausprobieren...
-- Theoretisch koennte man auch, in Abhaengigkeit der Frequenz des
-- Impulssignals, die Helligkeit WS2812-LEDs steuern...


-- **********************************************************************
-- Sommerzeit?
-- Quelle: https://github.com/maciejmiklas/NodeMCUUtils/blob/master/dateformatEurope.lua
-- ts --> UTC-Zeit (...aus rtctime.get())
function is_summertime(ts)
	if ts.mon < 3 or ts.mon > 10 then 
		return false 
	end
	if ts.mon > 3 and ts.mon < 10 then 
		return true 
	end
	local prev_sunday = ts.day - ts.wday
	if ts.mon == 3 then
		if ts.day >= 25 and ts.wday == 1 and ts.hour == 0 then 
			return false 
		end
		return prev_sunday > 23
	end
	if ts.mon == 10 then
		if ts.day >= 25 and ts.wday == 1 and ts.hour == 0 then 
			return true 
		end
		return prev_sunday < 24
	end
end

-- *********************************************************************
-- UNIX-Sekunde in lokale Zeit umrechnen 
function get_local_time(tz_offset, dst)
	-- UTC
	local utc = rtctime.get()
    local tm  = rtctime.epoch2cal(utc)
    -- Sommerzeit?
    if dst == true and is_summertime(tm) then
    	utc = utc + 3600
    end
    -- Zeitzone noch einrechnen
    tm = rtctime.epoch2cal(utc + tz_offset * 3600)
	return tm.sec, tm.min, tm.hour, tm.day, tm.mon, tm.year
end

-- **********************************************************************
-- momentane UNIX-Sekunde von einem NTP-Server holen und RTC setzen
function read_ntp()
    net.dns.resolve(ntp_server, 
    				function(sk, ip)
	    				if (ip == nil) then 
    						print("DNS failed!") 
							-- nach 5 Sekunden naechster Versuch...
							tmr.alarm(1, 5000, 1, function() read_ntp() end)
					   	else
        					sntp.sync(ip,
            					function(sec,usec,server)
                					print('sync', sec, usec, server)
                					rtctime.set(sec, usec)
                					-- LED-Animation (Timer 5) stoppen
                					tmr.unregister(5)
                					-- in einer Stunde Uhrzeit synchronisieren
                					tmr.alarm(1, 3600000, 1, function() read_ntp() end)
            					end,
            					function()
               						print('NTP sync failed!')
               						-- nach 5 Sekunden naechster Versuch...
               						tmr.alarm(1, 5000, 1, function() read_ntp() end)
            					end)
        				end
    				end) 
end

-- *********************************************************************
function display_now()
	local s, m, h = get_local_time(tz_offset, with_summertime)
	-- alle LEDs (Buffer) loeschen
	buffer:fill(0, 0, 0)
	-- nur wenn hell genug, dann auch LEDs (Buffer) neu setzen
	if ldr_value >= ldr_limit then 
		-- 5min-Raster setzen
		for i=1, 60, 5 do
			buffer:set(i, 1, 0, 0)
		end	
		-- Sekunde setzen
		local g, r, b = buffer:get(transform(s))
		buffer:set(transform(s), 32,  r,  b)
		-- Minute setzen
		g, r, b = buffer:get(transform(m))
		buffer:set(transform(m),  g, r, 32)
		-- Stunde setzen
		if h >= 12 then h = (h-12) end
		local h = h*5 + m/12	
		g, r, b = buffer:get(transform(h))
		buffer:set(transform(h),  g,  32, b)
	end 
	-- und (Buffer) rausschreiben	
	ws2812.write(buffer) 
end


-- *********************************************************************
-- zu setzende LEDs auf vorhandene Hardware umrechnen
function transform(v)
	-- bei mir ist der Ring um 180 Grad gedreht, damit die Anschluesse 
	-- unten (bei 06:00 Uhr) sind...
	if v < 30 then v=v+31 else v=v-29 end
	return v
end

-- *********************************************************************
-- *********************************************************************
-- *********************************************************************

-- Initialisierung LED-Strip
ws2812.init(ws2812.MODE_SINGLE)

-- einen entsprechenden Buffer fuer LED-Strip reservieren
buffer = ws2812.newBuffer(60, 3) 

-- eine kleine Animation starten, bis es eine aktuelle Uhrzeit gibt
i = 0
buffer:fill(0, 0, 0)
ws2812.write(buffer)
tmr.alarm(5, 10, 1,	function()
							i = i + 1
							buffer:fade(2)
							buffer:set(i % buffer:size() + 1, 0, 255, 0)
							ws2812.write(buffer)
						end)

-- Pin als Eingang
gpio.mode(ldr_pin, gpio.INPUT)
-- bei steigender Flanke counter inkrementieren
gpio.trig(ldr_pin, "down", 
	function()
		counter=counter+1
	end)

-- alle 100ms counter-Wert uebernehmen und zuruecksetzen
tmr.alarm(3, 100, 1, 
	function()
		ldr_value= counter
		counter=0
	end)

-- aktuelle Zeit von einem ntp-Server holen und jede Stunde aktualisieren
read_ntp()

-- Uhr aktualisieren und jede Sekunde dito...
display_now()
tmr.alarm(2, 1000, 1, function()
	-- print(ldr_value) 	-- Testausgabe aktuelle Impulsanzahl
	display_now()
end)

