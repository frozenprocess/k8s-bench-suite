#!/bin/bash
if ! command -v kubectl &> /dev/null
then
    echo "kubectl could not be found"
    exit
fi

CN="ip-10-0-144-18"
SN="ip-10-0-165-121"
PREFIX=$(kubectl get installation.operator.tigera.io default -o jsonpath='{.spec.calicoNetwork.linuxDataplane}')
# MODE=$(kubectl get felixconfiguration default -o jsonpath='{.spec.bpfExternalServiceMode}'
MULTI="2"
PARALLEL="2"
NAMESPACE="calico-test"
RULES=$(kubectl get cnp -n $NAMESPACE | wc -l)

# Making sure test namespace exists
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: $NAMESPACE
EOF

echo "Calico is using $PREFIX dataplane."
# Run bunch of benchmarks for a better result?
echo "Running 5 benchmark/s with $RULES rules."

for I in {1..5}
  do
    ./knb -cn $CN -sn $SN -m $MULTI -p $PARALLEL -n $NAMESPACE -o data -f "results/$PREFIX-$RULES-rules-$I.knbdata"
    echo "Benchmark $I is done, Waiting for the clean up ..."
    while [ $(kubectl get pods -n $NAMESPACE | wc -l) != "0" ]
    do
      sleep 60
    done
done

echo "Importing 11 security rules with 100,000 ipsets."
echo "This will take 20 seconds." # K8s API-server might nag about too many entries at once.
RULES=`ls rules`
for entry in $RULES
do
  kubectl apply -f rules/$entry
  sleep 2
done

RULES=$(kubectl get cnp -n $NAMESPACE | wc -l)

echo "Running 5 benchmark/s with $RULES rules."
for I in {1..5}
  do
    ./knb -cn $CN -sn $SN -m $MULTI -p $PARALLEL -n $NAMESPACE -o data -f "results/$PREFIX-$RULES-rules-$I.knbdata"
    echo "Benchmark $I is done, Waiting for the clean up ..."
    while [ $(kubectl get pods -n $NAMESPACE | wc -l) != "0" ]
    do
      sleep 60
    done
done

echo "Cleaning up rules"
kubectl delete -f rules
kubectl delete ns $NAMESPACE

# I'm done!
echo "checkout the results folder!"
