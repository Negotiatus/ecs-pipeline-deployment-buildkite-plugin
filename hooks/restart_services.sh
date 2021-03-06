#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source $SCRIPT_DIR/common.sh

set -e

ENVIRONMENT="$1"
ACCOUNT_ID="$BUILDKITE_PLUGIN_ECS_PIPELINE_DEPLOYMENT_ACCOUNT_ID"
CLUSTER="$BUILDKITE_PLUGIN_ECS_PIPELINE_DEPLOYMENT_SERVICE"

if [[ "$2" ]]; then
    AWS_PROFILE="$2"
    echo "--- :aws-iam: Using profile '$AWS_PROFILE'"
else
    echo "--- :aws-iam: Assuming $BUILDKITE_PLUGIN_ECS_PIPELINE_DEPLOYMENT_ROLE role on $ENVIRONMENT ($ACCOUNT_ID)"
    AWS_PROFILE=`aws_assume_role $BUILDKITE_PLUGIN_ECS_PIPELINE_DEPLOYMENT_ROLE $ACCOUNT_ID` || (echo "$AWS_PROFILE" && exit 1)
fi

echo "--- :ecs: Getting ECS service list for '$CLUSTER'"
SERVICES=`list_ecs_services $CLUSTER` || (echo "$SERVICES" && exit 1)

echo "Found `echo \"$SERVICES\" | wc -w | awk '{print $1}'` services:"
echo "$SERVICES" | tr '\t' '\n'

deployments=()
for service in $SERVICES; do
    service_name=`echo $service | cut -d/ -f3`
    echo "--- :ecs: Updating '$service_name' service on '$CLUSTER' cluster"
    service_update=`update_ecs_service $CLUSTER $service` || (echo "$deployment" && exit 1)
    echo "$service_update"
    deployment_id=`echo $service_update | jq -r '.service.deployments[] | select(.status == "PRIMARY") | .id'`
    echo "Started deployment $deployment_id"
    deployments+=("$service=$deployment_id")
done

echo "--- :stopwatch: Waiting for services to become healthy"
wait_for_ecs_services_to_be_healthy $CLUSTER "$SERVICES"

echo "--- :ecs: Verifying deployments"
for i in "${!deployments[@]}"; do
    service_arn=`echo ${deployments[$i]} | cut -d= -f1`
    service_name=`echo "$service_arn" | cut -d/ -f3`
    deployment_id=`echo ${deployments[$i]} | cut -d= -f2`
    echo "Checking $service_name:$deployment_id"
    service_info=`get_ecs_services_info $CLUSTER $service_name` || (echo "$service_info" && exit 1)
    deployment=`echo "$service_info" | jq -r ".services[].deployments[] | select(.status == \"PRIMARY\") | select(.id == \"$deployment_id\")"`
    if [[ "$deployment" && `echo "$deployment" | jq '.runningCount == .desiredCount'` ]]; then
        unset deployments[$i]
    fi
done

if [[ ${#deployments[@]} -eq 0 ]]; then
    echo -e "\nDeployments verified"
else
    echo -e "\nERROR: One or more deployments could not be verified; check logs and ECS console"
    for i in "${!deployments[@]}"; do
        echo "Could not verify deployment of ${deployments[$i]}"
    done
    exit 1
fi