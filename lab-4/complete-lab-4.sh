#!/bin/bash

SSO_CLIENT_SECRET=$1
OCP_DOMAIN=$2 #apps.cluster-w4h2j.w4h2j.sandbox2385.opentlc.com
LAB_PARTICIPANT_ID=$3


SM_TENANT_NAME=$LAB_PARTICIPANT_ID-production
SM_CP_NS=$LAB_PARTICIPANT_ID-prod-istio-system
SM_JAEGER_RESOURCE=$LAB_PARTICIPANT_ID-jaeger-small-production

echo
echo "---Values Used-----------------------------------------------"
echo "OCP_DOMAIN:            $OCP_DOMAIN"
echo "LAB_PARTICIPANT_ID:    $LAB_PARTICIPANT_ID"
echo "SM_TENANT_NAME:        $SM_TENANT_NAME"
echo "SM_CP_NS:              $SM_CP_NS"
echo "SM_JAEGER_RESOURCE:    $SM_JAEGER_RESOURCE"
echo "-------------------------------------------------------------"
set -e

oc project $SM_CP_NS
sleep 5

echo
echo "Task 2: External API integration with Injected Gateway & mTLS"
echo "#############################################################"
echo
echo
sleep 3

./login-as.sh farid

echo ""

./inject-gto-ingress-gateway.sh prod-travel-agency $OCP_DOMAIN $LAB_PARTICIPANT_ID

sleep 5

echo "############# Verify the creation of the additional gateway gto in SM Tenant [$SM_TENANT_NAME] in Namespace [$LAB_PARTICIPANT_ID-prod-travel-agency ] #############"

oc get pods -n $LAB_PARTICIPANT_ID-prod-travel-agency |grep gto
sleep 3
echo
oc get routes -n $LAB_PARTICIPANT_ID-prod-travel-agency |grep "gto"
sleep 5

echo
echo
echo "############# Setup mtls for additional ingress gateway gto in SM Tenant [$SM_TENANT_NAME] in Namespace [$SM_CP_NS ] #############"
sleep 2
echo
./create-external-mtls-https-ingress-gateway.sh prod-istio-system $OCP_DOMAIN $LAB_PARTICIPANT_ID

sleep 10
echo
echo
echo

echo "############# "
echo "      As Mesh Developer and Travel Services Domain Owner (Tech Lead) farid deploy the Istio Configs in your prod-travel-agency "
echo "      namespace to allow requests via the above defined Gateway to reach the required services cars, insurances, flights, hotels"
echo "      and travels. "
echo "#############"
sleep 3
./deploy-external-travel-api-mtls-vs.sh $LAB_PARTICIPANT_ID-prod $LAB_PARTICIPANT_ID-prod-istio-system $LAB_PARTICIPANT_ID

sleep 10

echo
echo
echo
echo
echo

echo "Task 3: Configure Authn and Authz with JWT Tokens"
echo "###########################################"
echo
echo
sleep 3
./login-as.sh emma

echo
echo
echo "############# Mount RHSSO certificate into istiod PODs #############"
echo "./mount-rhsso-cert-to-istiod.sh $LAB_PARTICIPANT_ID-prod-istio-system $LAB_PARTICIPANT_ID-production $OCP_DOMAIN"
./mount-rhsso-cert-to-istiod.sh $LAB_PARTICIPANT_ID-prod-istio-system $LAB_PARTICIPANT_ID-production $OCP_DOMAIN
echo
echo
sleep 15

echo "-------------ENCFORCING TOKEN PRESENCE--------------------------------------"
echo "apiVersion: security.istio.io/v1beta1
kind: RequestAuthentication
metadata:
 name: jwt-rhsso-gto-external
 namespace: $LAB_PARTICIPANT_ID-prod-istio-system
