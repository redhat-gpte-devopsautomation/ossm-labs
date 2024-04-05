#!/bin/bash

LAB_PARTICIPANT_ID=$1
SM_JAEGER_RESOURCE=$LAB_PARTICIPANT_ID-jaeger-small-production
SM_CP_NS=$LAB_PARTICIPANT_ID-prod-istio-system
SM_TENANT_NAME=$LAB_PARTICIPANT_ID-production


echo '---------------------------------------------------------------------------'
echo 'ServiceMesh Namespace                       : '$SM_CP_NS
echo 'ServiceMesh Control Plane Tenant Name       : '$SM_TENANT_NAME
echo 'ServiceMesh Jaeger Production Resource Name : '$SM_JAEGER_RESOURCE
echo '---------------------------------------------------------------------------'

echo
echo
echo "############# Update SM Tenant [$SM_TENANT_NAME] in Namespace [$SM_CP_NS ] to remove OSSM monitoring stack #############"

sleep 4

echo "apiVersion: maistra.io/v2
kind: ServiceMeshControlPlane
metadata:
  name: $SM_TENANT_NAME
spec:
  security:
    dataPlane:
      automtls: true
      mtls: true
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
    dataPlane:
      automtls: true
      mtls: true
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

sleep 6

echo
echo
echo
echo "############# Integrate SM Tenant [$SM_TENANT_NAME] with OCP user-workload monitoring #############"


echo "kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: istio-kiali-ingress
  namespace: $SM_CP_NS
spec:
  podSelector:
    matchLabels:
      app: kiali
  ingress:
    - {}
  policyTypes:
    - Ingress" |oc apply -f -

echo "apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: user-workload-access
  namespace: $LAB_PARTICIPANT_ID-prod-travel-control
spec:
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          network.openshift.io/policy-group: monitoring
  podSelector: {}
  policyTypes:
  - Ingress" |oc apply -f -


echo "apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: user-workload-access
  namespace: $LAB_PARTICIPANT_ID-prod-travel-portal
spec:
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          network.openshift.io/policy-group: monitoring
  podSelector: {}
  policyTypes:
  - Ingress" |oc apply -f -


echo "apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: user-workload-access
  namespace: $LAB_PARTICIPANT_ID-prod-travel-agency
spec:
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          network.openshift.io/policy-group: monitoring
  podSelector: {}
  policyTypes:
  - Ingress"   |oc apply -f -


echo "kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: prometheus-monitoring-exporter-istio-system
rules:
  - verbs:
      - get
      - list
      - watch
    apiGroups:
      - ''
    resources:
      - namespaces"   |oc apply -f -

echo "apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kiali-prometheus-monitoring-exporter-istio-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: prometheus-monitoring-exporter-istio-system
subjects:
- kind: ServiceAccount
  name: kiali-service-account
  namespace: $SM_CP_NS"   |oc apply -f -

echo "apiVersion: kiali.io/v1alpha1
kind: Kiali
metadata:
  name: kiali-user-workload-monitoring
  namespace: $SM_CP_NS
  labels:
    app.kubernetes.io/part-of: istio
    app.kubernetes.io/instance: $SM_CP_NS
    maistra.io/owner-name: $SM_TENANT_NAME
    app.kubernetes.io/version: 2.5.0-1-2
    app.kubernetes.io/component: kiali
    #maistra-version: 2.5.0
    maistra.io/owner: $SM_CP_NS
    app.kubernetes.io/name: kiali
spec:
  api:
    namespaces:
      exclude: []
  auth:
    strategy: openshift
  deployment:
    accessible_namespaces:
      - $LAB_PARTICIPANT_ID-prod-travel-control
      - $LAB_PARTICIPANT_ID-prod-travel-portal
      - $LAB_PARTICIPANT_ID-prod-travel-agency
    image_pull_policy: ''
    ingress:
      enabled: true
    namespace: $SM_CP_NS
    pod_labels:
      sidecar.istio.io/inject: 'false'
    resources:
      requests:
        cpu: 100m
        memory: 256Mi
    logger:
      log_level: debug
  external_services:
