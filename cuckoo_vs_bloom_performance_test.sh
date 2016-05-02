#!/usr/bin/bash
tee "cuckoo_vs_bloom_performance_log.txt"
echo "***************************************************"
echo "The configuration on which the test script is run is shown below";
sudo lshw #to print the system configuration.
echo " ";
clear
reset
startTime=$(echo `date`);
echo "NOTE : Make sure the Redis-server is running..."
#REDISPATH="~/Desktop/Redis/redis/src/redis-cli"
CUCKOO_INSERTION_EXEC_TIME_OUTPUT_FILE="cuckoo_insert_elem_timing.csv"
CUCKOO_ISMEMBER_EXEC_TIME_OUTPUT_FILE="cuckoo_check_elem_timing.csv"

BLOOM_INSERTION_EXEC_TIME_OUTPUT_FILE="bloom_insert_elem_timing.csv"
BLOOM_ISMEMBER_EXEC_TIME_OUTPUT_FILE="bloom_check_elem_timing.csv"

CUCKOO_FILTERNAME="ck"
BLOOM_FILTERNAME="bf"

#CUCKOO_FILTERSIZE=4000000000
#CUCKOO_FILTERSIZE=536870900 #no of elements , indirectly uses 512MB memory
CUCKOO_FILTERSIZE=41943040 #40*1024*1024
BLOOM_FILTERSIZE=41943040 #40*1024*1024
BLOOM_HASH_FNS=30

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


echo "Removing existing Cuckoo filter with name $CUCKOO_FILTERNAME"
#First remove the existing filter..
~/Desktop/Redis/redis/src/redis-cli del $CUCKOO_FILTERNAME
echo "Creating Cuckoo filter with name $CUCKOO_FILTERNAME and size $CUCKOO_FILTERSIZE"
~/Desktop/Redis/redis/src/redis-cli cuckoocreate $CUCKOO_FILTERNAME $CUCKOO_FILTERSIZE
read -p "Press any key to continue"

echo "Removing existing Bloom filter with name $BLOOM_FILTERNAME"
#First remove the existing filter..
~/Desktop/Redis/redis/src/redis-cli del $BLOOM_FILTERNAME
echo "Creating Bloom filter with name $BLOOM_FILTERNAME and size $BLOOM_FILTERSIZE and $BLOOM_HASH_FNS hash functions"
~/Desktop/Redis/redis/src/redis-cli bfcreate $BLOOM_FILTERNAME $BLOOM_FILTERSIZE $BLOOM_HASH_FNS #bloom filter hash fns count..
read -p "Press any key to continue"

#calculate time taken to insert 4-billion elements.
echo "Inserting elements into cuckoo and bloom filters.."
ELEM_INSERTION_COUNT=1;
VALUE=0;
#while [$ELEM_INSERTION_COUNT -lt 4294967296]
#\time -f "%e" -a -o $CUCKOO_INSERTION_EXEC_TIME_OUTPUT_FILE ~/Desktop/Redis/redis/src/redis-cli cuckooinsertelement $CUCKOO_FILTERNAME $VALUE
#while [$ELEM_INSERTION_COUNT -lt 4000000000]

#while [ $ELEM_INSERTION_COUNT -lt 524288 ] #524288 = 512KB
echo "Initial test for insertion for cuckoo : "
~/Desktop/Redis/redis/src/redis-cli cuckooinsertelement $CUCKOO_FILTERNAME $VALUE
read -p "Press any key to continue"

echo "Initial test for insertion for bloom : "
~/Desktop/Redis/redis/src/redis-cli bfadd $BLOOM_FILTERNAME $VALUE
read -p "Press any key to continue"

