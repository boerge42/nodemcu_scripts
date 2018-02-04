# nodemcu-Script-Sammlung
(Uwe Berger; 2016, 2017, 2018)

Hier sind einige (beispielhafte) Lua-Scripts für 
[ESP8266-Wifi-Module](http://bralug.de/wiki/ESP8266_mit_NodeMcu) 
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
Eine Uhr:
- stuendlich aktuelle Zeit von einem NTP-Server holen
- jede Sekunde Datum/Zeit auf einem OLED ausgeben

## oled_ntp_clock_analog
Wie oled_ntp_clock, nur zusätzlich mit analogen Ziffenblatt...

## weather_client
Kommuniziert zyklisch mit einem Server (hier mein Wetter-Server;
siehe beispielhaft enthaltenes Tcl-Script...;-)...) 
und gibt die empfangenen Daten auf einem OLED aus.

## weather_clock
Eine Kombination aus:
- oled_ntp_clock_analog
- weather_forecast (zusaetzlich wird auch das aktuelle Wetter ausgewertet)
- dht_telnet

Die Umschaltung zwischen den Betriebsarten/-anzeigen erfolgt ueber zwei Taster. Spaetestens
hier wird ein ESP8266-Modul, welches mindestens 5 frei verfuegbare I/O-Pins zur 
Verfuegung stellt (also z.B. ein ESP8266-12x), erforderlich!

## weather_clock_my_server
Eine Kombination aus:
- oled_ntp_clock_analog
- weather_forecast
- weather_client
- dht_telnet

Die Umschaltung zwischen den Betriebsarten/-anzeigen erfolgt ueber zwei Taster. Auch 
hier wird ein ESP8266-Modul, welches mindestens 5 frei verfuegbare I/O-Pins zur 
Verfuegung stellt (also z.B. ein ESP8266-12x), erforderlich! 
Ansonsten RTFM und/oder den Quell-Code ansehen und verstehen!

## weather_forecast
Wettervorhersage jede Stunde fuer woeid=xxx von Yahoo (im JSON-Format)
holen und entsprechend auf einem OLED (128x64) anzeigen --> Anzeige 
automatisch alle 5s tageweise rollierend

## wifi_scanner
Alle 3 Sekunden WLAN nach APs scannen und entsprechende Informationen zu 
den gefundenen APs ausgeben
  
## access_point
ESP8266-Module als Accesspoint.
  
## mqtt_client
Analog dht_telnet. Zusaetzlich werden die Werte zu einem MQTT-Broker
publiziert.

## bme280mqtt
Analog mqtt_client, nur:
- mit einem BME280 als Sensor
- MQTT-Topic: nodename/cmd    --> als Lua-Kommando-Eingabe
- MQTT-Topic: nodename/output --> als (Lua-Interpreter-)Ausgabe

## mqtt2oled
Aehnlich weather_clock_my_server, allerdings werden (fast) alle anzuzeigenden
Daten via MQTT empfangen.
  
## mqtt2cmd
Kommandozeile via MQTT-Protokoll

## ws2812_clock
Darstellung einer Uhr auf einem Ring mit 60 WS2812-LEDs.

---------  
Have fun!
