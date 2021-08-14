#!/bin/bash

RULES=`ls /rules`
for entry in "RULES"/*
do
  ./calicoctl apply -f rules/$entry
  sleep(5)
done
