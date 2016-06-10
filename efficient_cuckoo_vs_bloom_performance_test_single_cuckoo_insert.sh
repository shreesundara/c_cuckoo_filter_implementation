#!/usr/bin/bash
clear
reset

getCmdOutput(){
	echo "Executing command is : $@"
	cmd_exec_output=$(eval $@) #bloom filter hash fns cou$
	echo "Command exec output is : $cmd_exec_output";
	if [ $cmd_exec_output != "OK" ] && [  $cmd_exec_output != "1" ]
	then
        	#read -p "Press any key to continue"
	        echo "Problem executing command, May be the redis-server is not running."
        	exit;
	fi
}

echo "***************************************************"
echo "The configuration on which the test script is run is shown below";
sudo lshw #to print the system configuration.
echo " ";
startTime=$(echo `date`);
echo "NOTE : Make sure the Redis-server is running on port 123457..."

CUCKOO_INSERTION_EXEC_TIME_OUTPUT_FILE="efficient_single_cuckoo_insert_elem_timing.csv"
CUCKOO_ISMEMBER_EXEC_TIME_OUTPUT_FILE="efficient_single_cuckoo_check_elem_timing.csv"

CUCKOO_FILTERNAME="eff_single_cf"
CUCKOO_FILTERSIZE=536870800 #40*1024*1024. for 4GB it is 4294967296

NO_ELEMS_TO_INSERT=20971520;
NO_ELEMS_TO_CHECK=10485760;
LOG_AFTER_N_INSERTS=5;
LOG_AFTER_N_CHECKS=5;
AVG_AFTER_N_INSERTS=100000;
AVG_AFTER_N_CHECKS=100000;

REDIS_SERVER_PORT=9999;

echo "Removing cuckoo_timing files $CUCKOO_INSERTION_EXEC_TIME_OUTPUT_FILE and $CUCKOO_ISMEMBER_EXEC_TIME_OUTPUT_FILE"
rm $CUCKOO_INSERTION_EXEC_TIME_OUTPUT_FILE
rm $CUCKOO_ISMEMBER_EXEC_TIME_OUTPUT_FILE


echo "Creating cuckoo_timing files"
touch $CUCKOO_INSERTION_EXEC_TIME_OUTPUT_FILE
rm $CUCKOO_ISMEMBER_EXEC_TIME_OUTPUT_FILE


cmd_exec_output=0;
echo "Removing existing Cuckoo filter with name $CUCKOO_FILTERNAME"
#First remove the existing filter..
~/Desktop/Redis/redis/src/redis-cli -p $REDIS_SERVER_PORT del $CUCKOO_FILTERNAME

echo "Creating Cuckoo filter with name $CUCKOO_FILTERNAME and size $CUCKOO_FILTERSIZE"
getCmdOutput ~/Desktop/Redis/redis/src/redis-cli -p $REDIS_SERVER_PORT cuckoocreate $CUCKOO_FILTERNAME $CUCKOO_FILTERSIZE


#calculate time taken to insert 4-billion elements.
echo "Inserting elements into cuckoo.."
ELEM_INSERTION_COUNT=1;
VALUE=0;

echo "Initial test for insertion for cuckoo : "
getCmdOutput "~/Desktop/Redis/redis/src/redis-cli  -p $REDIS_SERVER_PORT cuckooinsertelement $CUCKOO_FILTERNAME $VALUE"

cuckoo_insert_time=0;
while [ $ELEM_INSERTION_COUNT -le $NO_ELEMS_TO_INSERT ] #524288 = 512KB
do
	if [ 0 == `expr $ELEM_INSERTION_COUNT % $LOG_AFTER_N_INSERTS` ]
	then
		echo "Completed inserting $ELEM_INSERTION_COUNT elements into cuckoo filter";
	fi
	VALUE=`expr $VALUE + 2`

        lastTime="$(TIMEFORMAT='%E';time (~/Desktop/Redis/redis/src/redis-cli  -p $REDIS_SERVER_PORT cuckooinsertelement $CUCKOO_FILTERNAME $VALUE) 2>&1 1>/dev/null )" ;
        cuckoo_insert_time=$(echo "scale=5;$cuckoo_insert_time+$lastTime" | bc);

	if [ 0 == `expr $ELEM_INSERTION_COUNT % $AVG_AFTER_N_INSERTS` ]
	then
	        time2=$(echo "scale=5;$cuckoo_insert_time/$ELEM_INSERTION_COUNT" | bc)
	        echo "$ELEM_INSERTION_COUNT,$time2" >> $CUCKOO_INSERTION_EXEC_TIME_OUTPUT_FILE
	fi
	ELEM_INSERTION_COUNT=`expr $ELEM_INSERTION_COUNT + 1`
done



#calculate time taken to check for existence of an element for say 100 or 1000 trials.
echo "Checking for element existence in cuckoo filters."
ELEM_CHECK_COUNT=1;
VALUE=0;


echo "Initial test for Element existence for cuckoo : "
getCmdOutput "~/Desktop/Redis/redis/src/redis-cli  -p $REDIS_SERVER_PORT cuckoocheckelement $CUCKOO_FILTERNAME $VALUE"


cuckoo_check_time=0;
while [ $ELEM_CHECK_COUNT -le $NO_ELEMS_TO_CHECK ]
do
        if [ 0 == `expr $ELEM_CHECK_COUNT % $LOG_AFTER_N_CHECKS` ]
        then
                echo "Completed checking $ELEM_CHECK_COUNT elements in cuckoo filter";
        fi
        VALUE=`expr $VALUE + 1`

        lastTime="$(TIMEFORMAT='%E';time (~/Desktop/Redis/redis/src/redis-cli -p $REDIS_SERVER_PORT  cuckoocheckelement $CUCKOO_FILTERNAME $VALUE) 2>&1 1>/dev/null )"
        cuckoo_check_time=$(echo "scale=5;$cuckoo_check_time+$lastTime" | bc);

        if [ 0 == `expr $ELEM_CHECK_COUNT % $AVG_AFTER_N_CHECKS` ]
        then
                time2=$(echo "scale=5;$cuckoo_check_time/$ELEM_CHECK_COUNT" | bc);
                echo "$ELEM_CHECK_COUNT,$time2" >> $CUCKOO_ISMEMBER_EXEC_TIME_OUTPUT_FILE
        fi
        ELEM_CHECK_COUNT=`expr $ELEM_CHECK_COUNT + 1`
done


echo "Deleting the cuckoo filter"
~/Desktop/Redis/redis/src/redis-cli -p $REDIS_SERVER_PORT  del $CUCKOO_FILTERNAME

endTime=$(echo `date`);
echo "Performance Simulated for $ELEM_INSERTION_COUNT single cuckoo-insertions is :";
echo "Script execution start time : $startTime";
echo "Script execution end time : $endTime";


echo "***************************************************"
