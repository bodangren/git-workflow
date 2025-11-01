#!/bin/bash
# This script scaffolds the basic directory structure for a SynthesisFlow project.

set -e

usage() {
    echo "Usage: $0 [-d <directory>]"
    echo "  -d <directory>: The root directory of the project to initialize. Defaults to the current directory."
    exit 1
}

PROJECT_DIR="."

while getopts ":d:" opt; do
  case ${opt} in
    d )
      PROJECT_DIR=$OPTARG
      ;;
    \? )
      echo "Invalid option: $OPTARG" 1>&2
      usage
      ;;
    : )
      echo "Invalid option: $OPTARG requires an argument" 1>&2
      usage
      ;;
  esac
done
shift $((OPTIND -1))

# Ensure the project directory exists
mkdir -p "$PROJECT_DIR"

echo "Initializing SynthesisFlow structure in $PROJECT_DIR..."
mkdir -p "$PROJECT_DIR/docs/specs"
mkdir -p "$PROJECT_DIR/docs/changes"
echo "Done."