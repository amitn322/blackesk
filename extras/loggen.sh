#!/binb/bash
if [ -z $1 ];then
   count=2
   echo "Sending One Log message, to send more run with argument"
   echo "Example: $0 10"
else
   count=$1
fi


for i in $(seq 1 2 ${count});do

	randomPort=$(( $RANDOM % 65535 + 2000 ))
	randomUser=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 13 `
	randomIP=$(dd if=/dev/urandom bs=4 count=1 2>/dev/null |od -An -tu1 | sed -e 's/^ *//' -e 's/  */./g')
	echo "Accepted password for ${randomUser} from ${randomIP} port ${randomPort} ssh2" > /tmp/ssh_logs.txt
	logger -t sshd -f /tmp/ssh_logs.txt 
done
echo $count Logs generated