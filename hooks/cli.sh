#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source $SCRIPT_DIR/common.sh

set -e

echo "--- Installing ecs-deploy CLI"
pip install ecs-deploy

ENVIRONMENT="$1"
ACCOUNT_ID="$2"
BUILDKITE_PLUGIN_ECS_PIPELINE_DEPLOYMENT_ROLE="$4"
BUILDKITE_PLUGIN_ECS_PIPELINE_DEPLOYMENT_SERVICE="$3"

echo "--- :aws-iam: Assuming $BUILDKITE_PLUGIN_ECS_PIPELINE_DEPLOYMENT_ROLE role on $ENVIRONMENT ($ACCOUNT_ID)"
AWS_PROFILE=`aws_assume_role $BUILDKITE_PLUGIN_ECS_PIPELINE_DEPLOYMENT_ROLE $ACCOUNT_ID` || (echo "$AWS_PROFILE" && exit 1)

CLUSTER="$BUILDKITE_PLUGIN_ECS_PIPELINE_DEPLOYMENT_SERVICE"
echo "--- :ecs: Getting ECS service list for '$CLUSTER'"
SERVICES=`list_ecs_services $CLUSTER` || (echo "$SERVICES" && exit 1)
echo "Found `echo \"$SERVICES\" | wc -w | awk '{print $1}'` services:"
# echo "$SERVICES" | tr '\t' '\n'

for task_arn in $SERVICES; do
    echo "this is the task arn: $task_arn"
    task_info=`get_ecs_task_info $CLUSTER $task_arn` || (echo "$task_info" && return 1)
    if [[ `echo "$task_info" | jq -r ".tasks[] | .containers[] | select(.healthStatus==\"HEALTHY\")"` ]]; then
    healthy=true
    service_name=`echo "$task_info" | jq ".tasks[].containers[0].name"`
    echo "The Service $service_name HEALTHY!"
    else
        printf "."
    fi    
done

