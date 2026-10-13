# Contributing

## Prerequisites

Java 21 and the committed Maven wrapper (`./mvnw`). Git hooks are managed by
[lefthook](https://lefthook.dev) — install the binary once (e.g.
`apt install lefthook`, `brew install lefthook`, or a release download), then:

```sh
lefthook install
```

The shared git hooks are Python scripts and need `python3` on PATH. They are
pulled from the repository configured under `remotes` in `lefthook.yml`, change
`git_url` and `ref` there to use another source.

## Development

```sh
./mvnw verify                   # full gate: format check, checkstyle, tests + coverage, build
./mvnw spotless:apply           # format
./mvnw test                     # unit tests
./mvnw -pl app spring-boot:run  # run the app
```

## Commits

Messages follow [Conventional Commits](https://www.conventionalcommits.org),
enforced by the shared `commit-msg` hook from
[aktin-github-scripts](https://github.com/aktin/aktin-github-scripts).

## Pull requests

Make sure `./mvnw verify` passes. The pre-push hook runs it as well.

## Releases

Push a `vX.Y.Z` tag. The release workflow builds the Boot jar, generates the
release notes, produces an SBOM and attestations, and publishes the
GitHub Release.
