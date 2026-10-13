# aktin-dwh-platform

[![CI](https://github.com/aktin/aktin-dwh-platform/actions/workflows/ci.yml/badge.svg)](https://github.com/aktin/aktin-dwh-platform/actions/workflows/ci.yml)
[![CodeQL](https://github.com/aktin/aktin-dwh-platform/actions/workflows/codeql.yml/badge.svg)](https://github.com/aktin/aktin-dwh-platform/actions/workflows/codeql.yml)
[![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/aktin/aktin-dwh-platform/badge)](https://securityscorecards.dev/viewer/?uri=github.com/aktin/aktin-dwh-platform)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](./LICENSE)
[![Release](https://img.shields.io/github/v/release/aktin/aktin-dwh-platform)](https://github.com/aktin/aktin-dwh-platform/releases)

Modular data warehouse platform for clinical data on i2b2. A small, stable platform service runs independent modules as containers and provides lifecycle management, database schemas, filesystem, event bus, OIDC identity (Keycloak) and a web frontend. On-premise, one Compose project per DWH.

## Getting started

You need Java 25 on PATH (Maven comes through the wrapper), the [lefthook](https://lefthook.dev) binary for the git hooks (`apt install lefthook`, `brew install lefthook`, or a release download) and `python3` for the shared hooks.

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

Allowed types are `feat fix docs style refactor perf test chore`. The subject starts lowercase, has no trailing period, and the header stays at most 100 characters. Pull requests are squash merged, so one conventional subject per PR lands on `main`.

A release is a tag `vX.Y.Z` on `main`. The release workflow builds the tagged commit with the version taken from the tag (`pom.xml` stays at `0.0.0`), writes the release notes from the commit history with git-cliff, adds a CycloneDX SBOM and build attestations, and attaches the Boot jar to the GitHub Release.

## Checks and gates

Three layers. Each layer trusts the one before it a little less.

### On your machine

lefthook runs these after `lefthook install`:

| When       | What runs                                                                                                                                                  | Blocks     |
|------------|------------------------------------------------------------------------------------------------------------------------------------------------------------|------------|
| pre-commit | Spotless formats the staged Java files, Checkstyle lints them, gitleaks scans for secrets, the shared hooks reject data files, large files and oversized commits | the commit |
| commit-msg | Conventional Commit header check                                                                                                                           | the commit |
| pre-push   | `./mvnw -B verify`: enforcer (JDK and Maven version), Spotless check, Checkstyle, tests, JaCoCo 80% line coverage                                         | the push   |

Hooks can be skipped with `--no-verify`, so nothing here is a guarantee. They exist for fast feedback.

### On a pull request to `main`

| Check             | Workflow                                                                      | Required to merge                                                                                             |
|-------------------|-------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------|
| `verify / verify` | `ci.yml` calls `verify.yml`, the same `mvnw verify` as the pre-push hook      | yes                                                                                                           |
| `review`          | `dependency-review.yml`, fails on new dependencies with high or critical CVEs | yes                                                                                                           |
| `analyze`         | `codeql.yml`, CodeQL code scanning                                            | not as a check, but the ruleset blocks the merge on CodeQL errors or security alerts of severity high or above |

### After a merge and on tags

On every push to `main`, `verify / verify` and `analyze` run again on the merged commit and Scorecard scores the repository and publishes the result to OpenSSF. CodeQL and Scorecard also run weekly.

On a tag `vX.Y.Z`, `release.yml` runs verify, builds the jar, writes the SBOM and attestations and creates the GitHub Release.

### Gates on `main`

Branch ruleset `default`:

| Rule                     | Meaning                                                                                                                       |
|--------------------------|-------------------------------------------------------------------------------------------------------------------------------|
| Pull request required    | No direct pushes. Squash merge only, 1 approval, code owner review, approval after the last push, all review threads resolved |
| Required checks          | `verify / verify` and `review` must pass                                                                                      |
| Code scanning            | CodeQL must have analysed the head commit without errors or security alerts of severity high or above                         |
| Signed commits           | Every commit on `main` is signed. Squash merges are signed by GitHub                                                           |
| No force push, no delete | History on `main` is append-only                                                                                              |

Organisation admins can bypass every rule. Other branches have no rules.

### Gates on tags `v*`

Tag ruleset `release-tags`: only maintainers and admins can create, move or delete release tags. A tag starts the release workflow, so this decides who can cut a release.
