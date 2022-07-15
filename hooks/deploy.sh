#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source $SCRIPT_DIR/common.sh

set -e

WORKSPACE="$BUILDKITE_PLUGIN_ECS_PIPELINE_DEPLOYMENT_WORKSPACE"
ACCOUNT_ID="$BUILDKITE_PLUGIN_ECS_PIPELINE_DEPLOYMENT_ACCOUNT_ID"

[[ "$2" ]] && DEPLOY_TAG="$2" || DEPLOY_TAG="deploy-$GIT_COMMIT"
CLUSTER="$APPLICATION-$WORKSPACE"

echo "--- :aws-iam: Assuming BuildkiteDeploy role on $WORKSPACE ($ACCOUNT_ID)"
AWS_PROFILE=`aws_assume_role BuildkiteDeploy $ACCOUNT_ID` || (echo "$AWS_PROFILE" && exit 1)

echo "--- :ecs: Getting ECS service list for '$CLUSTER'"
SERVICES=`list_ecs_services $CLUSTER` || (echo "$SERVICES" && exit 1)

echo "Found `echo \"$SERVICES\" | wc -w | awk '{print $1}'` services:"
echo "$SERVICES" | tr '\t' '\n'

if [[ $FORCE_DEPLOYMENT == true ]]; then
    echo "--- :warning: Skipping service health checks (may result in unexpected down time)"
else
    echo "--- :ecs: Checking service health"
    wait_for_ecs_services_to_be_healthy $CLUSTER "$SERVICES"
fi

echo "--- :ecr: Getting manifest for $BUILDKITE_PLUGIN_ECS_PIPELINE_DEPLOYMENT_DOCKER_REGISTRY/$APPLICATION:$WORKSPACE'"
old_manifest=`get_ecr_manifest $APPLICATION $WORKSPACE pass_if_not_found`
echo $old_manifest

echo "--- :ecr: Getting manifest for $BUILDKITE_PLUGIN_ECS_PIPELINE_DEPLOYMENT_DOCKER_REGISTRY/$APPLICATION:$DEPLOY_TAG'"
new_manifest=`get_ecr_manifest $APPLICATION $DEPLOY_TAG` || (echo "$new_manifest" && exit 1)
echo "$new_manifest"

echo "--- :mag: Comparing manifest digests"
old_manifest_digest="`echo "$old_manifest" | jq -r '.config.digest' | cut -d: -f2`"
echo "OLD: '$old_manifest_digest'"
new_manifest_digest="`echo "$new_manifest" | jq -r '.config.digest' | cut -d: -f2`"
echo "NEW: '$new_manifest_digest'"
! [ ${#new_manifest_digest} -eq 64 ] && echo "New manifest digest looks invalid (expecting 64 character hash)" && exit 1

if [[ "$old_manifest_digest" == "$new_manifest_digest" ]]; then
    echo "--- :warning: Manifest digests are the same, skipping ECR update (nothing to do)"
    echo "Probably a re-deployment of the same tag"
else
    echo "--- :ecr: Changing '$WORKSPACE' tag to point to '$DEPLOY_TAG' with manifest digest of '$new_manifest_digest'"
    aws ecr put-image --repository-name $APPLICATION --image-tag $WORKSPACE --image-manifest "$new_manifest"
    ! [ $? -eq 0 ] && echo "ERROR: Could not put ECR image tag (see above)" && exit 1
fi

./restart_services.sh $WORKSPACE $AWS_PROFILE