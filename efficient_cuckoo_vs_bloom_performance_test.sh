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
echo "NOTE : Make sure the Redis-server is running on port 12345..."
#REDISPATH="~/Desktop/Redis/redis/src/redis-cli"
CUCKOO_INSERTION_EXEC_TIME_OUTPUT_FILE="efficient_cuckoo_insert_elem_timing.csv"
CUCKOO_ISMEMBER_EXEC_TIME_OUTPUT_FILE="efficient_cuckoo_check_elem_timing.csv"

BLOOM_INSERTION_EXEC_TIME_OUTPUT_FILE="efficient_bloom_insert_elem_timing.csv"
BLOOM_ISMEMBER_EXEC_TIME_OUTPUT_FILE="efficient_bloom_check_elem_timing.csv"

CUCKOO_FILTERNAME="eff_cf"
BLOOM_FILTERNAME="eff_bf"

#CUCKOO_FILTERSIZE=536870900 #no of elements , indirectly uses 512MB memory
CUCKOO_FILTERSIZE=536870800 #40*1024*1024. for 4GB it is 4294967296
BLOOM_FILTERSIZE=536870800 #40*1024*1024
BLOOM_HASH_FNS=20

NO_ELEMS_TO_INSERT=536870800;
NO_ELEMS_TO_CHECK=536870800;
LOG_AFTER_N_INSERTS=5;
LOG_AFTER_N_CHECKS=5;
AVG_AFTER_N_INSERTS=1000000;
AVG_AFTER_N_CHECKS=1000000;

REDIS_SERVER_PORT=12345;

echo "Removing cuckoo_timing files $CUCKOO_INSERTION_EXEC_TIME_OUTPUT_FILE and $CUCKOO_ISMEMBER_EXEC_TIME_OUTPUT_FILE"
rm $CUCKOO_INSERTION_EXEC_TIME_OUTPUT_FILE
rm $CUCKOO_ISMEMBER_EXEC_TIME_OUTPUT_FILE


echo "Removing bloom_timing files $BLOOM_INSERTION_EXEC_TIME_OUTPUT_FILE and $BLOOM_ISMEMBER_EXEC_TIME_OUTPUT_FILE"
rm $BLOOM_INSERTION_EXEC_TIME_OUTPUT_FILE
rm $BLOOM_ISMEMBER_EXEC_TIME_OUTPUT_FILE


echo "Creating cuckoo_timing files"
touch $CUCKOO_INSERTION_EXEC_TIME_OUTPUT_FILE
touch $CUCKOO_ISMEMBER_EXEC_TIME_OUTPUT_FILE


echo "Creating bloom_timing files"
touch $BLOOM_INSERTION_EXEC_TIME_OUTPUT_FILE
touch $BLOOM_ISMEMBER_EXEC_TIME_OUTPUT_FILE

cmd_exec_output=0;
echo "Removing existing Cuckoo filter with name $CUCKOO_FILTERNAME"
#First remove the existing filter..
~/Desktop/Redis/redis/src/redis-cli -p $REDIS_SERVER_PORT del $CUCKOO_FILTERNAME

echo "Creating Cuckoo filter with name $CUCKOO_FILTERNAME and size $CUCKOO_FILTERSIZE"
getCmdOutput ~/Desktop/Redis/redis/src/redis-cli -p $REDIS_SERVER_PORT cuckoocreate $CUCKOO_FILTERNAME $CUCKOO_FILTERSIZE



echo "Removing existing Bloom filter with name $BLOOM_FILTERNAME"
#First remove the existing filter..
~/Desktop/Redis/redis/src/redis-cli -p $REDIS_SERVER_PORT  del $BLOOM_FILTERNAME

echo "Creating Bloom filter with name $BLOOM_FILTERNAME and size $BLOOM_FILTERSIZE and $BLOOM_HASH_FNS hash functions"
getCmdOutput "~/Desktop/Redis/redis/src/redis-cli -p $REDIS_SERVER_PORT  bfcreate $BLOOM_FILTERNAME $BLOOM_FILTERSIZE $BLOOM_HASH_FNS" #bloom filter hash fns count..
#read -p "Press any key to continue"


