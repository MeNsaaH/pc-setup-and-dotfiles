#!/bin/sh
# git house-keeping — remove worktrees and local branches whose upstream is gone.
#
# A branch is considered "merged" here when its upstream is gone — i.e., the
# remote branch has been deleted after its MR/PR was squash-merged. This is the
# only signal that's reliable across squash, rebase, and fast-forward merges.
#
# Worktrees with uncommitted changes are skipped (the branch is not deleted in
# that case either). Pass --force to bypass the dirty check.
#
# Usage: git house-keeping [--force] [--dry-run]

set -e

force=0
dry=0
for arg in "$@"; do
  case "$arg" in
    --force) force=1 ;;
    --dry-run|-n) dry=1 ;;
    -h|--help)
      sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "unknown flag: $arg" >&2
      exit 2
      ;;
  esac
done

run() {
  if [ "$dry" = 1 ]; then
    echo "  [dry-run] $*"
  else
    "$@"
  fi
}

git fetch --prune origin >/dev/null 2>&1 || true

gone=$(git for-each-ref --format='%(refname:short) %(upstream:track)' refs/heads/ \
  | awk '/\[gone\]/ {print $1}')

if [ -z "$gone" ]; then
  echo "No stale branches."
  exit 0
fi

echo "Stale branches (upstream gone):"
echo "$gone" | sed 's/^/  /'
echo

removed_worktrees=0
deleted_branches=0
skipped=0

# IFS=newline so branch names with slashes are preserved.
echo "$gone" | while IFS= read -r branch; do
  [ -z "$branch" ] && continue

  # Find a worktree (if any) that has this branch checked out.
  wt=$(git worktree list --porcelain \
    | awk -v b="$branch" '
        /^worktree / { w = $2 }
        /^branch /   { if ($2 == "refs/heads/" b) print w }
      ')

  if [ -n "$wt" ]; then
    dirty=""
    if [ -d "$wt" ]; then
      dirty=$(git -C "$wt" status --porcelain 2>/dev/null || true)
    fi
    if [ -n "$dirty" ] && [ "$force" != 1 ]; then
      echo "  $branch: skipping (worktree $wt has uncommitted changes; pass --force to override)"
      skipped=$((skipped + 1))
      continue
    fi
    echo "  $branch: removing worktree $wt"
    if [ "$force" = 1 ]; then
      run git worktree remove --force "$wt" 2>/dev/null || run git worktree remove --force "$wt"
    else
      run git worktree remove "$wt" 2>/dev/null || run git worktree remove --force "$wt"
    fi
    removed_worktrees=$((removed_worktrees + 1))
  fi

  echo "  $branch: deleting branch"
  run git branch -D "$branch"
  deleted_branches=$((deleted_branches + 1))
done

run git worktree prune

echo
echo "Done."
