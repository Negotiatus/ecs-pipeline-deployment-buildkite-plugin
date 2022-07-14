# pipeline-deployment-buildkite-plugin
Build + deploy ecs services

A Buildkite plugin for updating ECS services.

Requires the aws cli tool be installed
Updates a task definition based on a given workspace and account ID
Waits for the service to stabilize (wait services-stable)
Example
```
steps:
  - label: ":ecs: :rocket:"
    key: "ecs_deploy"
    plugins:
      - Negotiatus/ecs-pipeline-deployment#v1.0.1:
          workspace: 'sandbox'
          account_id: '6565656'
```

## Options

Parameter | Definition | Example | 
--- | --- | ---
workspace | Workspace name | sandbox | 
account_id | The account ID | 209637752 | 
