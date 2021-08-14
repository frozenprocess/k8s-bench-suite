#!/bin/bash
if ! command -v jq &> /dev/null
then
    echo "jq could not be found"
    exit
fi

CN="ip-10-0-151-248"
SN="ip-10-0-170-148"
PREFIX=$(kubectl get installation.operator.tigera.io default -o jsonpath='{.spec.calicoNetwork.linuxDataplane}')
# MODE=$(kubectl get felixconfiguration default -o jsonpath='{.spec.bpfExternalServiceMode}'
RULES=$(kubectl get cnp | wc -l)
MULTI="2"
PARALLEL="2"
for I in {1..5}
  do
    echo "Running benchmark $I without any rules"
    ./knb -cn $CN -sn $SN -m $MULTI -p $PARALLEL -n calic-test -o data -f "results/$PREFIX-$RULES-RULES-$I.knbdata"
    echo "Benchmark $I completed. Waiting 60 Seconds for the cleanup ..."
    sleep 60
done

# echo "Importing rules"
# kubectl apply -f rules
# sleep 10

# echo "Running benchmark with rules"
# for I in {1..5}
#   do
#     ./knb -cn $CN -sn $SN -m $MULTI -p $PARALLEL -o data -f "results/$PREFIX-with-rules-$I.knbdata"
#     echo "Benchmark $I completed. Waiting 60 Seconds for the cleanup ..."
#     sleep 60
# done

# echo "Cleaning up rules"
# kubectl delete -f rules
