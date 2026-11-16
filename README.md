# aktin-dwh-platform

[![Verify](https://github.com/aktin/aktin-dwh-platform/actions/workflows/verify.yml/badge.svg)](https://github.com/aktin/aktin-dwh-platform/actions/workflows/verify.yml)
[![CodeQL](https://github.com/aktin/aktin-dwh-platform/actions/workflows/scan-codeql.yml/badge.svg)](https://github.com/aktin/aktin-dwh-platform/actions/workflows/scan-codeql.yml)
[![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/aktin/aktin-dwh-platform/badge)](https://securityscorecards.dev/viewer/?uri=github.com/aktin/aktin-dwh-platform)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](./LICENSE)
[![Release](https://img.shields.io/github/v/release/aktin/aktin-dwh-platform)](https://github.com/aktin/aktin-dwh-platform/releases)

Modular data warehouse platform for clinical data on i2b2. A small, stable platform service runs independent modules as containers and provides lifecycle management, database schemas, filesystem, event bus, OIDC identity (Keycloak) and a web frontend. On-premise, one Compose project per DWH.

## Getting started

You need Java 25 on PATH. Maven comes through the wrapper. The git hooks need the [lefthook](https://lefthook.dev) binary (`apt install lefthook`, `brew install lefthook`, or a release download) and `python3`, `gitleaks`, `actionlint`, `hadolint` and `shellcheck` on PATH.

```sh
lefthook install                 # git hooks, once per clone
./mvnw verify                    # full gate: format check, checkstyle, tests + coverage, build
./mvnw spotless:apply            # format
./mvnw test                      # unit tests
./mvnw -pl app spring-boot:run   # run the app
```

The coverage report lands in `app/target/site/jacoco/index.html`.

## Commits and releases

Commits follow [Conventional Commits](https://www.conventionalcommits.org), enforced by the commit-msg hook:

```
<type>(<optional scope>): <subject>
```

Example: `feat(import): add CSV validation for uploads`

Allowed types are `feat fix docs style refactor perf test chore`. The subject starts lowercase, has no trailing period, and every line of the message stays at most 100 characters. Pull requests into `dev` are squash merged, so one conventional subject per PR lands on `dev`. `dev` is merged into `main` with a merge commit.

A release is a tag `vX.Y.Z` on `main`, for example `v1.2.0`. The tag starts the release workflow. It creates a GitHub Release with release notes written from the commit history, the Boot jar and its CycloneDX SBOM `sbom-java.cdx.json`. The jar takes its version from the tag, here `aktin-dwh-platform-1.2.0.jar`, and `pom.xml` stays at `0.0.0`. The jobs of the release workflow are described in [.github/workflows/README.md](.github/workflows/README.md#workflows).

GitHub stores a signed attestation for every released jar. To check that a downloaded jar was built by the release workflow, run the [GitHub CLI](https://cli.github.com) in the folder of the jar:

```sh
gh attestation verify aktin-dwh-platform-<version>.jar --repo aktin/aktin-dwh-platform --signer-repo aktin/aktin-github-scripts

# Example:
# gh attestation verify aktin-dwh-platform-1.2.0.jar --repo aktin/aktin-dwh-platform --signer-repo aktin/aktin-github-scripts
```

`--signer-repo` names aktin-github-scripts because the shared build workflow in that repository signs the attestation.

## Checks and gates

A change passes three layers: the git hooks on your machine, the checks on the pull request and the rules on the branch. Anyone can skip the hooks, only organisation admins can bypass the checks and the rules. The hooks are described here. The checks on pull requests, the workflows, Dependabot and the rules on `main`, `dev` and release tags are described in [.github/workflows/README.md](.github/workflows/README.md).

### On your machine

> [!CAUTION]
> Run `lefthook install` once after cloning, before your first commit. Without it no git hook runs on your machine.

All hooks come from [aktin-github-scripts](https://github.com/aktin/aktin-github-scripts#git-hooks) through `lefthook.yml`. lefthook runs them after `lefthook install`. A missing tool fails the commit. actionlint, hadolint and shellcheck are only called when a workflow file, Dockerfile or shell script is staged.

| When       | What runs                                                                                                                                                  | Blocks     |
|------------|------------------------------------------------------------------------------------------------------------------------------------------------------------|------------|
| pre-commit | Spotless formats the staged Java files, Checkstyle lints them, gitleaks scans for secrets, actionlint, hadolint and shellcheck lint the staged workflow files, Dockerfiles and shell scripts, the shared scripts reject data files, large files and oversized commits | the commit |
| commit-msg | Conventional Commit header check                                                                                                                           | the commit |
| pre-push   | `./mvnw -B verify`: enforcer (JDK and Maven version), Spotless check, Checkstyle, tests, JaCoCo 80% line coverage                                         | the push   |

Hooks can be skipped with `--no-verify`, so nothing here is a guarantee. They exist for fast feedback.

## License

Apache-2.0. See [LICENSE](./LICENSE) and [NOTICE](./NOTICE).