#    custom_dashboards:
#      namespace_label: kubernetes_namespace
#    grafana:
#      auth:
#        password:
#        type: basic
#        use_kiali_token: false
#        username: internal
#      enabled: true
#      in_cluster_url: 'https://grafana.$SM_CP_NS.svc:3000'
#      url: 'https://grafana-$SM_CP_NS.apps.july26.vqqh.p1.openshiftapps.com'
    istio:
      config_map_name: istio-$SM_TENANT_NAME
      istio_sidecar_injector_config_map_name: istio-sidecar-injector-$SM_TENANT_NAME
      istiod_deployment_name: istiod-$SM_TENANT_NAME
      url_service_version: 'http://istiod-$SM_TENANT_NAME.$SM_CP_NS:15014/version'
    prometheus:
      auth:
#        token: secret:thanos-querier-web-token:token
        insecure_skip_verify: true
        type: bearer
        use_kiali_token: true
      query_scope:
#        mesh_id: $SM_CP_NS/$SM_TENANT_NAME
        mesh_id: $SM_TENANT_NAME-$SM_CP_NS
      thanos_proxy:
        enabled: true
      url: https://thanos-querier.openshift-monitoring.svc.cluster.local:9091
    tracing:
      auth:
        password:
        type: basic
        use_kiali_token: false
        username: internal
      enabled: true
      in_cluster_url: 'https://$SM_JAEGER_RESOURCE-query.svc'
      namespace: $SM_CP_NS
      service: ''
      use_grpc: false
  installation_tag: 'Kiali [$SM_CP_NS'
  istio_namespace: $SM_CP_NS
  version: v1.73"   |oc apply -f -

echo "apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: istio-proxies-monitor
  namespace: $LAB_PARTICIPANT_ID-prod-travel-control
spec:
  selector:
    matchExpressions:
    - key: istio-prometheus-ignore
      operator: DoesNotExist
  podMetricsEndpoints:
  - path: /stats/prometheus
    interval: 30s
    relabelings:
    - action: keep
      sourceLabels: [__meta_kubernetes_pod_container_name]
      regex: \"istio-proxy\"
    - action: keep
      sourceLabels: [__meta_kubernetes_pod_annotationpresent_prometheus_io_scrape]
    - action: replace
      regex: \"(\d+);(([A-Fa-f0-9]{1,4}::?){1,7}[A-Fa-f0-9]{1,4})\"
      replacement: \'[$2]:$1\'
      sourceLabels: [__meta_kubernetes_pod_annotation_prometheus_io_port,
      __meta_kubernetes_pod_ip]
      targetLabel: __address__
    - action: replace
      regex: (\d+);((([0-9]+?)(\.|$)){4})
      replacement: $2:$1
      sourceLabels: [__meta_kubernetes_pod_annotation_prometheus_io_port,
      __meta_kubernetes_pod_ip]
      targetLabel: __address__
    - action: labeldrop
      regex: \"__meta_kubernetes_pod_label_(.+)\"
    - sourceLabels: [__meta_kubernetes_namespace]
      action: replace
      targetLabel: namespace
    - sourceLabels: [__meta_kubernetes_pod_name]
      action: replace
      targetLabel: pod_name
    - action: replace
      replacement: $SM_TENANT_NAME-$SM_CP_NS
      targetLabel: mesh_id'   |oc apply -f -

echo 'apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: istio-proxies-monitor
  namespace: $LAB_PARTICIPANT_ID-prod-travel-portal
spec:
  selector:
    matchExpressions:
    - key: istio-prometheus-ignore
      operator: DoesNotExist
  podMetricsEndpoints:
  - path: /stats/prometheus
    interval: 30s
    relabelings:
    - action: keep
      sourceLabels: [__meta_kubernetes_pod_container_name]
      regex: "istio-proxy"
    - action: keep
      sourceLabels: [__meta_kubernetes_pod_annotationpresent_prometheus_io_scrape]
    - action: replace
      regex: (\d+);(([A-Fa-f0-9]{1,4}::?){1,7}[A-Fa-f0-9]{1,4})
      replacement: '[$2]:$1'
      sourceLabels: [__meta_kubernetes_pod_annotation_prometheus_io_port,
      __meta_kubernetes_pod_ip]
      targetLabel: __address__
    - action: replace
      regex: (\d+);((([0-9]+?)(\.|$)){4})
      replacement: $2:$1
      sourceLabels: [__meta_kubernetes_pod_annotation_prometheus_io_port,
      __meta_kubernetes_pod_ip]
      targetLabel: __address__
    - action: labeldrop
      regex: "__meta_kubernetes_pod_label_(.+)"
    - sourceLabels: [__meta_kubernetes_namespace]
      action: replace
      targetLabel: namespace
    - sourceLabels: [__meta_kubernetes_pod_name]
      action: replace
      targetLabel: pod_name
    - action: replace
      replacement: $SM_TENANT_NAME-$SM_CP_NS
      targetLabel: mesh_id'   |oc apply -f -

