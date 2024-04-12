#!/bin/bash

SM_CP_NS=$1
SM_TENANT_NAME=$2
SM_JAEGER_RESOURCE=$3

echo '---------------------------------------------------------------------------'
echo 'ServiceMesh Namespace                       : '$SM_CP_NS
echo 'ServiceMesh Control Plane Tenant Name       : '$SM_TENANT_NAME
echo 'ServiceMesh Jaeger Production Resource Name : '$SM_JAEGER_RESOURCE
echo '---------------------------------------------------------------------------'


echo
sleep 10
echo "############# Updating SM Tenant [$SM_TENANT_NAME] in Namespace [$SM_CP_NS ] #############"
echo "apiVersion: maistra.io/v2
kind: ServiceMeshControlPlane
metadata:
  name: $SM_TENANT_NAME
spec:
  security:
    controlPlane:
      mtls: true
    certificateAuthority:
      cert-manager:
        address: 'cert-manager-istio-csr.$SM_CP_NS.svc:443'
      type: cert-manager
    dataPlane:
      automtls: true
      mtls: true
    identity:
      type: ThirdParty
  tracing:
    sampling: 500
    type: Jaeger
  general:
    logging:
      logAsJSON: true
  profiles:
    - default
  proxy:
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 500m
        memory: 128Mi
    accessLogging:
      file:
        name: /dev/stdout
    networking:
      trafficControl:
        inbound: {}
        outbound:
          policy: REGISTRY_ONLY
  gateways:
    egress:
      enabled: true
      runtime:
        deployment:
          autoScaling:
            enabled: true
            maxReplicas: 2
            minReplicas: 2
        pod: {}
      service: {}
    enabled: true
    ingress:
      enabled: true
      runtime:
        deployment:
          autoScaling:
            enabled: true
            maxReplicas: 2
            minReplicas: 2
        pod: {}
      service: {}
    openshiftRoute:
      enabled: false
  policy:
    type: Istiod
  addons:
    grafana:
      enabled: false
    jaeger:
      install:
        ingress:
          enabled: true
        storage:
          type: Elasticsearch
      name: $SM_JAEGER_RESOURCE
    kiali:
      name: kiali-user-workload-monitoring
    prometheus:
      enabled: false
  runtime:
    components:
      pilot:
        deployment:
          replicas: 2
        pod:
          affinity: {}
        container:
          resources:
          limits: {}
          requirements: {}
      grafana:
        deployment: {}
        pod: {}
      kiali:
        deployment: {}
        pod: {}
  version: v2.5
  telemetry:
    type: Istiod"

echo "apiVersion: maistra.io/v2
kind: ServiceMeshControlPlane
metadata:
  name: $SM_TENANT_NAME
spec:
  security:
    controlPlane:
      mtls: true
    certificateAuthority:
      cert-manager:
        address: 'cert-manager-istio-csr.$SM_CP_NS.svc:443'
      type: cert-manager
    dataPlane:
      automtls: true
      mtls: true
    identity:
      type: ThirdParty
  tracing:
    sampling: 500
    type: Jaeger
  general:
    logging:
      logAsJSON: true
  profiles:
    - default
  proxy:
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 500m
        memory: 128Mi
    accessLogging:
      file:
        name: /dev/stdout
    networking:
      trafficControl:
        inbound: {}
        outbound:
          policy: REGISTRY_ONLY
  gateways:
    egress:
      enabled: true
      runtime:
        deployment:
          autoScaling:
            enabled: true
            maxReplicas: 2
            minReplicas: 2
        pod: {}
      service: {}
    enabled: true
    ingress:
      enabled: true
      runtime:
        deployment:
          autoScaling:
            enabled: true
            maxReplicas: 2
            minReplicas: 2
        pod: {}
      service: {}
    openshiftRoute:
      enabled: false
  policy:
    type: Istiod
  addons:
    grafana:
      enabled: false
    jaeger:
      install:
        ingress:
          enabled: true
        storage:
          type: Elasticsearch
      name: $SM_JAEGER_RESOURCE
    kiali:
      name: kiali-user-workload-monitoring
    prometheus:
      enabled: false
  runtime:
    components:
      pilot:
        deployment:
          replicas: 2
        pod:
          affinity: {}
        container:
          resources:
          limits: {}
          requirements: {}
      grafana:
        deployment: {}
        pod: {}
      kiali:
        deployment: {}
        pod: {}
  version: v2.5
  telemetry:
    type: Istiod"| oc apply -n $SM_CP_NS -f -

sleep 3
echo
echo
echo "oc wait --for condition=Ready -n $SM_CP_NS smcp/$SM_TENANT_NAME --timeout=300s"
echo
echo
oc wait --for condition=Ready -n $SM_CP_NS smcp/$SM_TENANT_NAME --timeout=300s
echo
echo
oc -n $SM_CP_NS  get smcp/$SM_TENANT_NAME

travelurl=https://$(oc get route travel -o jsonpath='{.spec.host}' -n $SM_CP_NS)
kialiurl=https://$(oc get route kiali -o jsonpath='{.spec.host}' -n $SM_CP_NS)

echo "============================================================================================================================================"
echo "Check that the Travel Dashboard is accessible at the secured $travelurl"
echo "Login at $kialiurl as emma/emma and verify the App Graph shows traffic via istio-ingress gateway"
echo "============================================================================================================================================"