#calculate time taken to insert 4-billion elements.
echo "Inserting elements into cuckoo and bloom filters.."
ELEM_INSERTION_COUNT=1;
VALUE=0;
#while [$ELEM_INSERTION_COUNT -lt 4294967296]
#\time -f "%e" -a -o $CUCKOO_INSERTION_EXEC_TIME_OUTPUT_FILE ~/Desktop/Redis/redis/src/redis-cli cuckooinsertelement $CUCKOO_FILTERNAME $VALUE
#while [$ELEM_INSERTION_COUNT -lt 4000000000]

#while [ $ELEM_INSERTION_COUNT -lt 524288 ] #524288 = 512KB
echo "Initial test for insertion for cuckoo : "
getCmdOutput "~/Desktop/Redis/redis/src/redis-cli  -p $REDIS_SERVER_PORT cuckooinsertelement $CUCKOO_FILTERNAME $VALUE"
#read -p "Press any key to continue"

echo "Initial test for insertion for bloom : "
getCmdOutput "~/Desktop/Redis/redis/src/redis-cli  -p $REDIS_SERVER_PORT bfadd $BLOOM_FILTERNAME $VALUE"
#read -p "Press any key to continue"

cuckoo_insert_time=0;
while [ $ELEM_INSERTION_COUNT -le $NO_ELEMS_TO_INSERT ] #524288 = 512KB
#while [ $ELEM_INSERTION_COUNT -le 50000 ] #524288 = 512KB
#while [ $ELEM_INSERTION_COUNT -le 50 ] #524288 = 512KB
do
	if [ 0 == `expr $ELEM_INSERTION_COUNT % $LOG_AFTER_N_INSERTS` ]
	then
		echo "Completed inserting $ELEM_INSERTION_COUNT elements into cuckoo filter";
	fi
	VALUE=`expr $VALUE + 2`

        lastTime="$(TIMEFORMAT='%E';time (~/Desktop/Redis/redis/src/redis-cli  -p $REDIS_SERVER_PORT cuckooinsertelement $CUCKOO_FILTERNAME $VALUE) 2>&1 1>/dev/null )" ;
        cuckoo_insert_time=$(echo "scale=5;$cuckoo_insert_time+$lastTime" | bc);

	#lastTime="$(TIMEFORMAT='%E';time (~/Desktop/Redis/redis/src/redis-cli  -p $REDIS_SERVER_PORT bfadd $BLOOM_FILTERNAME $VALUE) 2>&1 1>/dev/null)";
	#bloom_insert_time=$(echo "scale=5;$bloom_insert_time+$lastTime" | bc); #bc is for adding decimal numbers..

	if [ 0 == `expr $ELEM_INSERTION_COUNT % $AVG_AFTER_N_INSERTS` ]
	#if [ 0 == `expr $ELEM_INSERTION_COUNT % 10` ]
	then
		#time1=$(echo "scale=5;$bloom_insert_time/$ELEM_INSERTION_COUNT" | bc)
		#echo "$ELEM_INSERTION_COUNT,$time1" >> $BLOOM_INSERTION_EXEC_TIME_OUTPUT_FILE
	        time2=$(echo "scale=5;$cuckoo_insert_time/$ELEM_INSERTION_COUNT" | bc)
	        echo "$ELEM_INSERTION_COUNT,$time2" >> $CUCKOO_INSERTION_EXEC_TIME_OUTPUT_FILE
	fi
	ELEM_INSERTION_COUNT=`expr $ELEM_INSERTION_COUNT + 1`
done

