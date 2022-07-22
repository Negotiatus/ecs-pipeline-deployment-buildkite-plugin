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
      - Negotiatus/ecs-pipeline-deployment#v1.0.2:
          account_id: '6565656'
          environment: 'sandbox'
          service: 'assistant-test'
          role: 'BuildkiteRole'
          deployment: true
          docker_registry: '${ECR_REPOSITORY}'
```

## Options

Parameter | Definition | Example | 
--- | --- | ---
environment | Environment name | sandbox | 
account_id | The account ID | 209637752 | 
docker_registry | ECR registry URL | aws_account_id.dkr.ecr.region.amazonaws.com |
deployment | If true then ecr manifest and restart services will be performed | true or false | 
role | Assume role name | BuilkiteRole | 
service | Service Name | assistant-sandbox | 
deploy_tag | deploy tag used in the previous step | deploy-dev | 
