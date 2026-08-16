#!/usr/bin/env bash

# 使用方法：
#   1. 编辑或新建 source/_posts/ 下的 Markdown 文章。
#   2. 运行 ./bin/publish.sh。
#      - 只有一篇文章发生变化时，脚本自动读取 Front Matter 的 title。
#      - 有多篇文章发生变化时，按编号选择主文章，脚本自动生成提交说明。
#   3. 也可以通过文件路径指定文章（路径支持终端 Tab 补全）：
#        ./bin/publish.sh --file source/_posts/Misc/example.md
#   4. 如需跳过最终确认：
#        ./bin/publish.sh --yes --file source/_posts/Misc/example.md
#   5. 仍可直接提供自定义提交说明：
#        ./bin/publish.sh "Update site configuration"
#
# 默认提交说明格式为 "Publish: 文章标题"。构建、隐私检查、提交和推送
# 仍由脚本自动完成；只有确认发布后才会创建提交并推送到 GitHub。

set -euo pipefail

usage() {
  echo "Usage: $0 [--yes] [--file post.md] [commit message]"
  echo "Select a changed post, derive its title, build, commit, and push."
}

assume_yes=false
commit_message=""
selected_post=""

while (($#)); do
  case "$1" in
    -y|--yes)
      assume_yes=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -f|--file)
      if (($# < 2)); then
        echo "Error: --file requires a Markdown file path." >&2
        exit 2
      fi
      selected_post="$2"
      shift
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

if [[ -n "$selected_post" ]]; then
  selected_post="${selected_post#./}"
  if [[ "$selected_post" == "$repo_root/"* ]]; then
    selected_post="${selected_post#"$repo_root/"}"
  fi
  case "$selected_post" in
    source/_posts/*.md) ;;
    *)
      echo "Error: --file must point to a Markdown file under source/_posts/." >&2
      exit 2
      ;;
  esac
  if [[ ! -f "$selected_post" ]]; then
    echo "Error: post file not found: $selected_post" >&2
    exit 2
  fi
fi

if [[ -n "$selected_post" && -n "$commit_message" ]]; then
  echo "Error: use either --file or a custom commit message, not both." >&2
  exit 2
fi

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

extract_post_title() {
  local post_file="$1"
  local post_title
  post_title="$(awk '
    NR == 1 && $0 ~ /^---\r?$/ { in_front_matter = 1; next }
    in_front_matter && $0 ~ /^---\r?$/ { exit }
    in_front_matter && $0 ~ /^title:[[:space:]]*/ {
      value = $0
      sub(/^title:[[:space:]]*/, "", value)
      sub(/\r$/, "", value)
      if ((substr(value, 1, 1) == "\"" && substr(value, length(value), 1) == "\"") ||
          (substr(value, 1, 1) == "\047" && substr(value, length(value), 1) == "\047")) {
        value = substr(value, 2, length(value) - 2)
      }
      print value
      exit
    }
  ' "$post_file")"

  if [[ -z "$post_title" ]]; then
    post_title="$(basename "$post_file" .md)"
  fi
  printf '%s' "$post_title"
}

changed_posts=()
while IFS= read -r -d '' post_file; do
  if [[ "$post_file" == *.md ]]; then
    changed_posts+=("$post_file")
  fi
done < <(git diff --cached --name-only --diff-filter=ACMR -z -- source/_posts)

if [[ -n "$selected_post" ]]; then
  post_is_changed=false
  for post_file in "${changed_posts[@]}"; do
    if [[ "$post_file" == "$selected_post" ]]; then
      post_is_changed=true
      break
    fi
  done
  if [[ "$post_is_changed" != true ]]; then
    echo "Error: selected post has no staged changes: $selected_post" >&2
    exit 1
  fi
  commit_message="Publish: $(extract_post_title "$selected_post")"
elif [[ -z "$commit_message" ]]; then
  case "${#changed_posts[@]}" in
    0)
      commit_message="Update blog $(date +%Y-%m-%d)"
      ;;
    1)
      selected_post="${changed_posts[0]}"
      commit_message="Publish: $(extract_post_title "$selected_post")"
      echo "Detected changed post: $selected_post"
      ;;
    *)
      if [[ "$assume_yes" == true ]]; then
        commit_message="Publish ${#changed_posts[@]} posts"
      else
        echo "Select the primary post for the commit message:"
        for index in "${!changed_posts[@]}"; do
          post_file="${changed_posts[$index]}"
          printf '  %d) %s — %s\n' "$((index + 1))" "$(extract_post_title "$post_file")" "$post_file"
        done
        echo "  0) General blog update"

        while true; do
          read -r -p "Selection [1-${#changed_posts[@]}, 0]: " selection
          if [[ "$selection" == "0" ]]; then
            commit_message="Update blog $(date +%Y-%m-%d)"
            break
          fi
          if [[ "$selection" =~ ^[0-9]+$ ]] && ((selection >= 1 && selection <= ${#changed_posts[@]})); then
            selected_post="${changed_posts[$((selection - 1))]}"
            commit_message="Publish: $(extract_post_title "$selected_post")"
            break
          fi
          echo "Invalid selection. Please enter a listed number." >&2
        done
      fi
      ;;
  esac
fi

echo
git diff --cached --stat
echo
echo "Commit message: $commit_message"
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

git commit -m "$commit_message"
git push origin master

echo "Published. GitHub Actions will deploy the new site automatically."
