# CI/CD and repository rules

What runs on GitHub for this repository and which rules protect `main`, `dev` and release tags. The git hooks that run on your machine are described in the [root README](../../README.md#checks-and-gates).

## On a pull request to `dev` or `main`

| Check                    | Workflow                                                                                                                    | Required to merge                                                                                                        |
|--------------------------|-----------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------|
| `verify / verify`        | `verify.yml`, passes only when `verify / base / verify` and `verify / maven` passed                                         | yes                                                                                                                      |
| `verify / base / verify` | `verify.yml`, lints the Dockerfiles with hadolint, the shell scripts with shellcheck and the workflow files with actionlint | no, but `verify / verify` fails when it fails                                                                            |
| `verify / maven`         | `verify.yml`, the same `./mvnw -B verify` as the pre-push hook                                                              | no, but `verify / verify` fails when it fails                                                                            |
| `review / review`        | `scan-dependencies.yml`, fails on new dependencies with a vulnerability of severity high or critical                        | yes                                                                                                                      |
| `analyze / analyze`      | `scan-codeql.yml`, CodeQL scan of the Java code                                                                             | not as a check, but the ruleset on `main` blocks the merge on CodeQL errors or security alerts of severity high or above |
| `CodeQL`                 | Posted by GitHub code scanning with the result of `scan-codeql.yml`, shows the new alerts on the changed lines              | no                                                                                                                       |

## Workflows

The workflow files only hold the triggers, their jobs live as reusable workflows in [aktin-github-scripts](https://github.com/aktin/aktin-github-scripts/tree/main/.github/workflows) and are called at `@main`.

What each workflow does and when it runs. Schedules are in UTC and run on `main`:

| Workflow                | Pull request to `dev` or `main` | Push to `main` | Schedule      | Other    | What happens |
|-------------------------|---------------------------------|----------------|---------------|----------|--------------|
| `verify.yml`            | yes                             | yes            |               |          | Starts the shared `verify-java.yml`. It checks the Dockerfiles with hadolint, the shell scripts with shellcheck and the workflow files with actionlint and runs `./mvnw -B verify` on Java 25. The run fails when hadolint reports an error, shellcheck a warning or worse, actionlint any finding or the Maven build fails |
| `scan-dependencies.yml` | yes                             |                |               |          | Compares the dependencies before and after the pull request and fails when a newly added one has a known vulnerability of severity high or critical. On a failure it writes the findings as a comment in the pull request |
| `scan-codeql.yml`       | yes                             | yes            | Mondays 03:00 |          | Scans the Java code with CodeQL and reports the findings in the Security tab. The workflow files are not scanned. CodeQL default setup is off in the repository settings, so this workflow is the only CodeQL scan |
| `scan-scorecard.yml`    |                                 | yes            | Mondays 04:00 |          | Rates the security practices of the repository, for example branch rules, pinned actions, token permissions and code review, publishes the score to OpenSSF and the findings to the Security tab and feeds the badge in the root README. It changes nothing |
| `release.yml`           |                                 |                |               | tag `v*` | Runs three jobs one after the other. `verify` runs the same checks as `verify.yml` on the tagged commit. `build` starts the shared `build-java.yml`, which builds the jar with the version taken from the tag, generates the SBOM `sbom-java.cdx.json` and attests build provenance and the SBOM at GitHub. `publish` starts the shared `publish-release.yml`, which writes the release notes from the commit history with git-cliff and creates the GitHub Release with the jar and `sbom-java.cdx.json` attached. It fails when it finds no file to attach |

Dependabot is configured in `.github/dependabot.yml`. Once a week it opens one grouped pull request per ecosystem against `dev`, one with updates for the Maven dependencies and one with updates for the GitHub Actions used in the workflows. Dependabot alerts and security updates are switched on in the repository settings. Alerts report known vulnerabilities in dependencies that are already in use. Security updates open pull requests against `main` that fix them.

## Gates on `main` and `dev`

Branch ruleset `default` on `main`:

| Rule                     | Meaning                                                                                                                       |
|--------------------------|-------------------------------------------------------------------------------------------------------------------------------|
| Pull request required    | No direct pushes. Merge commit only, 1 approval, code owner review, approval after the last push, all review threads resolved |
| Required checks          | `verify / verify` and `review / review` must pass                                                                             |
| Code scanning            | CodeQL must have analysed the head commit without errors or security alerts of severity high or above                         |
| Signed commits           | Every commit on `main` is signed. Merge commits are signed by GitHub                                                          |
| No force push, no delete | History on `main` is append-only                                                                                              |

Branch ruleset `dev` on `dev`: pull request required with squash merge only, 1 approval and resolved review threads, the same required checks, signed commits, no force push and no delete.

Approvals come from people. GitHub Actions cannot create or approve pull requests, auto-merge is off, and no app or bot is on the bypass list. Organisation admins can bypass every rule. Other branches have no rules.

The repository settings add to the rulesets. Only collaborators can open pull requests. Workflows on a pull request from a fork wait for approval. The head branch is deleted after the merge. Secret scanning with push protection blocks a push that contains a secret. The workflow token can only read by default, a job that needs more gets the permission in its workflow file.

## Gates on tags `v*`

Tag ruleset `release-tags`: only maintainers and admins can create, move or delete release tags. A tag starts the release workflow, so this decides who can cut a release. Releases are immutable once published. The tag stays on its commit and the attached files cannot be changed or deleted.
