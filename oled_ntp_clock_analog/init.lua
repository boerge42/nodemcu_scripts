ssid       = "xxx"
pwd        = "yyy"
sec_dns    = "10.1.1.1"
node_ip    = "10.1.1.43"
node_nm    = "255.255.255.0"
node_gw    = "10.1.1.1"

print("Connecting to wifi...")
wifi.setmode(wifi.STATION)
wifi.sta.config(ssid, pwd)
wifi.sta.setip({ip = node_ip, netmask = node_nm, gateway = node_gw})
wifi.sta.connect()

tmr.alarm(0, 1000, 1, function()
    print(".") 
    ip = wifi.sta.getip()
    if ( ( ip ~= nil ) and  ( ip ~= "0.0.0.0" ) )then
        print(ip)
        tmr.stop(0)
        net.dns.setdnsserver(sec_dns, 1)
		dofile("ntp_clock.lua")
    end
end )


