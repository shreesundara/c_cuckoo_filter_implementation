#!/usr/bin/bash

echo "***************************************************"
echo "NOTE : Make sure the Redis-server is running..."
#REDISPATH="~/Desktop/Redis/redis/src/redis-cli"
INSERTION_EXEC_TIME_OUTPUT_FILE="cuckoo_insert_elem_timing.txt"
ISMEMBER_EXEC_TIME_OUTPUT_FILE="cuckoo_check_elem_timing.txt"
FILTERNAME="ck"
FILTERSIZE=4000000000

echo "Removing cuckoo_timing files $INSERTION_EXEC_TIME_OUTPUT_FILE and $ISMEMBER_EXEC_TIME_OUTPUT_FILE"
rm $INSERTION_EXEC_TIME_OUTPUT_FILE
rm $ISMEMBER_EXEC_TIME_OUTPUT_FILE

echo "Creating cuckoo_timing.txt"
touch $INSERTION_EXEC_TIME_OUTPUT_FILE
touch $ISMEMBER_EXEC_TIME_OUTPUT_FILE

echo "Creating cuckoo filter.."
#First remove the existing filter..
~/Desktop/Redis/redis/src/redis-cli del $FILTERNAME
~/Desktop/Redis/redis/src/redis-cli cuckoocreate $FILTERNAME $FILTERSIZE


#calculate time taken to insert 4-billion elements.
echo "Inserting 4-billion elements into cuckoo filter.."
ELEM_INSERTION_COUNT=0;
VALUE=0;
#while [$ELEM_INSERTION_COUNT -lt 4294967296]
#\time -f "%e" -a -o $INSERTION_EXEC_TIME_OUTPUT_FILE ~/Desktop/Redis/redis/src/redis-cli cuckooinsertelement $FILTERNAME $VALUE
#while [$ELEM_INSERTION_COUNT -lt 4000000000]
while [ $ELEM_INSERTION_COUNT -lt 400 ]
do
	echo "Inserting element NUMBER $ELEM_INSERTION_COUNT"
	VALUE=`expr $VALUE + 2`
	\time -f "%e" -a -o $INSERTION_EXEC_TIME_OUTPUT_FILE ~/Desktop/Redis/redis/src/redis-cli cuckooinsertelement $FILTERNAME $VALUE
	ELEM_INSERTION_COUNT=`expr $ELEM_INSERTION_COUNT + 1`
done


#calculate time taken to check for existence of an element for say 100 or 1000 trials.
echo "Checking for element existence.."
ELEM_CHECK_COUNT=0;
VALUE=0;
while [ $ELEM_CHECK_COUNT -lt 100 ]
do
	echo "Checking iteration number : $ELEM_CHECK_COUNT"
	VALUE=`expr $VALUE + 1`
	\time -f "%e" -a -o $ISMEMBER_EXEC_TIME_OUTPUT_FILE ~/Desktop/Redis/redis/src/redis-cli cuckoocheckelement $FILTERNAME $VALUE
	ELEM_CHECK_COUNT=`expr $ELEM_CHECK_COUNT + 1`
done

echo "***************************************************"