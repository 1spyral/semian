#!/bin/bash

# Script to update CHANGELOG.md with new version and release notes
# Usage: update_changelog.sh <new_version> <current_version>

set -e

if [ $# -ne 2 ]; then
    echo "Usage: $0 <new_version> <current_version>"
    echo "Example: $0 1.2.3 1.2.2"
    exit 1
fi

NEW_VERSION="$1"
CURRENT_VERSION="$2"

echo "Updating CHANGELOG.md from $CURRENT_VERSION to $NEW_VERSION"

# Get the last tag to generate notes from
if [ "$CURRENT_VERSION" != "0.0.0" ]; then
    LAST_TAG="v$CURRENT_VERSION"
else
    # If no previous version, get the oldest commit
    LAST_TAG=$(git rev-list --max-parents=0 HEAD)
fi

echo "Generating release notes from $LAST_TAG to HEAD"

# Create temporary changelog file
TEMP_CHANGELOG="temp_changelog.md"
TEMP_FULL_CHANGELOG="temp_full_changelog.md"

# Generate release notes for the changelog
echo "# v$NEW_VERSION" > "$TEMP_CHANGELOG"
echo "" >> "$TEMP_CHANGELOG"

# Get commits since last version, excluding merge commits and dependabot
if git log --pretty=format:"* %s" "$LAST_TAG..HEAD" --no-merges | \
   grep -v -E "(^[[:space:]]*$|Bump.*by.*dependabot|^Merge)" | \
   head -20 >> "$TEMP_CHANGELOG"; then
    echo "Added commit-based release notes"
else
    echo "* Version bump to $NEW_VERSION" >> "$TEMP_CHANGELOG"
    echo "No significant commits found, added generic version bump note"
fi

echo "" >> "$TEMP_CHANGELOG"
echo "" >> "$TEMP_CHANGELOG"

# Prepend to existing CHANGELOG
cat "$TEMP_CHANGELOG" CHANGELOG.md > "$TEMP_FULL_CHANGELOG"
mv "$TEMP_FULL_CHANGELOG" CHANGELOG.md
rm "$TEMP_CHANGELOG"

echo "Successfully updated CHANGELOG.md"
echo "New changelog entries:"
head -15 CHANGELOG.md
