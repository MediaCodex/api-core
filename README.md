# Backend Core

This repo is an amalgamation of resources that are generally independent of any spefic service. It also contains most, if not _all_
of the DNS records bcause that means only having cloudflare credentials in one place.

## First deployment

While this should always be the first service to be instantiated in a new environment, and for the most part it will work just fine since
most of the resources are defined in such a way as to be independent of other services to avoid race-conditions. However, there are a few
resources that reply on the outputs from other services, as such they cannot be created without causing a lovely chicken-and-egg scenario
for the order in which to deploy said services.

To make life significantly easier any resources that rely on sub-services can be disabled by changing a single variable to `true`, while
this does force you to deploy this repo twice for a new cloud, that in significantly less effort than any alternatives. The variable can
even be set via the CI env so you don't have to commit any changes, just run the pipeline twice.

| Default value | TF Var         | Env Var               |
| ------------- | -------------- | --------------------- |
| `false`       | `first_deploy` | `TF_VAR_first_deploy` |
