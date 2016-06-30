#!/bin/bash

while :
do
	rm ~/.telegram-cli/state
	./launch.sh
	sleep 5
done