cuckoo_insert_time=0;
bloom_insert_time=0;
while [ $ELEM_INSERTION_COUNT -le 50000 ] #524288 = 512KB
#while [ $ELEM_INSERTION_COUNT -le 50 ] #524288 = 512KB
do
	echo "Inserting element NUMBER $ELEM_INSERTION_COUNT"
	VALUE=`expr $VALUE + 2`

	##echo "Inserting value $VALUE into cuckoo filter."
	##\time -f "$ELEM_INSERTION_COUNT,%e" -a -o $CUCKOO_INSERTION_EXEC_TIME_OUTPUT_FILE ~/Desktop/Redis/redis/src/redis-cli cuckooinsertelement $CUCKOO_FILTERNAME $VALUE
	#cuckoo_insert_time="$(TIMEFORMAT='%E';time (~/Desktop/Redis/redis/src/redis-cli cuckooinsertelement $CUCKOO_FILTERNAME $VALUE) 2>&1 1>/dev/null )" ;
	#echo "$ELEM_INSERTION_COUNT,$cuckoo_insert_time" >> $CUCKOO_INSERTION_EXEC_TIME_OUTPUT_FILE
	#echo "Time taken for cuckoo is $cuckoo_insert_time"
	#cuckoo_insert_time=0;

	#echo "Inserting value $VALUE into bloom filter."
	#\time -f "$ELEM_INSERTION_COUNT,%e" -a -o $BLOOM_INSERTION_EXEC_TIME_OUTPUT_FIL8E ~/Desktop/Redis/redis/src/redis-cli bfadd $BLOOM_FILTERNAME $VALUE	
	lastTime="$(TIMEFORMAT='%E';time (~/Desktop/Redis/redis/src/redis-cli bfadd $BLOOM_FILTERNAME $VALUE) 2>&1 1>/dev/null)";
	bloom_insert_time=$(echo "scale=5;$bloom_insert_time+$lastTime" | bc); #bc is for adding decimal numbers..
	#echo "Time taken for bloom is $bloom_insert_time"

        #echo "Inserting value $VALUE into cuckoo filter."
        #\time -f "$ELEM_INSERTION_COUNT,%e" -a -o $CUCKOO_INSERTION_EXEC_TIME_OUTPUT_FILE ~/Desktop/Redis/redis/src/redis-cli cuckooinsertelement $CUCKOO_FILTERNAME $
        lastTime="$(TIMEFORMAT='%E';time (~/Desktop/Redis/redis/src/redis-cli cuckooinsertelement $CUCKOO_FILTERNAME $VALUE) 2>&1 1>/dev/null )" ;
        cuckoo_insert_time=$(echo "scale=5;$cuckoo_insert_time+$lastTime" | bc);
        #echo "Time taken for cuckoo is $cuckoo_insert_time"

	if [ 0 == `expr $ELEM_INSERTION_COUNT % 1000` ]
	#if [ 0 == `expr $ELEM_INSERTION_COUNT % 10` ]
	then
		time1=$(echo "scale=5;$bloom_insert_time/$ELEM_INSERTION_COUNT" | bc)
		echo "$ELEM_INSERTION_COUNT,$time1" >> $BLOOM_INSERTION_EXEC_TIME_OUTPUT_FILE
	        time2=$(echo "scale=5;$cuckoo_insert_time/$ELEM_INSERTION_COUNT" | bc)
	        echo "$ELEM_INSERTION_COUNT,$time2" >> $CUCKOO_INSERTION_EXEC_TIME_OUTPUT_FILE
                #echo "Cuckoo time for iter:$ELEM_INSERTION_COUNT is $time2"
                #echo "Bloom time for iter:$ELEM_INSERTION_COUNT is $time1"
	fi
	ELEM_INSERTION_COUNT=`expr $ELEM_INSERTION_COUNT + 1`
done


#calculate time taken to check for existence of an element for say 100 or 1000 trials.
echo "Checking for element existence in bloom and cuckoo filters."
ELEM_CHECK_COUNT=1;
VALUE=0;

echo "Initial test for Element existence for cuckoo : "
~/Desktop/Redis/redis/src/redis-cli cuckoocheckelement $CUCKOO_FILTERNAME $VALUE
read -p "Press any key to continue"

echo "Initial test for Element existence for bloom : "
~/Desktop/Redis/redis/src/redis-cli bfmatch $BLOOM_FILTERNAME $VALUE
read -p "Press any key to continue"

