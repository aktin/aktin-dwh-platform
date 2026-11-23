# CI/CD and repository rules

What runs on GitHub for this repository and which rules protect `main`, `dev` and release tags. The git hooks that run on your machine are described in the [root README](../../README.md#checks-and-gates).

## On a pull request

These checks appear on a pull request into `main` or `dev`.

| Check | Workflow | Required to merge |
| --- | --- | --- |
| `verify / verify` | `verify.yml`, passes only when `verify / maven` and `verify / base / verify` passed | yes |
| `verify / maven` | `verify.yml`, runs `./mvnw -B verify` | through `verify / verify` |
| `verify / base / verify` | `verify.yml`, lints Dockerfiles, shell scripts and workflow files | through `verify / verify` |
| `review / review` | `scan-dependencies.yml`, fails on new dependencies with a known vulnerability of severity high or critical | yes |
| `analyze / analyze` | `scan-codeql.yml`, CodeQL scan of the Java code | not as a check, but the ruleset on `main` blocks the merge on CodeQL errors or security alerts of severity high or above |
| `CodeQL` | no workflow file, GitHub code scanning posts it with the result of the CodeQL scan | not as a check, the same code scanning rule applies |

## Workflows

The workflow files only hold the triggers. Their jobs live as reusable workflows in [aktin-github-scripts](https://github.com/aktin/aktin-github-scripts/tree/main/.github/workflows) and are called at `@main`. The actions they use are pinned to commit SHAs there.

What each workflow does and when it runs. A pull request means one into `main` or `dev`. Schedules are in UTC and run on `main`:

| Workflow | Pull request | Push to `main` | Schedule | Other | What happens |
| --- | --- | --- | --- | --- | --- |
| `verify.yml` | yes | yes | | | Starts the shared `verify-java.yml`. It checks the Dockerfiles with hadolint, the shell scripts with shellcheck and the workflow files with actionlint, and runs `./mvnw -B verify` with Java 25. The run fails when hadolint reports an error, shellcheck a warning or worse, actionlint any finding, or the Maven build fails |
| `scan-dependencies.yml` | yes | | | | Compares the dependencies before and after the pull request and fails when a newly added one has a known vulnerability of severity high or critical. On failure it writes the findings as a comment into the pull request |
| `scan-codeql.yml` | yes | yes | Mondays 03:00 | | Scans the Java and Kotlin code with CodeQL, without building it, and reports the findings in the Security tab. Workflow files and shell scripts are not scanned |
| `scan-scorecard.yml` | | yes | Mondays 04:00 | | Rates the security practices of the repository, for example branch rules, pinned actions, token permissions and code review, publishes the score to OpenSSF and to the Security tab and feeds the badge in the root README. It changes nothing |
| `release.yml` | | | | tag `v*` | Runs three jobs one after the other. `verify` repeats the checks of `verify.yml`. `build` starts the shared `build-java.yml`, which builds the jar of the tagged commit with the version taken from the tag, so the tag `v1.2.3` gives version `1.2.3`, generates the SBOM `sbom-java.cdx.json` and attests build provenance and the SBOM at GitHub. `publish` starts the shared `publish-release.yml`, which writes the release notes from the commit history with git-cliff and creates the GitHub Release with the jar and `sbom-java.cdx.json` attached. It fails when it finds no file to attach |

In `verify.yml` and `scan-codeql.yml` a newer run for the same pull request or branch cancels the one that is still running.

Dependabot is configured in `.github/dependabot.yml`. Once a week it opens one grouped pull request per ecosystem against `dev`, one for the Maven dependencies and one for the GitHub Actions referenced in the workflow files. Dependabot alerts and security updates are switched on in the repository settings and report known vulnerabilities in dependencies that are already in use. Security updates always open their pull requests against `main`.

## Gates on `main` and `dev`

Branch ruleset `default` on `main`:

| Rule | Meaning |
| --- | --- |
| Pull request required | No direct pushes. Merge commit only, 1 approval, code owner review, approvals dismissed by a new push, approval after the last push, all review threads resolved |
| Required checks | `verify / verify` and `review / review` must pass |
| Code scanning | CodeQL must have analysed the head commit without errors or security alerts of severity high or above |
| Signed commits | Every commit on `main` is signed. Merge commits are signed by GitHub |
| No force push, no delete | History on `main` is append-only |

Branch ruleset `dev` on `dev`: pull request required with squash merge only, 1 approval and resolved review threads, the same required checks, signed commits, no force push and no delete.

Approvals come from people. GitHub Actions cannot create or approve pull requests, auto-merge is off, and no app or bot is on the bypass list. Organisation admins can bypass every rule. Other branches have no rules.

The repository settings add to the rulesets. Only collaborators can open pull requests. Workflows on a pull request from a fork wait for an approval when the author is an external contributor. The head branch is deleted after a merge. Secret scanning with push protection is on, so GitHub blocks a push in which it finds a secret. The workflow token can only read by default, a job that needs more lists its permissions in the workflow file. CodeQL default setup is off, so `scan-codeql.yml` is the only CodeQL scan.

## Gates on tags `v*`

Tag ruleset `release-tags`: only maintainers and admins can create, move or delete release tags. A tag starts the release workflow, so this decides who can cut a release.

Releases are immutable. Once a release is published, its files cannot be changed or deleted and its tag cannot be moved.
