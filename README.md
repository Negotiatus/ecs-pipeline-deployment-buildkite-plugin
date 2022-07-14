# pipeline-deployment-buildkite-plugin
Build + deploy ecs services

A Buildkite plugin for updating ECS services.

Requires the aws cli tool be installed
Updates a task definition based on a given workspace and account ID
Waits for the service to stabilize (wait services-stable)
Example
steps:
  - label: ":ecs: :rocket:"
    key: "ecs_deploy"
    plugins:
      - Negotiatus/pipeline-deployment#v1.0.0:
          workspace: 'sandbox'
          account_id: '6565656'
Options
workspace
The name of the workspace.

Example: "sandbox"

account_id
The account ID.
