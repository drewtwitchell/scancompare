#!/bin/bash
# Script to configure GitHub tests

# Check if GitHub token is available and set advanced tests flag
if [ -n "$GITHUB_TOKEN" ]; then
  RUN_GITHUB_TESTS="true"
  
  # Enable advanced GitHub tests 
  RUN_GITHUB_ADVANCED_TESTS="true"
  echo "GitHub token available, running all GitHub tests including advanced tests"
else
  RUN_GITHUB_TESTS="false"
  RUN_GITHUB_ADVANCED_TESTS="false"
  echo "GitHub token not available, skipping GitHub tests"
fi

# Export the variables so they're available to subprocesses
export RUN_GITHUB_TESTS
export RUN_GITHUB_ADVANCED_TESTS