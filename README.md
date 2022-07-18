# pipeline-deployment-buildkite-plugin
Build + deploy ecs services

A Buildkite plugin for updating ECS services, part of the after deploy actions to restart the services.

Requires the aws cli tool be installed
Updates a task definition based on a given workspace and account ID
Waits for the service to stabilize (wait services-stable)
Example
```
steps:
  - label: ":ecs: :rocket:"
    key: "ecs_deploy"
    plugins:
      - Negotiatus/ecs-pipeline-deployment#v1.0.0:
          workspace: 'sandbox'
          account_id: '6565656'
          docker_registry: '${ECR_REPOSITORY}'
```

## Options

Parameter | Definition | Example | 
--- | --- | ---
workspace | Workspace name | sandbox | 
account_id | The account ID | 209637752 | 
docker_registry | ECR registry URL | aws_account_id.dkr.ecr.region.amazonaws.com |
full_deployment | If true then ecr manifest and restart services will be performed | true or false | 
