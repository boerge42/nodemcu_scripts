#
#  telnet_client.tcl
# ====================
#   Uwe Berger; 2016
#
#
# ---------
# Have fun!
#

set host_list {
				10.1.1.44
			  }
	
set port	8266
set cycle	60000

# ******************************************************
proc read_server {h p} {
	set chan [socket $h $p]
	return [gets $chan]
}

# ******************************************************
proc work {} {
	global host_list port cycle
	foreach host $host_list {
		puts "$host: [read_server $host $port]"
	}
	after $cycle {work}
}

# ******************************************************
# ******************************************************
# ******************************************************
work

vwait forever
