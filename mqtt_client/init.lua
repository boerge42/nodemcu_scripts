ssid       = "xxx"
pwd        = "yyy"
--sec_dns    = "10.1.1.1"
--node_ip    = "10.1.1.45"
--node_nm    = "255.255.255.0"
--node_gw    = "10.1.1.1"
node_hostname = "esp8266-"..node.chipid()

print("Connecting to wifi...")
wifi.setmode(wifi.STATION)
wifi.sta.config(ssid, pwd)
--wifi.sta.setip({ip = node_ip, netmask = node_nm, gateway = node_gw})
wifi.sta.sethostname(node_hostname)
wifi.sta.connect()

tmr.alarm(0, 1000, 1, function()
    print(wifi.sta.status()) 
    ip = wifi.sta.getip()
    if ( ( ip ~= nil ) and  ( ip ~= "0.0.0.0" ) and (wifi.sta.status() == 5))then
        print("IP/Name: "..ip.." / "..wifi.sta.gethostname())
        tmr.stop(0)
        --net.dns.setdnsserver(sec_dns, 1)
		dofile("dht2mqtt.lua")
    end
end )


