#!/bin/bash

LAB_PARTICIPANT_ID=$1
SM_JAEGER_RESOURCE=$LAB_PARTICIPANT_ID-jaeger-small-production
SM_CP_NS=$LAB_PARTICIPANT_ID-prod-istio-system
SM_TENANT_NAME=$LAB_PARTICIPANT_ID-production


echo '---------------------------------------------------------------------------'
echo 'LAB_PARTICIPANT_ID                       : 'LAB_PARTICIPANT_ID
echo '---------------------------------------------------------------------------'
sleep 2



echo "############# PodMonitor applied in $LAB_PARTICIPANT_ID-prod-istio-system namespace #############"
echo
sed 's@USERX@LAB_PARTICIPANT_ID@g; s@SMNAMESPACE@istio-system@g' pod-monitor.yaml > podmonitor-istio-system.yaml
cat podmonitor-istio-system.yaml

sleep 5
oc apply -f podmonitor-istio-system.yaml



echo
echo
echo "############# PodMonitor applied in $LAB_PARTICIPANT_ID-prod-travel-control namespace #############"
echo
sed 's@USERX@LAB_PARTICIPANT_ID@g; s@SMNAMESPACE@travel-control@g' pod-monitor.yaml > podmonitor-travel-control.yaml
cat podmonitor-travel-control.yaml

sleep 5
oc apply -f podmonitor-travel-control.yaml

echo
echo
echo "############# PodMonitor applied in $LAB_PARTICIPANT_ID-prod-travel-portal namespace #############"
echo
sed 's@USERX@LAB_PARTICIPANT_ID@g; s@SMNAMESPACE@travel-portal@g' pod-monitor.yaml > podmonitor-travel-portal.yaml
cat podmonitor-travel-portal.yaml

sleep 5
oc apply -f podmonitor-travel-portal.yaml

echo
echo
echo "############# PodMonitor applied in $LAB_PARTICIPANT_ID-prod-travel-agency namespace #############"
echo
sed 's@USERX@LAB_PARTICIPANT_ID@g; s@SMNAMESPACE@travel-agency@g' pod-monitor.yaml > podmonitor-travel-agency.yaml
cat podmonitor-travel-agency.yaml

sleep 5
oc apply -f podmonitor-travel-agency.yaml