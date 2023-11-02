IPV4_REGEX="(([0-9][0-9]?|[0-1][0-9][0-9]|[2][0-4][0-9]|[2][5][0-5])\.){3}([0-9][0-9]?|[0-1][0-9][0-9]|[2][0-4][0-9]|[2][5][0-5])"
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

test_tunnel() {
	CONN="$1"_
	CONNALT="$1"{

	if [ "$STRONG" -eq "1" ]; then
		ipsec status | grep -e "$CONN" -e "$CONNALT" > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			ipsec statusall | grep -e "$CONN" -e "$CONNALT" | grep -i "rekeying" > /dev/null 2>&1
			if [ $? -eq 0 ]; then
				ipsec statusall | grep -e "$CONN" -e "$CONNALT" | grep -v "rekeying" | grep -E "$IPV4_REGEX" > /dev/null 2>&1
				if [ $? -eq 0 ]; then
					return 0
				fi
			fi
		fi
	fi
	return 1
}

test_tunnel $1
echo $?
