#!/bin/bash

ALBURL=$1
while :
do
    ab -p test.json -T application/json -c 4000 -n 10000000 -v 4 http://$ALBURL/encrypt
done