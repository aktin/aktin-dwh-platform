#!/bin/sh
# One-time template initializer. Fills in placeholders, moves the Java
# packages to the chosen groupId, removes itself.
set -eu

default_slug=$(git remote get-url origin 2>/dev/null | sed -n 's|.*github\.com[:/]\(.*\)|\1|p' | sed 's|\.git$||') || default_slug=""

ask() {
  question=$1
  default=$2
  if [ -n "$default" ]; then
    printf '%s [%s]: ' "$question" "$default" >&2
  else
    printf '%s: ' "$question" >&2
  fi
  read -r answer
  printf '%s' "${answer:-$default}"
}

# Escape sed replacement metacharacters in user input.
esc() {
  printf '%s' "$1" | sed -e 's/[&|\\]/\\&/g'
}

slug=$(ask "Repository slug (owner/repo)" "$default_slug")
owner_guess=${slug%%/*}
name_guess=${slug#*/}
name=$(ask "Project name" "$name_guess")
description=$(ask "Description" "")
author=$(ask "Author (Name <email>)" "")
owner=$(ask "Code owner (GitHub handle or team)" "$owner_guess")
group_default=$(printf 'io.github.%s' "$owner_guess" | tr '[:upper:]' '[:lower:]')
group=$(ask "Maven groupId" "$group_default")

dist=$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]' | sed -e 's/[^a-z0-9._-]\{1,\}/-/g' -e 's/^[-_.]\{1,\}//')
pkg=$(printf '%s' "$dist" | tr -cd 'a-z0-9_')
group_path=$(printf '%s' "$group" | tr '.' '/')

for file in pom.xml app/pom.xml README.md NOTICE SECURITY.md .github/CODEOWNERS; do
  [ -f "$file" ] || continue
  sed -i \
    -e "s|{{PROJECT_NAME}}|$(esc "$name")|g" \
    -e "s|{{REPO_SLUG}}|$(esc "$slug")|g" \
    -e "s|{{DESCRIPTION}}|$(esc "$description")|g" \
    -e "s|{{AUTHOR}}|$(esc "$author")|g" \
    -e "s|{{OWNER}}|$(esc "$owner")|g" \
    -e "s|<groupId>org\.example</groupId>|<groupId>$(esc "$group")</groupId>|g" \
    -e "s|java-starter|$(esc "$dist")|g" \
    "$file"
done

find app/src -name '*.java' -exec sed -i "s|org\.example\.app|$(esc "$group").$pkg|g" {} +

for root in app/src/main/java app/src/test/java; do
  mkdir -p "$root/$group_path/$pkg"
  mv "$root/org/example/app"/* "$root/$group_path/$pkg/"
  rm -rf "$root/org"
done

sed -i '/<!-- template:start -->/,/<!-- template:end -->/d' README.md

rm -- "$0"
rmdir scripts 2>/dev/null || true

printf '\nInitialized. Review the diff, then commit. See the README "Repository settings" section for the manual GitHub steps.\n'
