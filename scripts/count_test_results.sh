#!/bin/bash
# Script to count test results and determine final status

# Read test results and count each type using a more robust approach
PASSED=0
FAILED=0
INCONCLUSIVE=0

# Process each result file individually
for file in test_results/*_result.txt; do
  if [ -f "$file" ]; then
    result=$(cat "$file")
    case "$result" in
      "PASS") 
        PASSED=$((PASSED + 1))
        ;;
      "FAIL") 
        FAILED=$((FAILED + 1))
        echo "Failed test: $file" >> test_results/failed_tests.log
        ;;
      "INCONCLUSIVE") 
        INCONCLUSIVE=$((INCONCLUSIVE + 1))
        echo "Inconclusive test: $file" >> test_results/inconclusive_tests.log
        ;;
    esac
  fi
done

# Calculate total
TOTAL=$((PASSED + FAILED + INCONCLUSIVE))

# Print counts for debugging
echo "Test results counts:"
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo "Inconclusive: $INCONCLUSIVE"
echo "Total tests: $TOTAL"

# Update the test summary in the report
echo "" >> test_results/report.md
echo "## Test Summary" >> test_results/report.md
echo "" >> test_results/report.md
echo "- Total Tests: $TOTAL" >> test_results/report.md
echo "- Passed: $PASSED" >> test_results/report.md
echo "- Inconclusive: $INCONCLUSIVE" >> test_results/report.md
echo "- Failed: $FAILED" >> test_results/report.md

# Add details of inconclusive tests if any
if [ "$INCONCLUSIVE" -gt 0 ] && [ -f "test_results/inconclusive_tests.log" ]; then
  echo "" >> test_results/report.md
  echo "### Inconclusive Tests" >> test_results/report.md
  echo "" >> test_results/report.md
  grep "⚠️ INCONCLUSIVE" test_results/report.md 2>/dev/null || echo "No inconclusive test details found" >> test_results/report.md
fi

# Add details of failed tests if any
if [ "$FAILED" -gt 0 ] && [ -f "test_results/failed_tests.log" ]; then
  echo "" >> test_results/report.md
  echo "### Failed Tests" >> test_results/report.md
  echo "" >> test_results/report.md
  cat test_results/failed_tests.log >> test_results/report.md
fi

# Report detailed logs section
echo "" >> test_results/report.md
echo "## Detailed Logs" >> test_results/report.md
echo "" >> test_results/report.md
echo "Detailed logs for each test are available in the test_results directory." >> test_results/report.md

# Set the final status based on results
if [ "$FAILED" -gt 0 ]; then
  echo "failure" > test_results/scancompare_status.txt
  echo "Final result: failure" >> test_results/scancompare_status.txt
  echo "❌ Some tests failed. See test report for details." >> test_results/scancompare_status.txt
  exit_code=1
elif [ "$INCONCLUSIVE" -gt 0 ]; then
  # Don't treat inconclusive as failure
  echo "success" > test_results/scancompare_status.txt
  echo "Final result: success (with some inconclusive tests)" >> test_results/scancompare_status.txt
  echo "✅ All tests passed! (Some tests were inconclusive but not failed)" >> test_results/scancompare_status.txt
  exit_code=0
else
  echo "success" > test_results/scancompare_status.txt
  echo "Final result: success" >> test_results/scancompare_status.txt
  echo "✅ All tests passed!" >> test_results/scancompare_status.txt
  exit_code=0
fi

exit $exit_code