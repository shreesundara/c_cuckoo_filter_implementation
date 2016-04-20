#!/usr/bin/bash

echo "***************************************************"
echo "NOTE : Make sure the Redis-server is running..."
#REDISPATH="~/Desktop/Redis/redis/src/redis-cli"
CUCKOO_INSERTION_EXEC_TIME_OUTPUT_FILE="cuckoo_insert_elem_timing.txt"
CUCKOO_ISMEMBER_EXEC_TIME_OUTPUT_FILE="cuckoo_check_elem_timing.txt"

BLOOM_INSERTION_EXEC_TIME_OUTPUT_FILE="bloom_insert_elem_timing.txt"
BLOOM_ISMEMBER_EXEC_TIME_OUTPUT_FILE="bloom_check_elem_timing.txt"

CUCKOO_FILTERNAME="ck"
BLOOM_FILTERNAME="bf"

#CUCKOO_FILTERSIZE=4000000000
#CUCKOO_FILTERSIZE=536870900 #no of elements , indirectly uses 512MB memory
CUCKOO_FILTERSIZE=4000
BLOOM_FILTERSIZE=4000

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


echo "Creating Cuckoo filter with name $CUCKOO_FILTERNAME and size $CUCKOO_FILTERSIZE"
#First remove the existing filter..
~/Desktop/Redis/redis/src/redis-cli del $CUCKOO_FILTERNAME
~/Desktop/Redis/redis/src/redis-cli cuckoocreate $CUCKOO_FILTERNAME $CUCKOO_FILTERSIZE


echo "Creating Bloom filter with name $BLOOM_FILTERNAME and size $BLOOM_FILTERSIZE and 20 hash functions"
#First remove the existing filter..
~/Desktop/Redis/redis/src/redis-cli del $BLOOM_FILTERNAME
~/Desktop/Redis/redis/src/redis-cli bfcreate $BLOOM_FILTERNAME $BLOOM_FILTERSIZE 20 #bloom filter hash fns count..


#calculate time taken to insert 4-billion elements.
echo "Inserting elements into cuckoo and bloom filters.."
ELEM_INSERTION_COUNT=0;
VALUE=0;
#while [$ELEM_INSERTION_COUNT -lt 4294967296]
#\time -f "%e" -a -o $CUCKOO_INSERTION_EXEC_TIME_OUTPUT_FILE ~/Desktop/Redis/redis/src/redis-cli cuckooinsertelement $CUCKOO_FILTERNAME $VALUE
#while [$ELEM_INSERTION_COUNT -lt 4000000000]

#while [ $ELEM_INSERTION_COUNT -lt 524288 ] #524288 = 512KB
while [ $ELEM_INSERTION_COUNT -lt 100 ] #524288 = 512KB
do
	echo "Inserting element NUMBER $ELEM_INSERTION_COUNT"
	VALUE=`expr $VALUE + 2`

	#echo "Inserting value $VALUE into cuckoo filter."
	\time -f "$ELEM_INSERTION_COUNT,%e" -a -o $CUCKOO_INSERTION_EXEC_TIME_OUTPUT_FILE ~/Desktop/Redis/redis/src/redis-cli cuckooinsertelement $CUCKOO_FILTERNAME $VALUE

	#echo "Inserting value $VALUE into bloom filter."
	\time -f "$ELEM_INSERTION_COUNT,%e" -a -o $BLOOM_INSERTION_EXEC_TIME_OUTPUT_FILE ~/Desktop/Redis/redis/src/redis-cli bfadd $BLOOM_FILTERNAME $VALUE	
	
	ELEM_INSERTION_COUNT=`expr $ELEM_INSERTION_COUNT + 1`
done


#calculate time taken to check for existence of an element for say 100 or 1000 trials.
echo "Checking for element existence in bloom and cuckoo filters."
ELEM_CHECK_COUNT=0;
VALUE=0;
while [ $ELEM_CHECK_COUNT -lt 50 ]
do
	echo "Checking iteration number : $ELEM_CHECK_COUNT"
	VALUE=`expr $VALUE + 1`

	#echo "Checking for value $VALUE in cuckoo filter."
	\time -f "$ELEM_CHECK_COUNT,%e" -a -o $CUCKOO_ISMEMBER_EXEC_TIME_OUTPUT_FILE ~/Desktop/Redis/redis/src/redis-cli cuckoocheckelement $CUCKOO_FILTERNAME $VALUE

	#echo "Checking for value $VALUE in bloom filter."
	\time -f "$ELEM_CHECK_COUNT,%e" -a -o $BLOOM_ISMEMBER_EXEC_TIME_OUTPUT_FILE ~/Desktop/Redis/redis/src/redis-cli bfmatch $BLOOM_FILTERNAME $VALUE

	ELEM_CHECK_COUNT=`expr $ELEM_CHECK_COUNT + 1`
done

echo "Deleting the cuckoo filter"
~/Desktop/Redis/redis/src/redis-cli del $CUCKOO_FILTERNAME

echo "Deleting the bloom filter"
~/Desktop/Redis/redis/src/redis-cli del $BLOOM_FILTERNAME

echo "***************************************************"