# network policy - inlude

function np_cleanup()
{
    separ
    echo "Namespace cleanup"
    kubectl delete pod -n networkpolicy-ns np-client-pod
    kubectl delete deployment -n networkpolicy-ns nginx-depl
    kubectl delete namespace networkpolicy-ns  
    echo Network policy cleanup done 
}

echo "Execing network policy, creating two PODs, communication allowed"

echo "Creating dedicated namespace"
separ
kubectl apply -f ./np-dedicated-namespace.yaml || exit 1
kubectl get namespace

# this is debut deployment
#kubectl apply -f ./np-depl-2busyboxes.yaml || exit 1

separ
echo "Creating nginx POD"
kubectl apply -f ./np-depl-nginx.yaml || exit 1
echo Waiting for startup 60s ...
A_POD=$(kubectl get pods -n networkpolicy-ns | grep nginx-depl|cut -f1 -d' ')
if [[ -z ${A_POD} ]] ; then
    echo $0 error: POD not found in namespace networkpolicy-ns: kubectl get pods -n networkpolicy-ns
    kubectl get pods -n networkpolicy-ns
    np_cleanup
    exit 1
fi
kubectl wait --for=condition=Ready pod/${A_POD} -n networkpolicy-ns --timeout=60s
if [[ $? != "0" ]] ; then
    echo $0 error: POD not started within 1minute, PROXY?
    np_cleanup
    exit 1
fi
kubectl get pods -n networkpolicy-ns -o wide 
cp ./np-client.yaml ./np-client-edited.yaml || exit 1

echo "Deploying busybox to connect to nginx ..."
NODE_IP=$(kubectl get pods -n networkpolicy-ns -o wide | grep nginx-depl|awk '{print $6}')
if [[ -z ${NODE_IP} ]] ; then
    echo $0 error: problem get NODE_IP, kubectl get pods -n networkpolicy-ns -o wide
    kubectl get pods -n networkpolicy-ns
    np_cleanup
    exit 1
fi
echo Using node ip ${NODE_IP}
sed -i "s/IP_GOES_HERE/$NODE_IP/" ./np-client-edited.yaml || exit 1
kubectl apply -f ./np-client-edited.yaml || exit 1
echo Waiting to start POD client, then show logs of licnet POD
kubectl wait --for=condition=Ready pod/np-client-pod -n networkpolicy-ns --timeout=60s || exit 1
separ running pods

kubectl get pods -n networkpolicy-ns -o wide
kubectl logs -n networkpolicy-ns np-client-pod | tail -200

separ Before network policy apply

np_cleanup