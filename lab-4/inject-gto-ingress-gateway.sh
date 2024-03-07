#!/bin/bash

#SM_CP_NS_ORIGINAL=$1
TRAVEL_AGENCY_NS_ORIGINAL=$1 #eg. prod-travel-agency
DOMAIN_NAME=$2
PARTICIPANTID=$3

PREFIX=gto-$PARTICIPANTID
#SM_CP_NS=$PARTICIPANTID-$SM_CP_NS_ORIGINAL
TA_NS=$PARTICIPANTID-$TRAVEL_AGENCY_NS_ORIGINAL

echo '---------------------------------------------------------------------------'
echo 'Travel Agency Data Plane  Namespace        : '$TA_NS
echo 'CLUSTER DOMAIN Name                        : '$DOMAIN_NAME
echo 'PREFIX                                     : '$PREFIX
echo 'Remote SMCP Route Name (when NO DNS)       : 'https://$PREFIX.$DOMAIN_NAME
echo '---------------------------------------------------------------------------'

sleep 10
echo
echo "================================================================================="
echo "Create new Injected Gateway ($PREFIX) in dataplane namespace ($TA_NS)"
echo "================================================================================="

echo "Create Service ($PREFIX-ingressgateway)"
echo "-------------------------------------------------------"
echo "apiVersion: v1
kind: Service
metadata:
  name: $PREFIX-ingressgateway
  namespace: $TA_NS
spec:
  type: ClusterIP
  selector:
    gw: $PREFIX-injection
  ports:
  - name: http2
    port: 80
    targetPort: 8080
  - name: https
    port: 443
    targetPort: 8443"

echo "apiVersion: v1
kind: Service
metadata:
  name: $PREFIX-ingressgateway
  namespace: $TA_NS
spec:
  type: ClusterIP
  selector:
    gw: $PREFIX-injection
  ports:
  - name: http2
    port: 80
    targetPort: 8080
  - name: https
    port: 443
    targetPort: 8443" | oc apply -n $TA_NS -f -

echo
sleep 5

echo "Create Deployment ($PREFIX-ingressgateway)"
echo "-------------------------------------------------------"
echo "apiVersion: apps/v1
kind: Deployment
metadata:
  name: $PREFIX-ingressgateway
  namespace: $TA_NS
spec:
  selector:
    matchLabels:
      gw: $PREFIX-injection
  template:
    metadata:
      annotations:
        inject.istio.io/templates: gateway
      labels:
        gw: $PREFIX-injection
        app: $PREFIX-ingressgateway
        sidecar.istio.io/inject: \"true\"
    spec:
      containers:
      - name: istio-proxy
        image: auto
        ports:
        - containerPort: 8080
          name: http2
          protocol: TCP
        - containerPort: 8443
          name: https
          protocol: TCP"

echo "apiVersion: apps/v1
kind: Deployment
metadata:
  name: $PREFIX-ingressgateway
  namespace: $TA_NS
spec:
  selector:
    matchLabels:
      gw: $PREFIX-injection
  template:
    metadata:
      annotations:
        inject.istio.io/templates: gateway
      labels:
        gw: $PREFIX-injection
        app: $PREFIX-ingressgateway
        sidecar.istio.io/inject: \"true\"
    spec:
      containers:
      - name: istio-proxy
        image: auto
        ports:
        - containerPort: 8080
          name: http2
          protocol: TCP
        - containerPort: 8443
          name: https
          protocol: TCP" | oc apply -n $TA_NS -f -

echo
sleep 5

echo "Create Role ($PREFIX-ingressgateway-sds)"
echo "-------------------------------------------------------"
echo "apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: $PREFIX-ingressgateway-sds
  namespace: $TA_NS
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["get", "watch", "list"]"

echo "apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: $PREFIX-ingressgateway-sds
  namespace: $TA_NS
rules:
  - apiGroups: [\"\"]
    resources: ["secrets"]
    verbs: ["get", "watch", "list"]" | oc apply -n $TA_NS -f -

echo
sleep 5


echo "Create Rolebinding ($PREFIX-ingressgateway-sds)"
echo "-------------------------------------------------------"
echo "apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: $PREFIX-ingressgateway-sds
  namespace: $TA_NS
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: $PREFIX-ingressgateway-sds
subjects:
- kind: ServiceAccount
  name: default"

echo "apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: $PREFIX-ingressgateway-sds
  namespace: $TA_NS
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: $PREFIX-ingressgateway-sds
subjects:
- kind: ServiceAccount
  name: default" | oc apply -n $TA_NS -f -

echo
sleep 5

echo "Create NetworkPolicy ($PREFIX-ingressgateway)"
echo "-------------------------------------------------------"
echo "apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: $PREFIX-ingressgateway
  namespace: $TA_NS
spec:
  podSelector:
    matchLabels:
      gw: $PREFIX-injection
  ingress:
    - {}
  policyTypes:
  - Ingress"

echo "apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: $PREFIX-ingressgateway
  namespace: $TA_NS
spec:
  podSelector:
    matchLabels:
      gw: $PREFIX-injection
  ingress:
    - {}
  policyTypes:
  - Ingress" | oc apply -n $TA_NS -f -

echo
sleep 5


echo "Setup $PREFIX-ingressgateway Gateway PODs scaling"
echo "-------------------------------------------------------"
#Automatically scale the pod when ingress traffic increases. This example sets the minimum replicas to 2 and the maximum replicas to 3. It also creates another replica when utilization reaches 80%.
echo "apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  labels:
    gw: $PREFIX-injection
    release: istio
  name: $PREFIX-ingressgatewayhpa
  namespace: $TA_NS
spec:
  maxReplicas: 3
  metrics:
  - resource:
      name: cpu
      target:
        averageUtilization: 80
        type: Utilization
    type: Resource
  minReplicas: 2
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: $PREFIX-ingressgateway"

echo "apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  labels:
    gw: $PREFIX-injection
    release: istio
  name: $PREFIX-ingressgatewayhpa
  namespace: $TA_NS
spec:
  maxReplicas: 3
  metrics:
  - resource:
      name: cpu
      target:
        averageUtilization: 80
        type: Utilization
    type: Resource
  minReplicas: 2
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: $PREFIX-ingressgateway" | oc apply -n $TA_NS -f -

echo
sleep 5

echo "Setup $PREFIX-ingressgateway Disruption"
echo "-------------------------------------------------------"
#Specify the minimum number of pods that must be running on the node. This example ensures one replica is running if a pod gets restarted on a new node.
echo "apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  labels:
    gw: $PREFIX-injection
    release: istio
  name: $PREFIX-ingressgatewaypdb
  namespace: $TA_NS
spec:
  minAvailable: 1
  selector:
    matchLabels:
      gw: $PREFIX-injection"

echo "apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  labels:
    gw: $PREFIX-injection
    release: istio
  name: $PREFIX-ingressgatewaypdb
  namespace: $TA_NS
spec:
  minAvailable: 1
  selector:
    matchLabels:
      gw: $PREFIX-injection" | oc apply -n $TA_NS -f -

echo
sleep 5
