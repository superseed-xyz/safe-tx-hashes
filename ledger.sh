#!/bin/bash

# This is an optional bash script to convert the legacy ledger message to it's hex 
# enter your weird ledger message into the raw_string variable and run the script
# You'll get it's hex representation

raw_string=''
echo -n "0x"; echo -en "$raw_string" | xxd -p | tr -d '\n'; echo