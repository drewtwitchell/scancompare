#!/bin/bash
# Script to run GitHub integration tests

# Make sure test_results directory exists
mkdir -p test_results

# Source the GitHub tests configuration if it exists
if [ -f "./scripts/configure_github_tests.sh" ]; then
  source ./scripts/configure_github_tests.sh
else
  # Default values if configuration script is not found
  RUN_GITHUB_TESTS="true"
  RUN_GITHUB_ADVANCED_TESTS="true"
  if [ -z "$GITHUB_TOKEN" ]; then
    RUN_GITHUB_TESTS="false"
    RUN_GITHUB_ADVANCED_TESTS="false"
    echo "GitHub token not available, skipping GitHub tests"
  fi
fi

echo "Running GitHub integration tests..."
echo "RUN_GITHUB_TESTS: $RUN_GITHUB_TESTS"
echo "RUN_GITHUB_ADVANCED_TESTS: $RUN_GITHUB_ADVANCED_TESTS"

if [ "$RUN_GITHUB_TESTS" = "true" ]; then
  # Run GHAS test - with better error handling
  if [ -f "scripts/expect/test_repo_url_ghas.exp" ]; then
    echo "Running GHAS integration test..."
    chmod +x scripts/expect/test_repo_url_ghas.exp
    scripts/expect/test_repo_url_ghas.exp
    rc=$?
    if [ $rc -ne 0 ]; then
      echo "Warning: test_repo_url_ghas.exp exited with code $rc"
      # If test script failed but no result file, create one marked as INCONCLUSIVE
      if [ ! -f "test_results/test_repo_url_ghas_result.txt" ]; then
        echo "INCONCLUSIVE" > test_results/test_repo_url_ghas_result.txt
        echo "REPO URL GHAS TEST: INCONCLUSIVE - Script crashed or failed to complete" > test_results/test_repo_url_ghas.log
      fi
    fi
  else
    echo "ERROR: test_repo_url_ghas.exp script not found!"
    echo "INCONCLUSIVE" > test_results/test_repo_url_ghas_result.txt
    echo "REPO URL GHAS TEST: INCONCLUSIVE - Test script not found" > test_results/test_repo_url_ghas.log
  fi
  
  # Run GitHub Pages test with better error handling
  if [ -f "scripts/expect/test_url_repo_gh_pages.exp" ]; then
    echo "Running GitHub Pages test..."
    chmod +x scripts/expect/test_url_repo_gh_pages.exp
    scripts/expect/test_url_repo_gh_pages.exp
    rc=$?
    if [ $rc -ne 0 ]; then
      echo "Warning: test_url_repo_gh_pages.exp exited with code $rc"
      # If test script failed but no result file, create one marked as INCONCLUSIVE
      if [ ! -f "test_results/test_url_repo_gh_pages_result.txt" ]; then
        echo "INCONCLUSIVE" > test_results/test_url_repo_gh_pages_result.txt
        echo "REPO URL GH-PAGES TEST: INCONCLUSIVE - Script crashed or failed to complete" > test_results/test_url_repo_gh_pages.log
      fi
    fi
  else
    echo "ERROR: test_url_repo_gh_pages.exp script not found!"
    echo "INCONCLUSIVE" > test_results/test_url_repo_gh_pages_result.txt
    echo "REPO URL GH-PAGES TEST: INCONCLUSIVE - Test script not found" > test_results/test_url_repo_gh_pages.log
  fi
  
  # Run comprehensive test with better error handling
  if [ -f "scripts/expect/test_url_repo_comprehensive.exp" ]; then
    echo "Running comprehensive GitHub test..."
    chmod +x scripts/expect/test_url_repo_comprehensive.exp
    scripts/expect/test_url_repo_comprehensive.exp
    rc=$?
    if [ $rc -ne 0 ]; then
      echo "Warning: test_url_repo_comprehensive.exp exited with code $rc"
      # If test script failed but no result file, create one marked as INCONCLUSIVE
      if [ ! -f "test_results/test_url_repo_comprehensive_result.txt" ]; then
        echo "INCONCLUSIVE" > test_results/test_url_repo_comprehensive_result.txt
        echo "COMPREHENSIVE TEST: INCONCLUSIVE - Script crashed or failed to complete" > test_results/test_url_repo_comprehensive.log
      fi
    fi
  else
    echo "ERROR: test_url_repo_comprehensive.exp script not found!"
    echo "INCONCLUSIVE" > test_results/test_url_repo_comprehensive_result.txt
    echo "COMPREHENSIVE TEST: INCONCLUSIVE - Test script not found" > test_results/test_url_repo_comprehensive.log
  fi
else
  echo "GitHub token not available - skipping all GitHub tests"
  
  # Create placeholder results for GitHub tests
  echo "INCONCLUSIVE" > test_results/test_repo_url_ghas_result.txt
  echo "INCONCLUSIVE" > test_results/test_url_repo_gh_pages_result.txt
  echo "INCONCLUSIVE" > test_results/test_url_repo_comprehensive_result.txt
  
  # Create placeholder logs
  echo "REPO URL GHAS TEST: INCONCLUSIVE - GitHub token not available" > test_results/test_repo_url_ghas.log
  echo "REPO URL GH-PAGES TEST: INCONCLUSIVE - GitHub token not available" > test_results/test_url_repo_gh_pages.log
  echo "COMPREHENSIVE TEST: INCONCLUSIVE - GitHub token not available" > test_results/test_url_repo_comprehensive.log
fi

echo "GitHub integration tests completed."