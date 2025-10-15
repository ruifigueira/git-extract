#!/bin/bash

# Script to extract changes from specific paths and rebase cleanly
# Usage: ./git-extract-v2.sh --base <base-branch> --paths <path1,path2,path3>

set -e  # Exit on any error

# Initialize variables
BASE_BRANCH=""
PATHS=()
COMMIT_MESSAGE=""

# Function to show usage
show_usage() {
    echo "Usage: $0 --base <base-branch> --paths <path1,path2,path3> [--message <commit-message>]"
    echo "       $0 -b <base-branch> -p <path1,path2,path3> [-m <commit-message>]"
    echo ""
    echo "Options:"
    echo "  --base, -b       Base branch to rebase from (e.g., staging, main)"
    echo "  --paths, -p      Comma-separated list of files/folders to extract changes from"
    echo "  --message, -m    Optional commit message (default: auto-generated)"
    echo ""
    echo "Examples:"
    echo "  $0 --base staging --paths browser-host,workers/core"
    echo "  $0 -b main -p src/components,src/utils,package.json -m 'feat: update components'"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --base|-b)
            BASE_BRANCH="$2"
            shift 2
            ;;
        --paths|-p)
            IFS=',' read -ra PATHS <<< "$2"
            shift 2
            ;;
        --message|-m)
            COMMIT_MESSAGE="$2"
            shift 2
            ;;
        --help|-h)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate required arguments
if [ -z "$BASE_BRANCH" ]; then
    echo "❌ Error: Base branch is required"
    show_usage
    exit 1
fi

if [ ${#PATHS[@]} -eq 0 ]; then
    echo "❌ Error: At least one path is required"
    show_usage
    exit 1
fi

# Safety checks: Ensure working directory is clean
echo "🔍 Checking working directory status..."
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "❌ Error: You have uncommitted changes (staged or unstaged). Please commit or stash them first."
    echo "💡 Run: git add . && git commit -m 'Your message' or git stash"
    exit 1
fi

echo "✅ Working directory is clean"

# Get current branch name and store original state
CURRENT_BRANCH=$(git branch --show-current)
ORIGINAL_COMMIT=$(git rev-parse HEAD)
TEMP_BRANCH="temp-extract-$(date +%s)"

echo "🔄 Starting extraction and rebase process..."
echo "📍 Current branch: $CURRENT_BRANCH"
echo "📍 Base branch: $BASE_BRANCH"
echo "📁 Paths to extract: ${PATHS[*]}"

# Step 1: Create diff for specified paths only
echo "📦 Creating diff for specified paths..."
DIFF_FILE="extract-$(date +%s).diff"
git diff "$BASE_BRANCH..HEAD" -- "${PATHS[@]}" > "$DIFF_FILE"

if [ ! -s "$DIFF_FILE" ]; then
    echo "❌ No changes found in specified paths"
    rm "$DIFF_FILE"
    exit 1
fi

echo "✅ Diff created: $DIFF_FILE ($(wc -l < "$DIFF_FILE") lines)"

# Step 2: Create clean branch from base and apply diff
echo "🌿 Creating clean branch from $BASE_BRANCH..."
git checkout -b "$TEMP_BRANCH" "$BASE_BRANCH"

echo "🔧 Applying diff..."
if git apply --index "$DIFF_FILE"; then
    echo "✅ Diff applied successfully"
else
    echo "❌ Failed to apply diff"
    git checkout "$CURRENT_BRANCH"
    git branch -D "$TEMP_BRANCH" 2>/dev/null || true
    rm "$DIFF_FILE"
    echo "🔄 Your repository is back to its original state"
    exit 1
fi

# Step 3: Commit the changes
if ! git diff --cached --quiet; then
    if [ -n "$COMMIT_MESSAGE" ]; then
        commit_msg="$COMMIT_MESSAGE"
    else
        commit_msg="Extract: Apply changes from ${PATHS[*]} (from $CURRENT_BRANCH)"
    fi
    
    git commit --no-verify -m "$commit_msg"
    echo "✅ Changes committed: $commit_msg"
else
    echo "❌ No changes to commit after applying diff"
    git checkout "$CURRENT_BRANCH"
    git branch -D "$TEMP_BRANCH" 2>/dev/null || true
    rm "$DIFF_FILE"
    echo "🔄 Your repository is back to its original state"
    exit 1
fi

# Step 4: Switch back and rebase
echo "🔄 Switching back to $CURRENT_BRANCH..."
git checkout "$CURRENT_BRANCH"

echo "🚀 Rebasing $CURRENT_BRANCH onto $TEMP_BRANCH..."
if git rebase -X ours "$TEMP_BRANCH"; then
    echo "✅ Rebase completed successfully!"
else
    echo "⚠️  Rebase had conflicts."
    echo "💡 The specified paths should auto-resolve to your extracted version due to -X ours strategy."
    echo "💡 Resolve any remaining conflicts and run 'git rebase --continue'"
    echo "💡 Or run 'git rebase --abort' to cancel"
    echo "🔄 To completely revert all changes, run: git reset --hard $ORIGINAL_COMMIT"
fi

# Step 5: Cleanup
echo "🧹 Cleaning up..."
git branch -D "$TEMP_BRANCH" 2>/dev/null || true
rm "$DIFF_FILE"

echo "✨ Process complete!"
echo "📍 You are now on branch: $(git branch --show-current)"
echo "🔍 Review the changes with: git log --oneline -10"
echo ""
echo "🔄 To revert all changes made by this script, run:"
echo "   git reset --hard $ORIGINAL_COMMIT"
echo "💡 This will restore your branch to its original state before running this script"
