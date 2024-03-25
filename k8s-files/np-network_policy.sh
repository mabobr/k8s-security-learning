# network policy - inlude

function np_cleanup()
{
    separ kubectl delete namespace networkpolicy-ns
    kubectl delete namespace networkpolicy-ns  
    echo Network policy cleanup done 
}

echo "Execing network policy, creating two PODs, communication allowed"

separ kubectl apply -f ./np-dedicated-namespace.yaml
kubectl apply -f ./np-dedicated-namespace.yaml || exit 1
kubectl get namespace

# this is debut deployment
#kubectl apply -f ./np-depl-2busyboxes.yaml || exit 1

separ Creating nginx POD: kubectl apply -f ./np-depl-nginx.yaml
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
cp ./np-busybox-w-curl.yaml ./np-busybox-w-curl-edited.yaml || exit 1

separ Deploying busybox POD to connect to nginx
NODE_IP=$(kubectl get pods -n networkpolicy-ns -o wide | grep nginx-depl|awk '{print $6}')
if [[ -z ${NODE_IP} ]] ; then
    echo $0 error: problem get NODE_IP, kubectl get pods -n networkpolicy-ns -o wide
    kubectl get pods -n networkpolicy-ns
    np_cleanup
    exit 1
fi
echo Using node ip ${NODE_IP}
sed -i "s/IP_GOES_HERE/$NODE_IP/" ./np-busybox-w-curl-edited.yaml || exit 1
kubectl apply -f ./np-busybox-w-curl-edited.yaml || exit 1
echo Waiting to start POD client, then show logs of client POD ...
kubectl wait --for=condition=Ready pod/np-busybox-w-curl -n networkpolicy-ns --timeout=60s || exit 1
echo All PODs rae erady

kubectl get pods -n networkpolicy-ns -o wide
kubectl logs -n networkpolicy-ns np-busybox-w-curl | tail -200
separ No policy applied yet, above must be successfull communication

kubectl apply -f ./np-deny-all-network-policy.yaml || exit 1
sleep 5
echo After network policy application logs will show failures:
kubectl logs -n networkpolicy-ns np-busybox-w-curl | tail -200
echo Now, will keep default DENY policy but will add ingress and egress policy to allow commincation.
kubectl apply -f ./np-policy-client-2-nginx.yaml || exit 1
kubectl apply -f ./np-policy-allow-ingress-nginx.yaml|| exit 1

sleep 2
echo Listing applies policies:
kubectl get NetworkPolicy -n networkpolicy-ns -o wide 
echo But connection is not allowed - condition about project label is not met:

for i in {1..5}
do
    date
    kubectl logs -n networkpolicy-ns np-busybox-w-curl | tail -20
    sleep 2
done

separ  Now labling whole namespace for all network policy to be met: kubectl label namespace networkpolicy-ns project=mb-test
kubectl label namespace networkpolicy-ns project=mb-test || exit 1
separ Connection should be allowed now
for i in {1..5}
do
    date
    kubectl logs -n networkpolicy-ns np-busybox-w-curl | tail -20
    sleep 2
done

np_cleanup