spec:
 selector:
   matchLabels:
     app: gto-$LAB_PARTICIPANT_ID-ingressgateway
 jwtRules:
   - issuer: >-
       https://keycloak-rhsso.$OCP_DOMAIN/auth/realms/servicemesh-lab
     jwksUri: >-
       https://keycloak-rhsso.$OCP_DOMAIN/auth/realms/servicemesh-lab/protocol/openid-connect/certs"

sleep 3

echo "apiVersion: security.istio.io/v1beta1
kind: RequestAuthentication
metadata:
 name: jwt-rhsso-gto-external
 namespace: $LAB_PARTICIPANT_ID-prod-istio-system
spec:
 selector:
   matchLabels:
     app: gto-$LAB_PARTICIPANT_ID-ingressgateway
 jwtRules:
   - issuer: >-
       https://keycloak-rhsso.$OCP_DOMAIN/auth/realms/servicemesh-lab
     jwksUri: >-
       https://keycloak-rhsso.$OCP_DOMAIN/auth/realms/servicemesh-lab/protocol/openid-connect/certs" | oc apply -f -

sleep 3

echo "-------------AUTHZ POLICY WITH TOKEN--------------------------------------"
echo
echo "apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: authpolicy-gto-external
  namespace: $LAB_PARTICIPANT_ID-prod-istio-system
spec:
  selector:
    matchLabels:
      app: gto-$LAB_PARTICIPANT_ID-ingressgateway
  action: ALLOW
  rules:
  - from:
    - source:
        requestPrincipals: ['*']
    when:
    - key: request.auth.claims[iss]
      values: [\"https://keycloak-rhsso.$OCP_DOMAIN/auth/realms/servicemesh-lab'] "

sleep 3


echo "apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: authpolicy-gto-external
  namespace: $LAB_PARTICIPANT_ID-prod-istio-system
spec:
  selector:
    matchLabels:
      app: gto-$LAB_PARTICIPANT_ID-ingressgateway
  action: ALLOW
  rules:
  - from:
    - source:
        requestPrincipals: ['*']
    when:
    - key: request.auth.claims[iss]
      values: ['https://keycloak-rhsso.$OCP_DOMAIN/auth/realms/servicemesh-lab'] " | oc apply -f -

sleep 3

echo
echo
echo
echo
echo

echo "Task 4: Test Authn / Authz with JWT"
echo "###################################"
echo
echo
sleep 3
./login-as.sh emma

export GATEWAY_URL=$(oc -n $LAB_PARTICIPANT_ID-prod-istio-system get route gto-$LAB_PARTICIPANT_ID -o jsonpath='{.spec.host}')
echo $GATEWAY_URL

echo
echo
echo "-------------TESTS WITHOUT TOKEN EXPECTED TO FAIL (403: RBAC: ACCESS DENIED)--------------------------------------"
echo
sleep 3

curl -v -X GET --cacert ca-root.crt --key curl-client.key --cert curl-client.crt https://$GATEWAY_URL/cars/Tallinn
sleep 2
curl -v -X GET --cacert ca-root.crt --key curl-client.key --cert curl-client.crt https://$GATEWAY_URL/travels/Tallinn
sleep 2

echo
echo
echo

echo "-------------TESTS WITH JWT TOKEN --------------------------------------"
echo
sleep 3


TOKEN=$(curl -Lk --data "username=gtouser&password=gtouser&grant_type=password&client_id=istio-$LAB_PARTICIPANT_ID&client_secret=$SSO_CLIENT_SECRET" https://keycloak-rhsso.$OCP_DOMAIN/auth/realms/servicemesh-lab/protocol/openid-connect/token | jq .access_token)

echo
echo "----- TOKEN RECEIVED FOR GTO USER BEFORE AUTHZ TESTS-----"
echo $TOKEN
echo "---------------------------------------------------------"
sleep 7

./call-via-mtls-and-jwt-travel-agency-api.sh $LAB_PARTICIPANT_ID-prod-istio-system gto-$LAB_PARTICIPANT_ID $TOKEN
