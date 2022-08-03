#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source $SCRIPT_DIR/functions.sh

set -e

ENVIRONMENT="$1"
ACCOUNT_ID="$2"
BUILDKITE_PLUGIN_ECS_PIPELINE_DEPLOYMENT_ROLE="$BUILDKITE_PLUGIN_ECS_PIPELINE_DEPLOYMENT_ROLE"
BUILDKITE_PLUGIN_ECS_PIPELINE_DEPLOYMENT_SERVICE="$BUILDKITE_PLUGIN_ECS_PIPELINE_DEPLOYMENT_SERVICE"

echo "--- :aws-iam: Assuming $BUILDKITE_PLUGIN_ECS_PIPELINE_DEPLOYMENT_ROLE role on $ENVIRONMENT ($ACCOUNT_ID)"
AWS_PROFILE=`aws_assume_role $BUILDKITE_PLUGIN_ECS_PIPELINE_DEPLOYMENT_ROLE $ACCOUNT_ID` || (echo "$AWS_PROFILE" && exit 1)
CLUSTER="$BUILDKITE_PLUGIN_ECS_PIPELINE_DEPLOYMENT_SERVICE"

echo "--- :ecs: Starting health checks for cluster: '$CLUSTER'"
SERVICES=`list_ecs_services $CLUSTER` || (echo "$SERVICES" && exit 1)
for service in $SERVICES; do
    service_name=`echo $service | cut -d/ -f3`
    TASKS=`list_ecs_tasks $CLUSTER $service_name` || (echo "$TASKS" && exit 1)
    echo "--- :ecs: Getting ECS service Healthy status for '$service_name'"
    for task_arn in $TASKS; do
        task_info=`get_ecs_task_info $CLUSTER $task_arn` || (echo "$task_info" && return 1)
        if [[ `echo "$task_info" | jq -r ".tasks[] | .containers[] | select(.healthStatus==\"HEALTHY\")"` ]]; then
            healthy=true
            echo "The Service $service_name HEALTHY!" | tr '\t' '\n'
        else
            echo "Service Not healthy $service_name" | tr '\t' '\n'
        fi    
    done
done
