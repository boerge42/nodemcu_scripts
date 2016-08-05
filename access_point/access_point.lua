-----------------------------------------------

-- AP-Konfiguration selbst
AP_CFG={}
AP_CFG.ssid="esp8266"
AP_CFG.pwd="espespesp"
AP_CFG.auth=AUTH_OPEN
AP_CFG.channel = 6
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

-- Access Point
wifi.ap.config(AP_CFG)
wifi.ap.setip(AP_IP_CFG)

-- DHCP
wifi.ap.dhcp.config(AP_DHCP_CFG)
wifi.ap.dhcp.start()
---------------------------------------

---------------------------------------
-- HTTP-Server
---------------------------------------
srv=net.createServer(net.TCP) 
srv:listen(80,function(conn) 
    conn:on("receive",function(conn,request) 
        --print(request)
        local buf=""
        buf=buf.."<h1>Hallo Uwe!</h1>"
        conn:send(buf)
        conn:close()
        end) 
end)
