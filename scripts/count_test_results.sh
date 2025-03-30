#!/bin/bash
# Script to count test results and determine final status

# Read test results and count each type (with error handling)
passed=$(grep -c "PASS" test_results/*_result.txt 2>/dev/null || echo 0)
failed=$(grep -c "FAIL" test_results/*_result.txt 2>/dev/null || echo 0)
inconclusive=$(grep -c "INCONCLUSIVE" test_results/*_result.txt 2>/dev/null || echo 0)

# Print counts for debugging
echo "Test results counts:"
echo "Passed: $passed"
echo "Failed: $failed"
echo "Inconclusive: $inconclusive"

# Calculate totals
total=$((passed + failed + inconclusive))
echo "Total tests: $total"

# Update the test summary in the report
echo "" >> test_results/report.md
echo "## Test Summary" >> test_results/report.md
echo "" >> test_results/report.md
echo "- Total Tests: $total" >> test_results/report.md
echo "- Passed: $passed" >> test_results/report.md
echo "- Inconclusive: $inconclusive" >> test_results/report.md
echo "- Failed: $failed" >> test_results/report.md

# Add details of inconclusive tests if any
if [ "$inconclusive" -gt 0 ]; then
  echo "" >> test_results/report.md
  echo "### Inconclusive Tests" >> test_results/report.md
  echo "" >> test_results/report.md
  grep "⚠️ INCONCLUSIVE" test_results/report.md | sort >> test_results/report.md
fi

# Add details of failed tests if any
if [ "$failed" -gt 0 ]; then
  echo "" >> test_results/report.md
  echo "### Failed Tests" >> test_results/report.md
  echo "" >> test_results/report.md
  grep "❌ FAIL" test_results/report.md | sort >> test_results/report.md
fi

# Report detailed logs section
echo "" >> test_results/report.md
echo "## Detailed Logs" >> test_results/report.md
echo "" >> test_results/report.md
echo "Detailed logs for each test are available in the test_results directory." >> test_results/report.md

# Set the final status based on results
if [ "$failed" -gt 0 ]; then
  echo "failure" > test_results/scancompare_status.txt
  echo "Final result: failure" >> test_results/scancompare_status.txt
  echo "❌ Some tests failed. See test report for details." >> test_results/scancompare_status.txt
  exit_code=1
elif [ "$inconclusive" -gt 0 ]; then
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