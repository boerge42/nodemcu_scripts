# nodemcu-Script-Sammlung
(Uwe Berger, 2016)

Hier sind einige Lua-Scripts für 
[ESP8266-Wifi-Module](https://www.mikrocontroller.net/articles/ESP8266) 
zu finden, auf denen die [NodeMCU-Firmware](http://nodemcu.com) installiert
wurde.


## dht11_ntp_http
- stuendlich aktuelle Zeit von einem NTP-Server holen
- minuetlich einen DHT11 auslesen
- Bereitstellung eines HTTP-Severs auf Port 80, welcher
  Temperatur, Luftfeuchtigkeit und Datum/Uhrzeit zurueckgibt


## oled_ntp_clock
- stuendlich aktuelle Zeit von einem NTP-Server holen
- jede Sekunde Datum/Zeit auf einem OLED ausgeben


## weather_client
Kommuniziert zyklisch mit einem Server (hier mein Wetter-Server;
siehe beispielhaft enthaltenes Tcl-Script...;-)...) 
und gibt die empfangenen Daten auf einem OLED aus.


## wifi_scanner
- alle 3 Sekunden WLAN nach APs scannen und entsprechende Informationen
  zu den gefundenen APs ausgeben
  
  
  
Have fun!
