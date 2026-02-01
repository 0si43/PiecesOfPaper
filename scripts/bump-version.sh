#!/bin/bash

# Version bumping script for PiecesOfPaper
# Uses xcodebuild to read version/build numbers and direct project.pbxproj editing to update them
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

get_build_setting() {
    local setting_name=$1
    local value

    # Use -target for portability, -configuration Release for production values
    value=$(xcodebuild -showBuildSettings \
        -target PiecesOfPaper \
        -configuration Release 2>/dev/null \
        | grep -w "$setting_name" \
        | awk '{print $3}')

    echo "$value"
}

update_build_setting() {
    local setting_name=$1
    local new_value=$2
    local project_file="PiecesOfPaper.xcodeproj/project.pbxproj"

    # Create a backup
    cp "$project_file" "$project_file.bak"

    # Update the setting using sed
    # This replaces all occurrences of the setting in the project file
    sed -i '' "s/\(${setting_name} = \)[^;]*;/\1${new_value};/g" "$project_file"

    # Remove backup if successful
    rm "$project_file.bak"
}

show_current() {
    local marketing_version
    local build_number

    marketing_version=$(get_build_setting "MARKETING_VERSION")
    build_number=$(get_build_setting "CURRENT_PROJECT_VERSION")

    echo "Current version:"
    if [ -n "$marketing_version" ]; then
        echo "  $marketing_version"
    else
        echo "  (not set)"
    fi

    echo "Current build:"
    if [ -n "$build_number" ]; then
        echo "  $build_number"
    else
        echo "  (not set)"
    fi
}

increment_build() {
    local current_build
    current_build=$(get_build_setting "CURRENT_PROJECT_VERSION")

    if [ -z "$current_build" ]; then
        echo "Error: Could not read current build number"
        exit 1
    fi

    local new_build=$((current_build + 1))
    echo "Incrementing build number from $current_build to $new_build..."
    update_build_setting "CURRENT_PROJECT_VERSION" "$new_build"
    echo ""
    show_current
}

set_version() {
    local version=$1
    echo "Setting marketing version to $version..."
    update_build_setting "MARKETING_VERSION" "$version"
    echo ""
    show_current
}

set_build() {
    local build=$1
    echo "Setting build number to $build..."
    update_build_setting "CURRENT_PROJECT_VERSION" "$build"
    echo ""
    show_current
}

bump_version() {
    local bump_type=$1
    local current_version
    current_version=$(get_build_setting "MARKETING_VERSION")

    if [ -z "$current_version" ]; then
        echo "Error: Could not read current version"
        exit 1
    fi

    # Validate version format
    if ! [[ "$current_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: Invalid version format: $current_version"
        echo "Expected format: X.Y.Z (e.g., 3.2.1)"
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
