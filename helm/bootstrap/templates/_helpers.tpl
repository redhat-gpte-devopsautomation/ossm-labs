{{- define "usertool.labExtraUrls" }}
{{- $domain := .Values.agnosticd.domain }}
{{- $consoleUrl := printf "https://console-openshift-console.%s;OpenShift Console" $domain }}
{{- $kialiUrl := printf "https://kiali-%%USERNAME%%-dev-istio-system.%s;Kiali" $domain }}
{{- $codeServer := printf "https://codeserver-codeserver-%%USERNAME%%.%s;Code Server" $domain }}
{{- $assertsUrl := printf "https://github.com/skoussou/summit-2023-ossm-labs/;Labs Asset Repository" }}
{{- $urls := list $consoleUrl $codeServer $assertsUrl }}
{{- join "," $urls }}
{{- end }}

{{- define "usertool.labModuleUrls" }}
{{- $domain := .Values.agnosticd.domain }}
{{- $apiUrl := .Values.agnosticd.apiUrl }}
{{- $params := printf "?LAB_PARTICIPANT_ID=%%USERNAME%%&OCP_DOMAIN=%s&API_URL=%s" $domain $apiUrl }}
{{- $module1 := printf "https://guides-guides.%s/summit-ossm-labs-guides/main/intro/intro.html%s;Travel Demo Use Case Introduction" $domain $params }}
{{- $module1 := printf "https://guides-guides.%s/summit-ossm-labs-guides/main/m1/intro.html%s;Designing a Service Mesh" $domain $params }}
{{- $module2 := printf "https://guides-guides.%s/summit-ossm-labs-guides/main/m2/intro.html%s;Using the Observability Stack" $domain $params }}
{{- $module3 := printf "https://guides-guides.%s/summit-ossm-labs-guides/main/m3/intro.html%s;Setting up a Production Environment" $domain $params }}
{{- $module4 := printf "https://guides-guides.%s/summit-ossm-labs-guides/main/m4/intro.html%s;Applying Authz and Authn" $domain $params }}
{{- $module5 := printf "https://guides-guides.%s/summit-ossm-labs-guides/main/m5/intro.html%s;Hardening the Production Setup" $domain $params }}
{{- $module6 := printf "https://guides-guides.%s/summit-ossm-labs-guides/main/m6/intro.html%s;Service Mesh Day 2 Operations" $domain $params }}

{{- $urls := list $module1 $module2 $module3 $module4 $module5 $module6}}
{{- join "," $urls }}
{{- end }}
