#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source $SCRIPT_DIR/common.sh

set -e

echo "--- Installing ecs-deploy CLI"
pip install ecs-deploy

# ENVIRONMENT="$1"
# ACCOUNT_ID="$BUILDKITE_PLUGIN_ECS_PIPELINE_DEPLOYMENT_ACCOUNT_ID"

# echo "--- :aws-iam: Assuming $BUILDKITE_PLUGIN_ECS_PIPELINE_DEPLOYMENT_ROLE role on $ENVIRONMENT ($ACCOUNT_ID)"
# AWS_PROFILE=`aws_assume_role $BUILDKITE_PLUGIN_ECS_PIPELINE_DEPLOYMENT_ROLE $ACCOUNT_ID` || (echo "$AWS_PROFILE" && exit 1)

# CLUSTER="$BUILDKITE_PLUGIN_ECS_PIPELINE_DEPLOYMENT_SERVICE"
# echo "--- :ecs: Getting ECS service list for '$CLUSTER'"
# SERVICES=`list_ecs_services $CLUSTER` || (echo "$SERVICES" && exit 1)


# ecs scale $CLUSTER my-service 1