#!/bin/bash

# Version bumping script for PiecesOfPaper
# Uses agvtool (Apple Generic Versioning Tool) to manage version and build numbers
#
# Usage:
#   ./scripts/bump-version.sh                    # Show current version
#   ./scripts/bump-version.sh build              # Increment build number only
#   ./scripts/bump-version.sh patch              # Bump patch version (e.g., 3.2.1 -> 3.2.2)
#   ./scripts/bump-version.sh minor              # Bump minor version (e.g., 3.2.1 -> 3.3.0)
#   ./scripts/bump-version.sh major              # Bump major version (e.g., 3.2.1 -> 4.0.0)
#   ./scripts/bump-version.sh set 3.3.0          # Set specific version
#   ./scripts/bump-version.sh set-build 18       # Set specific build number

set -e

cd "$(dirname "$0")/.."

show_current() {
    echo "Current version:"
    agvtool what-marketing-version -terse1 2>/dev/null || echo "  (not set)"
    echo "Current build:"
    agvtool what-version -terse 2>/dev/null || echo "  (not set)"
}

increment_build() {
    echo "Incrementing build number..."
    agvtool next-version -all
    echo ""
    show_current
}

set_version() {
    local version=$1
    echo "Setting marketing version to $version..."
    agvtool new-marketing-version "$version"
    echo ""
    show_current
}

set_build() {
    local build=$1
    echo "Setting build number to $build..."
    agvtool new-version -all "$build"
    echo ""
    show_current
}

bump_version() {
    local bump_type=$1
    local current_version
    current_version=$(agvtool what-marketing-version -terse1 2>/dev/null)

    if [ -z "$current_version" ]; then
        echo "Error: Could not read current version"
        exit 1
    fi

    IFS='.' read -r major minor patch <<< "$current_version"

    case $bump_type in
        patch)
            patch=$((patch + 1))
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            ;;
        major)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
    esac

    local new_version="$major.$minor.$patch"
    set_version "$new_version"
    increment_build
}

case "${1:-}" in
    "")
        show_current
        ;;
    build)
        increment_build
        ;;
    patch)
        bump_version patch
        ;;
    minor)
        bump_version minor
        ;;
    major)
        bump_version major
        ;;
    set)
        if [ -z "${2:-}" ]; then
            echo "Error: Please provide a version number"
            echo "Usage: $0 set <version>"
            exit 1
        fi
        set_version "$2"
        ;;
    set-build)
        if [ -z "${2:-}" ]; then
            echo "Error: Please provide a build number"
            echo "Usage: $0 set-build <build>"
            exit 1
        fi
        set_build "$2"
        ;;
    *)
        echo "Unknown command: $1"
        echo ""
        echo "Usage:"
        echo "  $0                    Show current version"
        echo "  $0 build              Increment build number"
        echo "  $0 patch              Bump patch version (x.y.Z)"
        echo "  $0 minor              Bump minor version (x.Y.0)"
        echo "  $0 major              Bump major version (X.0.0)"
        echo "  $0 set <version>      Set specific version"
        echo "  $0 set-build <build>  Set specific build number"
        exit 1
        ;;
esac
