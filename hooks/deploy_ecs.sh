#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source $SCRIPT_DIR/functions.sh

set -e

ENVIRONMENT="$1"
ACCOUNT_ID="$2"
BUILDKITE_PLUGIN_ECS_PIPELINE_DEPLOYMENT_DEPLOY_TAG="$3"
BUILDKITE_PLUGIN_ECS_PIPELINE_DEPLOYMENT_ROLE="$BUILDKITE_PLUGIN_ECS_PIPELINE_DEPLOYMENT_ROLE"
BUILDKITE_PLUGIN_ECS_PIPELINE_DEPLOYMENT_SERVICE="$BUILDKITE_PLUGIN_ECS_PIPELINE_DEPLOYMENT_SERVICE"
IMAGE="$BUILDKITE_PLUGIN_ECS_PIPELINE_DEPLOYMENT_DOCKER_REGISTRY/$APPLICATION:$BUILDKITE_PLUGIN_ECS_PIPELINE_DEPLOYMENT_DEPLOY_TAG"

echo "--- :aws-iam: Assuming $BUILDKITE_PLUGIN_ECS_PIPELINE_DEPLOYMENT_ROLE role on $ENVIRONMENT ($ACCOUNT_ID)"
AWS_PROFILE=`aws_assume_role $BUILDKITE_PLUGIN_ECS_PIPELINE_DEPLOYMENT_ROLE $ACCOUNT_ID` || (echo "$AWS_PROFILE" && exit 1)
CLUSTER="$BUILDKITE_PLUGIN_ECS_PIPELINE_DEPLOYMENT_SERVICE"

echo "--- :ecs: Getting ECS service list for '$CLUSTER'"
SERVICES=`list_ecs_services $CLUSTER` || (echo "$SERVICES" && exit 1)
echo "Found `echo \"$SERVICES\" | wc -w | awk '{print $1}'` services:"
echo "$SERVICES" | tr '\t' '\n'
for service in $SERVICES; do
    service_name=`echo $service | cut -d/ -f3`
    echo "--- Updating and assumming role for $service_name"
    AWS_PROFILE=`aws_assume_role $BUILDKITE_PLUGIN_ECS_PIPELINE_DEPLOYMENT_ROLE $ACCOUNT_ID` || (echo "$AWS_PROFILE" && exit 1)
    IDENTITY=`aws sts get-caller-identity` || (echo $IDENTITY && exit 1)
    echo $IDENTITY
    ecs deploy $CLUSTER $service --image $service_name $IMAGE --health-check $service_name "curl -f $BUILDKITE_PLUGIN_ECS_PIPELINE_DEPLOYMENT_URL" 30 5 3 0
done