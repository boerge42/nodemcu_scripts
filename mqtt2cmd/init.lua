dofile("wlan_config.lua")

node_hostname = "esp8266-"..node.chipid()

print("Connecting to wifi...")
wifi.setmode(wifi.STATION)
wifi.sta.config(station_cfg)
wifi.sta.sethostname(node_hostname)
wifi.sta.connect()

tmr.alarm(0, 1000, 1, function()
    print(wifi.sta.status()) 
    ip = wifi.sta.getip()
    if ( ( ip ~= nil ) and  ( ip ~= "0.0.0.0" ) and (wifi.sta.status() == 5))then
        print("IP/Name: "..ip.." / "..wifi.sta.gethostname())
        tmr.stop(0)
		dofile("mqtt2cmd_test.lua")
    end
end )


