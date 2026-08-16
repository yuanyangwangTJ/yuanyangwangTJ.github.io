#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "Usage: $0 [--yes] [commit message]"
  echo "Build, review, commit, and push the Hexo blog to origin/master."
}

assume_yes=false
commit_message=""

while (($#)); do
  case "$1" in
    -y|--yes)
      assume_yes=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ -n "$commit_message" ]]; then
        echo "Error: provide the commit message as one quoted argument." >&2
        usage >&2
        exit 2
      fi
      commit_message="$1"
      ;;
  esac
  shift
done

for command_name in git node pnpm; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Error: required command '$command_name' was not found." >&2
    exit 1
  fi
done

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

current_branch="$(git branch --show-current)"
if [[ "$current_branch" != "master" ]]; then
  echo "Error: publishing is only allowed from master (current: $current_branch)." >&2
  exit 1
fi

echo "Installing locked dependencies..."
pnpm install --frozen-lockfile

echo "Building the site..."
pnpm run clean
pnpm run build
git diff --check

# Stage only blog source and known project files. Unrelated files are never
# included automatically.
git add -- \
  .github .gitignore .nvmrc \
  _config.yml _config.next.yml \
  package.json pnpm-lock.yaml pnpm-workspace.yaml \
  bin scaffolds source

privacy_pattern='-----BEGIN ([A-Z ]+ )?PRIVATE KEY-----|gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9]{20,}|/Users/[^/[:space:]]+|/home/[^/[:space:]]+|[[:alnum:]._%+-]+@[[:alnum:].-]+\.[[:alpha:]]{2,}'
sensitive_files="$(git grep --cached -IlE -e "$privacy_pattern" -- . ':!pnpm-lock.yaml' ':!bin/publish.sh' || true)"
if [[ -n "$sensitive_files" ]]; then
  echo "Error: possible private data found in staged files:" >&2
  echo "$sensitive_files" >&2
  echo "Review the files, unstage if necessary, and run the script again." >&2
  exit 1
fi

if git diff --cached --quiet; then
  echo "Nothing to publish."
  exit 0
fi

echo
git diff --cached --stat
echo

if [[ "$assume_yes" != true ]]; then
  read -r -p "Commit and publish these changes? [y/N] " answer
  case "$answer" in
    y|Y|yes|YES) ;;
    *)
      echo "Publish cancelled. Changes remain staged for review."
      exit 0
      ;;
  esac
fi

if [[ -z "$commit_message" ]]; then
  commit_message="Publish blog $(date +%Y-%m-%d)"
fi

git commit -m "$commit_message"
git push origin master

echo "Published. GitHub Actions will deploy the new site automatically."