cuckoo_check_time=0;
bloom_check_time=0;
while [ $ELEM_CHECK_COUNT -le 40000 ]
#while [ $ELEM_CHECK_COUNT -le 40 ]
do
	echo "Checking iteration number : $ELEM_CHECK_COUNT"
	VALUE=`expr $VALUE + 1`

	##echo "Checking for value $VALUE in cuckoo filter."
	##\time -f "$ELEM_CHECK_COUNT,%e" -a -o $CUCKOO_ISMEMBER_EXEC_TIME_OUTPUT_FILE ~/Desktop/Redis/redis/src/redis-cli cuckoocheckelement $CUCKOO_FILTERNAME $VALUE
        #cuckoo_check_time="$(TIMEFORMAT='%E';time (~/Desktop/Redis/redis/src/redis-cli cuckoocheckelement $CUCKOO_FILTERNAME $VALUE) 2>&1 1>/dev/null)";
        #echo "$ELEM_CHECK_COUNT,$cuckoo_check_time" >> $CUCKOO_ISMEMBER_EXEC_TIME_OUTPUT_FILE
	#echo "time taken for cuckoo check is $cuckoo_check_time";
	#cuckoo_check_time=0;

	#echo "Checking for value $VALUE in bloom filter."
	#\time -f "$ELEM_CHECK_COUNT,%e" -a -o $BLOOM_ISMEMBER_EXEC_TIME_OUTPUT_FILE ~/Desktop/Redis/redis/src/redis-cli bfmatch $BLOOM_FILTERNAME $VALUE
        lastTime="$(TIMEFORMAT='%E';time (~/Desktop/Redis/redis/src/redis-cli bfmatch $BLOOM_FILTERNAME $VALUE) 2>&1 1>/dev/null)";
	bloom_check_time=$(echo "scale=5;$bloom_check_time+$lastTime" | bc);
	#echo "time taken for bloom check is $bloom_check_time"

        #echo "Checking for value $VALUE in cuckoo filter."
        #\time -f "$ELEM_CHECK_COUNT,%e" -a -o $CUCKOO_ISMEMBER_EXEC_TIME_OUTPUT_FILE ~/Desktop/Redis/redis/src/redis-cli cuckoocheckelement $CUCKOO_FILTERNAME $VALUE
        lastTime="$(TIMEFORMAT='%E';time (~/Desktop/Redis/redis/src/redis-cli cuckoocheckelement $CUCKOO_FILTERNAME $VALUE) 2>&1 1>/dev/null)";
        cuckoo_check_time=$(echo "scale=5;$cuckoo_check_time+$lastTime" | bc);
        #echo "time taken for cuckoo check is $cuckoo_check_time";

	if [ 0 == `expr $ELEM_CHECK_COUNT % 1000` ]
	#if [ 0 == `expr $ELEM_CHECK_COUNT % 10`]
	then
	        time1=$(echo "scale=5;$bloom_check_time/$ELEM_CHECK_COUNT" | bc);
	        echo "$ELEM_CHECK_COUNT,$time1" >> $BLOOM_ISMEMBER_EXEC_TIME_OUTPUT_FILE
	        time2=$(echo "scale=5;$cuckoo_check_time/$ELEM_CHECK_COUNT" | bc);
		echo "$ELEM_CHECK_COUNT,$time2" >> $CUCKOO_ISMEMBER_EXEC_TIME_OUTPUT_FILE
		#echo "Cuckoo time for iter:$ELEM_CHECK_COUNT is $time2"
		#echo "Bloom time for iter:$ELEM_CHECK_COUNT is $time1"
	fi
	ELEM_CHECK_COUNT=`expr $ELEM_CHECK_COUNT + 1`
done

echo "Deleting the cuckoo filter"
~/Desktop/Redis/redis/src/redis-cli del $CUCKOO_FILTERNAME

echo "Deleting the bloom filter"
~/Desktop/Redis/redis/src/redis-cli del $BLOOM_FILTERNAME

endTime=$(echo `date`);
echo "Script execution start time : $startTime for $ELEM_INSERTION_TIME insertions and $ELEM_CHECK_COUNT checks is :";
echo "Script execution end time : $endTime";

read -p "Press any key to start visualization";

echo "Starting Visualizing the performance differences"
firefox ./Visualize_cuckoo_vs_bloom_performance/visualize_cuckoo_vs_bloom_performance.html

echo "***************************************************"
