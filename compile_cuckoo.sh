#!/usr/bin/bash
rm cuckoo_filter.o
rm cuckoo_filter_manual.a
rm cuckoo_filter_auto.a
rm manual_test_cuckoo.out
rm auto_test_cuckoo.out

echo "************* COMPILING THE CUCKOO FILTER LIBRARY SOURCE FILE  (gcc -c -g -DDEBUG cuckoo_filter.c)   ***********"
gcc -c -g -DDEBUG cuckoo_filter.c
echo "************* CREATING CUCKOO FILTER LIBRARY cuckoo_filter.a (ar rvs cuckoo_filter.a cuckoo_filter.o)  ************"
ar rvs cuckoo_filter_manual.a cuckoo_filter.o
echo "***********  COMPILING THE TEST CUCKOO FILTER SOURCE FILE (gcc -g test_cuckoo_filter.c cuckoo_filter.a -lm -o cuckoo_start.out) ***************"
gcc -g manual_test_cuckoo_filter.c cuckoo_filter_manual.a -lm -o manual_test_cuckoo.out



rm cuckoo_filter.o
echo "************* COMPILING THE CUCKOO FILTER LIBRARY SOURCE FILE  (gcc -c -g -DDEBUG cuckoo_filter.c)   ***********"
gcc -c -g cuckoo_filter.c
echo "************* CREATING CUCKOO FILTER LIBRARY cuckoo_filter.a (ar rvs cuckoo_filter.a cuckoo_filter.o)  ************"
ar rvs cuckoo_filter_auto.a cuckoo_filter.o
echo "********** COMPILING THE TEST CASES SOURCE FILE (gcc -g cuckoo_test_cases.c cuckoo_filter.a -lm -o auto_test_cuckoo.out)  ***************"
gcc -g auto_test_cuckoo_filter.c cuckoo_filter_auto.a -lm -o auto_test_cuckoo.out
echo "************** END OF COMPILATION ****************"


echo " Check Manually if any error are generated during compilation"
