#!/bin/bash
if ! command -v kubectl &> /dev/null
then
    echo "kubectl could not be found"
    exit
fi

if ! command -v calicoctl &> /dev/null
then
    echo "calicoctl could not be found."
    echo "checkout https://docs.projectcalico.org/archive/v3.20/getting-started/clis/calicoctl/install"
    exit
fi

CN="multistream-worker"
SN="multistream-worker2"
PREFIX=$(kubectl get installation.operator.tigera.io default -o jsonpath='{.spec.calicoNetwork.linuxDataplane}')
# MODE=$(kubectl get felixconfiguration default -o jsonpath='{.spec.bpfExternalServiceMode}'
MULTI="2"
PARALLEL="2"
NAMESPACE="calico-test"
RULES=$(kubectl get GlobalNetworkSet | wc -l)

# Making sure test namespace exists
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: $NAMESPACE
EOF

echo "Calico is using $PREFIX dataplane."
# Run bunch of benchmarks for a better result?
for I in {1..5}
  do
    echo "Benchmark $I with $RULES rules."
    ./knb -v -cn $CN -sn $SN -m $MULTI -P $PARALLEL -n $NAMESPACE -o data -f "results/$PREFIX-$RULES-rules-$I.knbdata"
    echo "Benchmark $I is done, Waiting for the clean up ..."
    while [ $(kubectl get pods -n $NAMESPACE | wc -l) != "0" ]
    do
      sleep 60
    done
done

echo "Importing 100 security to block 100,000 ips."
calicoctl apply -f rules

calicoctl apply -f - <<EOF
apiVersion: projectcalico.org/v3
kind: GlobalNetworkPolicy
metadata:
  name: allow-egress
spec:
  selector: projectcalico.org/namespace == "$NAMESPACE"
  order: 1000
  types:
  - Egress
  egress:
  - action: Allow
---
apiVersion: projectcalico.org/v3
kind: GlobalNetworkPolicy
metadata:
  name: deny-egress
spec:
  selector: projectcalico.org/namespace == "$NAMESPACE"
  order: 0
  types:
  - Egress
  egress:
  - action: Deny
    destination: 
      selector: IP-deny-list == 'true'
EOF

RULES=$(kubectl GlobalNetworkSet | wc -l)

echo "Running 5 benchmark/s with $RULES rules."
for I in {1..5}
  do
    echo "Benchmark $I with $RULES rules."
    ./knb -v -cn $CN -sn $SN -m $MULTI -P $PARALLEL -n $NAMESPACE -o data -f "results/$PREFIX-$RULES-rules-$I.knbdata"
    echo "Benchmark $I is done, Waiting for the clean up ..."
    while [ $(kubectl get pods -n $NAMESPACE | wc -l) != "0" ]
    do
      sleep 60
    done
done

echo "Cleaning up rules"
calicoctl delete -f rules
calicoctl delete gnp allow-egress deny-egress
kubectl delete ns $NAMESPACE

# I'm done!
echo "checkout the results folder!"
