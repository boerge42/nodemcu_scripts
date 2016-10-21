# nodemcu-Script-Sammlung
(Uwe Berger, 2016)

Hier sind einige Lua-Scripts für 
[ESP8266-Wifi-Module](https://www.mikrocontroller.net/articles/ESP8266) 
zu finden, auf denen die [NodeMCU-Firmware](https://github.com/nodemcu/nodemcu-firmware) installiert
wurde...:


## dht11_ntp_http
- stuendlich aktuelle Zeit von einem NTP-Server holen
- minuetlich einen DHT11 auslesen
- Bereitstellung eines HTTP-Severs auf Port 80, welcher
  Temperatur, Luftfeuchtigkeit und Datum/Uhrzeit zurueckgibt

## dht_telnet
- alle 10s einen angeschlossenen DHTxx-Sensor auslesen
- via Port 8266 (;-)) einen Telnet-Server bereitstellen, welcher
  Status|Temperatur|Feuchtigkeit
  sendet und dann die Verbindung beendet

## oled_ntp_clock
- stuendlich aktuelle Zeit von einem NTP-Server holen
- jede Sekunde Datum/Zeit auf einem OLED ausgeben

## oled_ntp_clock_analog
- oled_ntp_clock dito, nur zusätzlich mit analogen Ziffenblatt...

## weather_client
Kommuniziert zyklisch mit einem Server (hier mein Wetter-Server;
siehe beispielhaft enthaltenes Tcl-Script...;-)...) 
und gibt die empfangenen Daten auf einem OLED aus.

## weather_clock
Eine Kombination aus:
- oled_ntp_clock_analog
- weather_forecast (zusaetzlich wird auch das aktuelle Wetter ausgewertet)
- dht_telnet
Die Umschaltung zwischen den Betriebsarten erfolgt ueber zwei Taste. Spaetestens
hier wird ein ESP8266-Modul mit mindestens 5 frei verfuegbaren I/O-Pins zur 
Verfuegung stellt.

## weather_forecast
Wettervorhersage jede Stunde fuer woeid=xxx von Yahoo (im JSON-Format)
holen und entsprechend auf einem OLED (128x64) anzeigen --> Anzeige 
automatisch alle 5s tageweise rollierend

## wifi_scanner
- alle 3 Sekunden WLAN nach APs scannen und entsprechende Informationen
  zu den gefundenen APs ausgeben
  
  
---------  
Have fun!
