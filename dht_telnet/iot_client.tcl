#
#    iot_client.tcl
#   ================
#   Uwe Berger; 2016
#
# dht_iot:
# --------
# ts=1469561211|stat=0|temp=27.9|hum=30.6
#
# ---------
# Have fun!
#
package require sqlite3

set db_name iot.sqlite

#
# SQL-Tabellen (Spaltenname Type)
#
set tab(dht_iot) {
			name text
	 		ts integer
	 		stat integer
	 		temp real
	 		hum real
}

set tab(dummy) {
			col1 text
}

#
# Host-Liste (Name IP-Adresse Port Tabelle)
#
set host_list {
				dht_44 10.1.1.44 8266 dht_iot
				dht_45 10.1.1.45 8266 dummy
			  }

# ******************************************************
proc var_list {s} {
	set r {}
	foreach v [split $s |] {
		set r [linsert $r end [split $v =]]
	}
	return $r
}

# ******************************************************
proc get_val {l k} {
	return [lindex [lsearch -index 0 -inline -exact $l $k] 1]
}

# ******************************************************
proc work {l} {
	global tab
	# create table zusammenbauen und absetzen
	set c ""
	set sql "create table if not exists [get_val $l tab] ("
	foreach {col type} $tab([get_val $l tab]) {
		set sql "$sql$c $col $type"
		set c ","
	}
	set sql "$sql)"
	db eval $sql
	# insert into zusammenbauen und absetzen
	set c ""
	set sql "insert into [get_val $l tab] values ("
	foreach {col type} $tab([get_val $l tab]) {
		if {$type == "text"} {set a "'"} else {set a ""}
		set sql "$sql$c$a[get_val $l $col]$a"
		set c ","	
	}
	set sql "$sql)"
	db eval $sql
}

# ******************************************************
# ******************************************************
# ******************************************************

sqlite3 db $db_name

# Host-Liste abarbeiten
foreach {name host port table} $host_list {
	if {[catch {set result [gets [socket $host $port]]}]} {
		puts "Error by $host $port"	
	} else {
		work [var_list "name=$name|$result|tab=$table"]
	}
}

db close
