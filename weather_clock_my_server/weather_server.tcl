#
#    weather_server.tcl
#  ======================
#  Uwe Berger; 2016, 2017
#
# Server beantwortet folgende Anfragen (Strings), welche ueber das, 
# im Script, definierte Port "reinkommen":
#
# get_weather_current
# -------------------
# Was|Timestamp|Temperatur|Luftfeuchtigkeit|Luftdruck|Luftdrucktendenz
#
# Bsp.: 
# get_weather_current|05.02.2016, 23:38:49|5.7|humidity_out|1020.1|0
#
#
# get_weather_forecast_day index
# ------------------------------
# Was|Index|Wochentag|Datum|min.Temp|max.Temp|Code|Text
#
# Bsp.:
# get_weather_forecast_day|1|Mon|20.06.2016|10|21|30|Partly Cloudy
#
#
# get_weather_forecast_all
# ------------------------------
# Was|@|Wochentag|Datum|min.Temp|max.Temp|Code|Text|@|...
#
# Bsp.:
# get_weather_forecast_all|@|Mon|20.06.2016|10|21|30|Partly Cloudy|@|...
# 
#
# get_weather_all
# ------------------------------
# Was|@|Timestamp|Temperatur|Luftfeuchtigkeit|Luftdruck|Luftdrucktendenz|@|
# Wochentag|Datum|min.Temp|max.Temp|Code|Text|@|...
#
# Bsp.:
# get_weather_all|@|Mon|20.06.2016|10|21|30|Partly Cloudy|@|
# Mon|20.06.2016|10|21|30|Partly Cloudy|@|...
# 
# ---------
# Have fun!
#

set path /home/pi/public_html/temp
set weather_current_conf $path/weather_current.conf
set weather_forecast_conf $path/weather_forecast.conf
set port 12342

# *****************************************************************
proc get_current_weather {} {
	global weather_current_conf
	set timestamp 		0
	set temperature_out 0
	set humidity_out	0
	set pressure_rel	0
	set pressure_rising	0
	set fd [open $weather_current_conf r] 
	set data [read $fd [file size $weather_current_conf]]
	close $fd
	set data [split $data \n]
	foreach s $data {
		set s [split $s =]	
		set key [string trim [lindex $s 0]] 
		set value [string trim [string trim [lindex $s 1]] \"]
		if {[string first timestamp $key] > -1} 		{set timestamp $value}
		if {[string first temperature_out $key] > -1}	{set temperature_out $value}
		if {[string first humidity_out $key] > -1}		{set humidity_out $value}
		if {[string first pressure_rel $key] > -1}		{set pressure_rel $value}
		if {[string first pressure_rising $key] > -1}	{set pressure_rising $value}
	}
	#return "get_weather_current|$timestamp|$temperature_out|$humidity_out|$pressure_rel|$pressure_rising"
	return "$timestamp|$temperature_out|$humidity_out|$pressure_rel|$pressure_rising"
}

# *****************************************************************
proc get_weather_forecast {index} {
	global weather_forecast_conf
	set day			-
	set date		-
	set temp_low	-
	set temp_high	-
	set code		-
	set text		-
	set fd [open $weather_forecast_conf r] 
	set data [read $fd [file size $weather_forecast_conf]]
	close $fd
	set data [split $data \n]
	foreach s $data {
		set s [split $s =]	
		set key [string trim [lindex $s 0]] 
		set value [string trim [string trim [lindex $s 1]] \"]
		if {[string first forecast$index\_day $key] > -1}       {set day $value}
		if {[string first forecast$index\_date $key] > -1}      {set date $value}
		if {[string first forecast$index\_temp_low $key] > -1}  {set temp_low $value}
		if {[string first forecast$index\_temp_high $key] > -1} {set temp_high $value}
		if {[string first forecast$index\_code $key] > -1}      {set code $value}
		if {[string first forecast$index\_text $key] > -1}      {set text $value}
	}
	if {$day != "-"} {
		return "$day|$date|$temp_low|$temp_high|$code|$text"
	} else {
		return ""
	}
}

# *****************************************************************
proc get_weather_forecast_day {index} {
	return "get_weather_forecast_day|$index|[get_weather_forecast $index]"
}

# *****************************************************************
proc get_weather_current {} {
	return "get_weather_current|[get_current_weather]"
}

# *****************************************************************
proc get_weather_forecast_all {} {
	return "get_weather_forecast_all|@[get_all_forecast]"
}

# *****************************************************************
proc get_all_forecast {} {
	set result ""
	set index 0
	set day [get_weather_forecast $index]
	while {$day != ""} {
		set result "$result|$day|@"
		incr index
		set day [get_weather_forecast $index]
	}
	return $result
}

# *****************************************************************
proc get_weather_all {} {
	return "get_weather_all|@|[get_current_weather]|@[get_all_forecast]"
}


# *****************************************************************
proc accept {chan addr port} {
	global si
	set cmd [gets $chan]
	puts "rx: $cmd"
	if {[catch {puts $chan [$si eval $cmd]}]} {
		puts $chan "no!: $cmd"}
	flush $chan
	close $chan
}

# *****************************************************************
# *****************************************************************
# *****************************************************************

# sicheren Interpreter mit zulaessigen
# Kommandos definieren...
set si [interp create -safe] 
$si alias get_weather_current get_weather_current 
$si alias get_weather_forecast_day get_weather_forecast_day 
$si alias get_weather_forecast_all get_weather_forecast_all 
$si alias get_weather_all get_weather_all 
 
# Server-Socket definieren
socket -server accept $port

# "ewig" an dieser Stelle warten
vwait forever 
