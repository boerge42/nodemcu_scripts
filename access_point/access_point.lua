
-- AP-Konfiguration selbst
AP_CFG={}
AP_CFG.ssid="esp8266"
AP_CFG.pwd="espespesp"
AP_CFG.auth=AUTH_OPEN
AP_CFG.channel = 1
AP_CFG.hidden = 0
AP_CFG.max=4
AP_CFG.beacon=100

--  AP IP-Konfiguration 
AP_IP_CFG={}
AP_IP_CFG.ip="10.1.2.1"
AP_IP_CFG.netmask="255.255.255.0"
AP_IP_CFG.gateway="10.1.2.1"

-- DHCP-Server-Konfiguration
AP_DHCP_CFG ={}
AP_DHCP_CFG.start = "10.1.2.2"
---------------------------------------

print("MAC:"..wifi.ap.getmac())
print("setmode:"..wifi.setmode(wifi.SOFTAP))

-- Access Point
print("AP...")
print(wifi.ap.config(AP_CFG))
print(wifi.ap.setip(AP_IP_CFG))

-- DHCP
print("DHCP...")
print("dhcp.config:"..wifi.ap.dhcp.config(AP_DHCP_CFG))
print(wifi.ap.dhcp.start())

---------------------------------------
tmr.alarm(0,3000,1,function()
					print("Hallo...")
					for mac,ip in pairs(wifi.ap.getclient()) do
    					print(mac,ip)
					end
				end)

