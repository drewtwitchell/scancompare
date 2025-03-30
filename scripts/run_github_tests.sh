#!/bin/bash
# Script to run GitHub integration tests

# Make sure test_results directory exists
mkdir -p test_results

# Source the GitHub tests configuration
source ./scripts/configure_github_tests.sh

echo "Running GitHub integration tests..."
echo "RUN_GITHUB_TESTS: $RUN_GITHUB_TESTS"
echo "RUN_GITHUB_ADVANCED_TESTS: $RUN_GITHUB_ADVANCED_TESTS"

if [ "$RUN_GITHUB_TESTS" = "true" ]; then
  # Run GHAS test
  if [ -f "scripts/expect/test_repo_url_ghas.exp" ]; then
    echo "Running GHAS integration test..."
    scripts/expect/test_repo_url_ghas.exp
  else
    echo "ERROR: test_repo_url_ghas.exp script not found!"
    echo "INCONCLUSIVE" > test_results/test_repo_url_ghas_result.txt
    echo "REPO URL GHAS TEST: INCONCLUSIVE - Test script not found" > test_results/test_repo_url_ghas.log
  fi
  
  # Run GitHub Pages test
  if [ -f "scripts/expect/test_url_repo_gh_pages.exp" ]; then
    echo "Running GitHub Pages test..."
    scripts/expect/test_url_repo_gh_pages.exp
  else
    echo "ERROR: test_url_repo_gh_pages.exp script not found!"
    echo "INCONCLUSIVE" > test_results/test_url_repo_gh_pages_result.txt
    echo "REPO URL GH-PAGES TEST: INCONCLUSIVE - Test script not found" > test_results/test_url_repo_gh_pages.log
  fi
  
  # Run comprehensive test
  if [ -f "scripts/expect/test_url_repo_comprehensive.exp" ]; then
    echo "Running comprehensive GitHub test..."
    scripts/expect/test_url_repo_comprehensive.exp
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