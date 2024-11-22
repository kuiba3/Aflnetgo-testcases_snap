pid=$(ps -ef|grep ./dcmqrscp | grep afl|grep -v timeout|awk '{print $2}')
while true
do
	kpid=$(ps -ef|grep ./dcmqrscp|grep -v $pid|grep -v timeout |awk '{print $2}')
	if [ -n '$kpid' ];then
	echo $kpid|xargs kill -9
	fi
	sleep 300
done