bloom_insert_time=0;
ELEM_INSERTION_COUNT=1;
while [ $ELEM_INSERTION_COUNT -le $NO_ELEMS_TO_INSERT ] #524288 = 512KB
#while [ $ELEM_INSERTION_COUNT -le 50000 ] #524288 = 512KB
#while [ $ELEM_INSERTION_COUNT -le 50 ] #524288 = 512KB
do
        if [ 0 == `expr $ELEM_INSERTION_COUNT % $LOG_AFTER_N_INSERTS` ]
        then
                echo "Completed inserting $ELEM_INSERTION_COUNT elements into bloom filter";
        fi
        VALUE=`expr $VALUE + 2`

        #lastTime="$(TIMEFORMAT='%E';time (~/Desktop/Redis/redis/src/redis-cli  -p $REDIS_SERVER_PORT cuckooinsertelement $CUCKOO_FILTERNAME $VALUE) 2>&1 1>/dev/null )" ;
        #cuckoo_insert_time=$(echo "scale=5;$cuckoo_insert_time+$lastTime" | bc);

        lastTime="$(TIMEFORMAT='%E';time (~/Desktop/Redis/redis/src/redis-cli  -p $REDIS_SERVER_PORT bfadd $BLOOM_FILTERNAME $VALUE) 2>&1 1>/dev/null)";
        bloom_insert_time=$(echo "scale=5;$bloom_insert_time+$lastTime" | bc); #bc is for adding decimal numbers..

        if [ 0 == `expr $ELEM_INSERTION_COUNT % $AVG_AFTER_N_INSERTS` ]
        #if [ 0 == `expr $ELEM_INSERTION_COUNT % 10` ]
        then
                time1=$(echo "scale=5;$bloom_insert_time/$ELEM_INSERTION_COUNT" | bc)
                echo "$ELEM_INSERTION_COUNT,$time1" >> $BLOOM_INSERTION_EXEC_TIME_OUTPUT_FILE
                #time2=$(echo "scale=5;$cuckoo_insert_time/$ELEM_INSERTION_COUNT" | bc)
                #echo "$ELEM_INSERTION_COUNT,$time2" >> $CUCKOO_INSERTION_EXEC_TIME_OUTPUT_FILE
        fi
        ELEM_INSERTION_COUNT=`expr $ELEM_INSERTION_COUNT + 1`
done



#calculate time taken to check for existence of an element for say 100 or 1000 trials.
echo "Checking for element existence in bloom and cuckoo filters."
ELEM_CHECK_COUNT=1;
VALUE=0;

echo "Initial test for Element existence for cuckoo : "
getCmdOutput "~/Desktop/Redis/redis/src/redis-cli  -p $REDIS_SERVER_PORT cuckoocheckelement $CUCKOO_FILTERNAME $VALUE"
#read -p "Press any key to continue"

echo "Initial test for Element existence for bloom : "
getCmdOutput "~/Desktop/Redis/redis/src/redis-cli  -p $REDIS_SERVER_PORT bfmatch $BLOOM_FILTERNAME $VALUE"
#read -p "Press any key to continue"

cuckoo_check_time=0;
while [ $ELEM_CHECK_COUNT -le $NO_ELEMS_TO_CHECK ]
#while [ $ELEM_CHECK_COUNT -le 40000 ]
#while [ $ELEM_CHECK_COUNT -le 40 ]
do
        if [ 0 == `expr $ELEM_CHECK_COUNT % $LOG_AFTER_N_CHECKS` ]
        then
		echo "Completed checking $ELEM_CHECK_COUNT elements in cuckoo filter";
        fi
	VALUE=`expr $VALUE + 1`

        lastTime="$(TIMEFORMAT='%E';time (~/Desktop/Redis/redis/src/redis-cli -p $REDIS_SERVER_PORT  cuckoocheckelement $CUCKOO_FILTERNAME $VALUE) 2>&1 1>/dev/null)";
        cuckoo_check_time=$(echo "scale=5;$cuckoo_check_time+$lastTime" | bc);

        #lastTime="$(TIMEFORMAT='%E';time (~/Desktop/Redis/redis/src/redis-cli  -p $REDIS_SERVER_PORT bfmatch $BLOOM_FILTERNAME $VALUE) 2>&1 1>/dev/null)";
	#bloom_check_time=$(echo "scale=5;$bloom_check_time+$lastTime" | bc);

	if [ 0 == `expr $ELEM_CHECK_COUNT % $AVG_AFTER_N_CHECKS` ]
	#if [ 0 == `expr $ELEM_CHECK_COUNT % 10` ]
	then
	        #time1=$(echo "scale=5;$bloom_check_time/$ELEM_CHECK_COUNT" | bc);
	        #echo "$ELEM_CHECK_COUNT,$time1" >> $BLOOM_ISMEMBER_EXEC_TIME_OUTPUT_FILE
	        time2=$(echo "scale=5;$cuckoo_check_time/$ELEM_CHECK_COUNT" | bc);
		echo "$ELEM_CHECK_COUNT,$time2" >> $CUCKOO_ISMEMBER_EXEC_TIME_OUTPUT_FILE
	fi
	ELEM_CHECK_COUNT=`expr $ELEM_CHECK_COUNT + 1`
