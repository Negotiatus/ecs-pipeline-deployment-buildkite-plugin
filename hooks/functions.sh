#!/bin/bash

# Common variables, functions, and other things shared between Buildkite scripts

### String Conversion Functions

### AWS Functions ###
aws_assume_role() {
    # Assumes a role on a given AWS account and returns the profile name you can use to call the AWS CLI
    local tmp_file="`mktemp`" role_name=$1 account_id=$2 profile=$3
    [[ "$profile" ]] && profile="--profile $3"
    local EXTRA_ARGS="$@"
    local profile="$role_name$account_id" \
          role_arn="arn:aws:iam::$account_id:role/$role_name"
    aws sts assume-role --output json \
                        --role-arn $role_arn \
                        --role-session-name $profile`date +%s` \
                        --duration 3600 \
                        --output json > "$tmp_file";
    if ! [ $? -eq 0 ]; then
        cat "$tmp_file"
        echo "ERROR: Could not assume $role_name IAM role on $account_id (see above)" && return 1;
    else
        access_key_id=`cat "$tmp_file" | grep "AccessKeyId" | awk '{print $2}' | sed s/[\",]//g`;
        secret_access_key=`cat "$tmp_file" | grep "SecretAccessKey" | awk '{print $2}' | sed s/[\",]//g`;
        session_token=`cat "$tmp_file" | grep "SessionToken" | awk '{print $2}' | sed s/[\",]//g`;
    fi;
    aws configure set aws_access_key_id $access_key_id --profile $profile;
    aws configure set aws_secret_access_key $secret_access_key --profile $profile;
    aws configure set aws_session_token $session_token --profile $profile;
    aws configure set region us-east-1 --profile $profile;
    echo "$profile"
}

get_ecs_task_info() {
    local tmp_file="`mktemp`" cluster="$1" task_arn="$2"
    [[ "$AWS_PROFILE" ]] && profile="$AWS_PROFILE"
    [[ "$3" ]] && profile="$3"
    [[ -z "$profile" ]] && echo "Must either set AWS_PROFILE or pass a profile name" && return 1
    aws ecs describe-tasks --cluster "$cluster" \
                           --tasks $task_arn \
                           --profile $profile \
                           --output json > $tmp_file
    ! [ $? -eq 0 ] && echo "ERROR: Could not describe task (see above)" && return 1
    cat $tmp_file
}

list_ecs_services() {
    # Lists ECS Services on a specific cluster
    local tmp_file="`mktemp`" cluster="$1"
    [[ "$AWS_PROFILE" ]] && profile="$AWS_PROFILE"
    [[ "$2" ]] && profile="$2"
    [[ -z "$profile" ]] && echo "Must either set AWS_PROFILE or pass a profile name" && return 1
    aws ecs list-services --cluster $cluster \
                          --profile $profile \
                          --query "serviceArns" \
                          --output text > "$tmp_file"
    ! [ $? -eq 0 ] && echo "ERROR: Could not list services (see above)" && return 1
    ! [[ `cat "$tmp_file"` ]] && echo "ERROR: No services found" && return 1
    cat "$tmp_file"
}

list_ecs_tasks() {
    # Lists ECS Services on a specific cluster
    local tmp_file="`mktemp`" cluster="$1" service_name="$2"
    [[ "$AWS_PROFILE" ]] && profile="$AWS_PROFILE"
    [[ "$3" ]] && profile="$3"
    [[ -z "$profile" ]] && echo "Must either set AWS_PROFILE or pass a profile name" && return 1
    aws ecs list-tasks --cluster $cluster \
                          --service-name $service_name \
                          --profile $profile \
                          --query "taskArns" \
                          --output text > "$tmp_file"
    ! [ $? -eq 0 ] && echo "ERROR: Could not list tasks (see above)" && return 1
    ! [[ `cat "$tmp_file"` ]] && echo "ERROR: No tasks found" && return 1
    cat "$tmp_file"
}

### Variables ###

echo "--- :information_source: Loading environment information"

export COMMON_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export APPLICATION="`[[ $BUILDKITE_PIPELINE_SLUG ]] && echo "$BUILDKITE_PIPELINE_SLUG" | sed -e 's/\-[^\-]*$//' || cat $COMMON_DIR/../.application`"

export GIT_BRANCH=`[[ $BUILDKITE_BRANCH ]] && echo "$BUILDKITE_BRANCH" || git branch | grep \* | cut -d ' ' -f2`
export GIT_COMMIT=`[[ $BUILDKITE_COMMIT && $BUILDKITE_COMMIT != HEAD ]] && echo "$BUILDKITE_COMMIT" || git rev-parse HEAD`

export JOB_NUMBER=`[[ $BUILDKITE_PARALLEL_JOB ]] && echo "$BUILDKITE_PARALLEL_JOB" || echo "0"`
export JOB_COUNT=`[[ $BUILDKITE_PARALLEL_JOB_COUNT ]] && echo "$BUILDKITE_PARALLEL_JOB_COUNT" || echo "1"`
export BUILD_NUMBER=`[[ $BUILDKITE_BUILD_NUMBER ]] && echo "$BUILDKITE_BUILD_NUMBER" || echo "$RANDOM"`

export SCHEMA_COMMIT=`git log --pretty=format:'%h' -n 1 -- db/`
export SCHEMA_FILE="schema_$SCHEMA_COMMIT.sql"

export DESCRIPTION=`[[ $BUILDKITE_MESSAGE ]] && echo "$BUILDKITE_MESSAGE" || echo "Manual command by '$(whoami)'"`

echo "common.sh MD5 checksum: `md5sum $COMMON_DIR/common.sh | cut -d' ' -f1`"
echo "COMMON_DIR=$COMMON_DIR"
echo "SCRIPT_DIR=$SCRIPT_DIR"
echo "APPLICATION=$APPLICATION"
echo "GIT_BRANCH=$GIT_BRANCH"
echo "GIT_COMMIT=$GIT_COMMIT"
echo "SCHEMA_COMMIT=$SCHEMA_COMMIT"
echo "SCHEMA_FILE=$SCHEMA_FILE"
echo "JOB_NUMBER=$JOB_NUMBER"
echo "JOB_COUNT=$JOB_COUNT"
echo "BUILD_NUMBER=$BUILD_NUMBER"
echo "DESCRIPTION=$DESCRIPTION"