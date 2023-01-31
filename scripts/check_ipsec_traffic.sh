IPSECBIN="/usr/local/sbin/ipsec"

if [ $# -eq 0 ]; then
	echo "Missing arguments"
	exit $STATE_UNKNOWN
fi

test -e $IPSECBIN

if [ $? -ne 0 ]; then
	echo "$IPSECBIN does not exist"
	exit $STATE_CRITICAL
else
	STRONG=`$IPSECBIN --version | grep strongSwan | wc -l`
fi

getTraffic() {
	CONN="$1"_
	METRIC="$2"

	if [ "$STRONG" -eq "1" ]; then
		ipsec status | grep -e "$CONN" > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			ipsec statusall | grep -e "$CONN" | grep -e "bytes" | grep -e "pkts" > /dev/null 2>&1
			if [ $? -eq 0 ]; then
				case $METRIC in
					bytesIn)
						bytesIn=$(ipsec statusall | grep -e "$CONN" | grep bytes_i | awk -F" " '{print $3}' | awk '{SUM += $1} END {print SUM}')
						echo $bytesIn
						;;
					bytesOut)
						bytesOut=$(ipsec statusall | grep -e "$CONN" | grep bytes_i | awk -F" " '{print $9}' | awk '{SUM += $1} END {print SUM}')
						echo $bytesOut
						;;
					pktsIn)
						pktsIn=$(ipsec statusall | grep -e "$CONN" | grep bytes_i | awk -F" " '{print $5}' | cut -c 2- | awk '{SUM += $1} END {print SUM}')
						echo $pktsIn
						;;
					pktsOut)
						pktsOut=$(ipsec statusall | grep -e "$CONN" | grep bytes_i | awk -F" " '{print $11}' | cut -c 2- | awk '{SUM += $1} END {print SUM}')
						echo $pktsOut
						;;
					*)
						echo "Parameter $METRIC is not allowed"
				esac
				return 0
			else
				echo 0
			fi
		else
			echo 0
		fi
	fi
	return 1
}

getTraffic $1 $2
