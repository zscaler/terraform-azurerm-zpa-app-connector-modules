# Contributing

Contributions are welcome, and they are greatly appreciated! Every little bit helps,
and credit will always be given.

## Coding Standards

Please follow the [Terraform conventions](terraform-conventions.md) for the project.

## Testing

Every module and example has a Terratest suite in `main_test.go`. Run a suite with the Makefile, passing the test name prefix as `ACTION`:

```sh
make examples/base_ac ACTION=Plan
```

`ACTION` is passed to `go test -run`, so `Plan` runs every `TestPlan*` function in the directory.

| Action | What it does | Where it runs |
|--------|--------------|---------------|
| `Validate` | `terraform init` + `validate` | PR CI, every changed module and example |
| `Plan` | Plans the example and asserts the planned image, Marketplace purchase plan and Trusted Launch settings, and that the pinned image version is still published in the region | PR CI, every changed example |
| `Apply` | Deploys and destroys the example | ChatOps `/apply` |
| `Idempotence` | Deploys, checks that a second plan has no changes, and destroys | ChatOps `/idempotence` |

The plan assertions live in `internal/testhelpers`. The test skeleton only asserts Terraform outputs, so the helpers read the planned resource values instead. `examples/base_ac` deploys the RHEL 9 Generation 2 image with Trusted Launch in `Apply` and `Idempotence`; `examples/ac` covers the Zscaler Marketplace image.

To run the suites locally, log in with `az login` and export `ARM_SUBSCRIPTION_ID`. Examples that create ZPA resources also need the ZPA OneAPI variables (`ZSCALER_CLIENT_ID`, `ZSCALER_CLIENT_SECRET`, `ZSCALER_VANITY_DOMAIN`, `ZPA_CUSTOMER_ID`, and `ZSCALER_CLOUD` where applicable).

## Publish a new release (for maintainers)

### Test the release process

Testing the workflow requires node, npm, and semantic-release to be installed locally:

```
$ npm install -g semantic-release@^17.1.1 @semantic-release/git@^9.0.0 @semantic-release/exec@^5.0.0 conventional-changelog-conventionalcommits@^4.4.0
```

Run `semantic-release` on develop:

```
semantic-release --dry-run --no-ci --branches=develop
```

Verify in the output that the next version is set correctly, and the release notes are generated correctly.

### Merge develop to master and push

```
git checkout master
git merge develop
git push origin master
```

At this point, GitHub Actions builds and tags the release.

### Merge master to develop and push

Now, sync develop to master to add any commits made by the release bot.

```
git fetch --all --tags
git pull origin master
git checkout develop
git merge master
git push origin develop
```