echo 'apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: istio-proxies-monitor
  namespace: $LAB_PARTICIPANT_ID-prod-travel-agency
spec:
  selector:
    matchExpressions:
    - key: istio-prometheus-ignore
      operator: DoesNotExist
  podMetricsEndpoints:
  - path: /stats/prometheus
    interval: 30s
    relabelings:
    - action: keep
      sourceLabels: [__meta_kubernetes_pod_container_name]
      regex: "istio-proxy"
    - action: keep
      sourceLabels: [__meta_kubernetes_pod_annotationpresent_prometheus_io_scrape]
    - action: replace
      regex: (\d+);(([A-Fa-f0-9]{1,4}::?){1,7}[A-Fa-f0-9]{1,4})
      replacement: '[$2]:$1'
      sourceLabels: [__meta_kubernetes_pod_annotation_prometheus_io_port,
      __meta_kubernetes_pod_ip]
      targetLabel: __address__
    - action: replace
      regex: (\d+);((([0-9]+?)(\.|$)){4})
      replacement: $2:$1
      sourceLabels: [__meta_kubernetes_pod_annotation_prometheus_io_port,
      __meta_kubernetes_pod_ip]
      targetLabel: __address__
    - action: labeldrop
      regex: "__meta_kubernetes_pod_label_(.+)"
    - sourceLabels: [__meta_kubernetes_namespace]
      action: replace
      targetLabel: namespace
    - sourceLabels: [__meta_kubernetes_pod_name]
      action: replace
      targetLabel: pod_name
    - action: replace
      replacement: $SM_TENANT_NAME-$SM_CP_NS
      targetLabel: mesh_id'   |oc apply -f -

echo 'apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: istio-proxies-monitor
  namespace: $LAB_PARTICIPANT_ID-prod-istio-system
spec:
  selector:
    matchExpressions:
    - key: istio-prometheus-ignore
      operator: DoesNotExist
  podMetricsEndpoints:
  - path: /stats/prometheus
    interval: 30s
    relabelings:
    - action: keep
      sourceLabels: [__meta_kubernetes_pod_container_name]
      regex: "istio-proxy"
    - action: keep
      sourceLabels: [__meta_kubernetes_pod_annotationpresent_prometheus_io_scrape]
    - action: replace
      regex: (\d+);(([A-Fa-f0-9]{1,4}::?){1,7}[A-Fa-f0-9]{1,4})
      replacement: '[$2]:$1'
      sourceLabels: [__meta_kubernetes_pod_annotation_prometheus_io_port,
      __meta_kubernetes_pod_ip]
      targetLabel: __address__
    - action: replace
      regex: (\d+);((([0-9]+?)(\.|$)){4})
      replacement: $2:$1
      sourceLabels: [__meta_kubernetes_pod_annotation_prometheus_io_port,
      __meta_kubernetes_pod_ip]
      targetLabel: __address__
    - action: labeldrop
      regex: "__meta_kubernetes_pod_label_(.+)"
    - sourceLabels: [__meta_kubernetes_namespace]
      action: replace
      targetLabel: namespace
    - sourceLabels: [__meta_kubernetes_pod_name]
      action: replace
      targetLabel: pod_name
    - action: replace
      replacement: $SM_TENANT_NAME-$SM_CP_NS
      targetLabel: mesh_id'   |oc apply -f -

echo "apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: istiod-monitor
  namespace: $SM_CP_NS
spec:
  targetLabels:
  - app
  selector:
    matchLabels:
      istio: pilot
  endpoints:
  - port: http-monitoring
    interval: 30s
    relabelings:
    - action: replace
      replacement: $SM_TENANT_NAME-$SM_CP_NS
      targetLabel: mesh_id"   |oc apply -f -

echo "apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: enable-prometheus-metrics
  namespace: $SM_CP_NS
spec:
  metrics:
  - providers:
    - name: prometheus"   |oc apply -f -