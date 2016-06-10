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
echo "NOTE : Make sure the Redis-server is running on port 9998..."

BLOOM_INSERTION_EXEC_TIME_OUTPUT_FILE="efficient_bloom_single_insert_elem_timing.csv"
BLOOM_ISMEMBER_EXEC_TIME_OUTPUT_FILE="efficient_bloom_single_check_elem_timing.csv"

BLOOM_FILTERNAME="eff_single_bf"

BLOOM_FILTERSIZE=536870800 #40*1024*1024
BLOOM_HASH_FNS=20

NO_ELEMS_TO_INSERT=20971520;
NO_ELEMS_TO_CHECK=10485760;
LOG_AFTER_N_INSERTS=5;
LOG_AFTER_N_CHECKS=5;
AVG_AFTER_N_INSERTS=100000;
AVG_AFTER_N_CHECKS=100000;

REDIS_SERVER_PORT=9998;

echo "Removing bloom_timing files $BLOOM_INSERTION_EXEC_TIME_OUTPUT_FILE and $BLOOM_ISMEMBER_EXEC_TIME_OUTPUT_FILE"
rm $BLOOM_INSERTION_EXEC_TIME_OUTPUT_FILE
rm $BLOOM_ISMEMBER_EXEC_TIME_OUTPUT_FILE


echo "Creating bloom_timing files"
touch $BLOOM_INSERTION_EXEC_TIME_OUTPUT_FILE
touch $BLOOM_ISMEMBER_EXEC_TIME_OUTPUT_FILE

cmd_exec_output=0;

echo "Removing existing Bloom filter with name $BLOOM_FILTERNAME"
#First remove the existing filter..
~/Desktop/Redis/redis/src/redis-cli -p $REDIS_SERVER_PORT  del $BLOOM_FILTERNAME

echo "Creating Bloom filter with name $BLOOM_FILTERNAME and size $BLOOM_FILTERSIZE and $BLOOM_HASH_FNS hash functions"
getCmdOutput "~/Desktop/Redis/redis/src/redis-cli -p $REDIS_SERVER_PORT  bfcreate $BLOOM_FILTERNAME $BLOOM_FILTERSIZE $BLOOM_HASH_FNS" #bloom filter hash fns count..


#calculate time taken to insert 4-billion elements.
echo "Inserting elements into bloom filter.."
ELEM_INSERTION_COUNT=1;
VALUE=0;

echo "Initial test for insertion for bloom : "
getCmdOutput "~/Desktop/Redis/redis/src/redis-cli  -p $REDIS_SERVER_PORT bfadd $BLOOM_FILTERNAME $VALUE"

bloom_insert_time=0;
ELEM_INSERTION_COUNT=1;
while [ $ELEM_INSERTION_COUNT -le $NO_ELEMS_TO_INSERT ] #524288 = 512KB
do
        if [ 0 == `expr $ELEM_INSERTION_COUNT % $LOG_AFTER_N_INSERTS` ]
        then
                echo "Completed inserting $ELEM_INSERTION_COUNT elements into bloom filter";
        fi
        VALUE=`expr $VALUE + 2`

        lastTime="$(TIMEFORMAT='%E';time (~/Desktop/Redis/redis/src/redis-cli  -p $REDIS_SERVER_PORT bfadd $BLOOM_FILTERNAME $VALUE) 2>&1 1>/dev/null)";
        bloom_insert_time=$(echo "scale=5;$bloom_insert_time+$lastTime" | bc); #bc is for adding decimal numbers..

        if [ 0 == `expr $ELEM_INSERTION_COUNT % $AVG_AFTER_N_INSERTS` ]
        then
                time1=$(echo "scale=5;$bloom_insert_time/$ELEM_INSERTION_COUNT" | bc)
                echo "$ELEM_INSERTION_COUNT,$time1" >> $BLOOM_INSERTION_EXEC_TIME_OUTPUT_FILE
        fi
        ELEM_INSERTION_COUNT=`expr $ELEM_INSERTION_COUNT + 1`
done



#calculate time taken to check for existence of an element for say 100 or 1000 trials.
echo "Checking for element existence in bloom filters."
ELEM_CHECK_COUNT=1;
VALUE=0;

echo "Initial test for Element existence for bloom : "
getCmdOutput "~/Desktop/Redis/redis/src/redis-cli  -p $REDIS_SERVER_PORT bfmatch $BLOOM_FILTERNAME $VALUE"

bloom_check_time=0;
ELEM_CHECK_COUNT=1;
while [ $ELEM_CHECK_COUNT -le $NO_ELEMS_TO_CHECK ]
do
        if [ 0 == `expr $ELEM_CHECK_COUNT % $LOG_AFTER_N_CHECKS` ]
        then
                echo "Completed checking $ELEM_CHECK_COUNT elements in bloom filter";
        fi
        VALUE=`expr $VALUE + 1`

        lastTime="$(TIMEFORMAT='%E';time (~/Desktop/Redis/redis/src/redis-cli -p $REDIS_SERVER_PORT  bfmatch $BLOOM_FILTERNAME $VALUE) 2>&1 1>/dev/null)";
        bloom_check_time=$(echo "scale=5;$bloom_check_time+$lastTime" | bc);

        if [ 0 == `expr $ELEM_CHECK_COUNT % $AVG_AFTER_N_CHECKS` ]
        then
                time1=$(echo "scale=5;$bloom_check_time/$ELEM_CHECK_COUNT" | bc);
                echo "$ELEM_CHECK_COUNT,$time1" >> $BLOOM_ISMEMBER_EXEC_TIME_OUTPUT_FILE
        fi
        ELEM_CHECK_COUNT=`expr $ELEM_CHECK_COUNT + 1`
done

echo "Deleting the bloom filter"
~/Desktop/Redis/redis/src/redis-cli  -p $REDIS_SERVER_PORT del $BLOOM_FILTERNAME

endTime=$(echo `date`);
echo "Performance Simulated for $ELEM_INSERTION_COUNT BLOOM insertions and $ELEM_CHECK_COUNT BLOOM checks is :";
echo "Script execution start time : $startTime";
echo "Script execution end time : $endTime";

#echo "Starting Visualizing the performance differences"
#firefox ./Visualize_cuckoo_vs_bloom_performance/visualize_cuckoo_vs_bloom_performance.html

echo "***************************************************"
