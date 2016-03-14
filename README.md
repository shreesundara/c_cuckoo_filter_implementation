# c_cuckoo_filter_implementation
Implementing simple cuckoo filter in c language

Currently only tested on Ubuntu Operating system.
The following are the compilation options..
gcc -g -c -D __TRACE -D __DEBUG cuckoo_filter.c
ar rvs cuckoo_filter.a cuckoo_filter.o
gcc -g -D __TRACE -D __DEBUG -lm test_cuckoo_filter.c cuckoo_filter.a
