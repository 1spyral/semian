#!/bin/bash

# Script to update CHANGELOG.md with new version and release notes
# Usage: update_changelog.sh <new_version> <current_version>

set -e

NEW_VERSION=$1
CURRENT_VERSION=$2

if [ -z "$NEW_VERSION" ] || [ -z "$CURRENT_VERSION" ]; then
    echo "Usage: $0 <new_version> <current_version>"
    echo "Example: $0 v1.2.0 v1.1.0"
    exit 1
fi

# Get commits between versions, excluding unwanted commits
get_filtered_commits() {
    local from_tag=$1
    local to_tag=$2
    
    # Get all commits between tags with format: hash|subject|author
    git log --pretty=format:"%H|%s|%an" "${from_tag}..${to_tag}" --no-merges | \
    while IFS='|' read -r hash subject author; do
        # Skip dependabot commits
        if [[ "$author" == "dependabot"* ]] || [[ "$author" == *"dependabot"* ]]; then
            continue
        fi
        
        # Skip version bump commits
        if [[ "$subject" =~ ^[Bb]ump\ version\ to\ |^[Vv]ersion\ bump\ |^[Rr]elease\ |^v?[0-9]+\.[0-9]+\.[0-9]+ ]]; then
            continue
        fi
        
        # Skip merge commits (additional safety net)
        if [[ "$subject" =~ ^[Mm]erge\ |^[Mm]erged\ ]]; then
            continue
        fi
        
        # Format as changelog entry
        echo "* $subject"
    done
}

# Generate changelog entries
echo "Generating changelog entries for $NEW_VERSION..."
echo ""

# Get commits from current version to HEAD if CURRENT_VERSION is provided
if [ "$CURRENT_VERSION" != "HEAD" ]; then
    COMMITS=$(get_filtered_commits "$CURRENT_VERSION" "HEAD")
else
    # If no previous version, get all commits
    COMMITS=$(git log --pretty=format:"* %s" --no-merges | \
    grep -v -E "(dependabot|^[[:space:]]*\*[[:space:]]*[Bb]ump version|^[[:space:]]*\*[[:space:]]*[Vv]ersion bump|^[[:space:]]*\*[[:space:]]*[Rr]elease|^[[:space:]]*\*[[:space:]]*v?[0-9]+\.[0-9]+\.[0-9]+|^[[:space:]]*\*[[:space:]]*[Mm]erge)")
fi

if [ -z "$COMMITS" ]; then
    echo "No commits found to add to changelog."
    exit 0
fi

# Create temporary file with new changelog content
TEMP_FILE=$(mktemp)

# Add new version header and commits
echo "# $NEW_VERSION" > "$TEMP_FILE"
echo "" >> "$TEMP_FILE"
echo "$COMMITS" >> "$TEMP_FILE"
echo "" >> "$TEMP_FILE"

# Append existing changelog content (skip first line if it's empty)
if [ -f "CHANGELOG.md" ]; then
    tail -n +1 CHANGELOG.md >> "$TEMP_FILE"
fi

# Replace original changelog
mv "$TEMP_FILE" CHANGELOG.md

echo "Updated CHANGELOG.md with $NEW_VERSION"
echo ""
echo "New entries added:"
echo "$COMMITS"