done


bloom_check_time=0;
ELEM_CHECK_COUNT=1;
while [ $ELEM_CHECK_COUNT -le $NO_ELEMS_TO_CHECK ]
#while [ $ELEM_CHECK_COUNT -le 40000 ]
#while [ $ELEM_CHECK_COUNT -le 40 ]
do
        if [ 0 == `expr $ELEM_CHECK_COUNT % $LOG_AFTER_N_CHECKS` ]
        then
                echo "Completed checking $ELEM_CHECK_COUNT elements in bloom filter";
        fi
        VALUE=`expr $VALUE + 1`

        #lastTime="$(TIMEFORMAT='%E';time (~/Desktop/Redis/redis/src/redis-cli  -p $REDIS_SERVER_PORT cuckoocheckelement $CUCKOO_FILTERNAME $VALUE) 2>&1 1>/dev/null)";
        #cuckoo_check_time=$(echo "scale=5;$cuckoo_check_time+$lastTime" | bc);

        lastTime="$(TIMEFORMAT='%E';time (~/Desktop/Redis/redis/src/redis-cli -p $REDIS_SERVER_PORT  bfmatch $BLOOM_FILTERNAME $VALUE) 2>&1 1>/dev/null)";
        bloom_check_time=$(echo "scale=5;$bloom_check_time+$lastTime" | bc);

        if [ 0 == `expr $ELEM_CHECK_COUNT % $AVG_AFTER_N_CHECKS` ]
        #if [ 0 == `expr $ELEM_CHECK_COUNT % 10` ]
        then
                time1=$(echo "scale=5;$bloom_check_time/$ELEM_CHECK_COUNT" | bc);
                echo "$ELEM_CHECK_COUNT,$time1" >> $BLOOM_ISMEMBER_EXEC_TIME_OUTPUT_FILE
                #time2=$(echo "scale=5;$cuckoo_check_time/$ELEM_CHECK_COUNT" | bc);
                #echo "$ELEM_CHECK_COUNT,$time2" >> $CUCKOO_ISMEMBER_EXEC_TIME_OUTPUT_FILE
        fi
        ELEM_CHECK_COUNT=`expr $ELEM_CHECK_COUNT + 1`
done

echo "Deleting the cuckoo filter"
~/Desktop/Redis/redis/src/redis-cli -p $REDIS_SERVER_PORT  del $CUCKOO_FILTERNAME

echo "Deleting the bloom filter"
~/Desktop/Redis/redis/src/redis-cli  -p $REDIS_SERVER_PORT del $BLOOM_FILTERNAME

endTime=$(echo `date`);
echo "Performance Simulated for $ELEM_INSERTION_COUNT insertions and $ELEM_CHECK_COUNT checks is :";
echo "Script execution start time : $startTime";
echo "Script execution end time : $endTime";

#read -p "Press any key to start visualization";

echo "Starting Visualizing the performance differences"
#firefox ./Visualize_cuckoo_vs_bloom_performance/visualize_cuckoo_vs_bloom_performance.html

echo "***************************************************"
