#!/usr/bin/env python3
import sys
import os
import subprocess

# Create test results directory if it doesn't exist
os.makedirs("test_results", exist_ok=True)

# Create a log file for output
with open('test_results/parser_log.txt', 'w') as log_file:
    log_file.write("Starting CLI argument tests\n")
    
    # Track test results
    results = []
    
    # Test --auto flag via CLI
    try:
        log_file.write("Testing --auto flag...\n")
        output = subprocess.run(
            ['./scancompare', '--help'], 
            capture_output=True, 
            text=True, 
            env=dict(os.environ, SCANCOMPARE_UPDATED="1")
        )
        
        if "--auto" in output.stdout:
            results.append(("Auto Flag Test", "PASS", "Auto flag found in help text"))
            log_file.write("Auto Flag Test: PASS - Flag found in help text\n")
        else:
            results.append(("Auto Flag Test", "FAIL", "Auto flag not found in help text"))
            log_file.write("Auto Flag Test: FAIL - Flag not found in help text\n")
    except Exception as e:
        results.append(("Auto Flag Test", "ERROR", f"Exception occurred: {e}"))
        log_file.write(f"Auto Flag Test: ERROR - Exception occurred: {e}\n")
    
    # Test --mock-yes flag via CLI
    try:
        log_file.write("Testing --mock-yes flag...\n")
        output = subprocess.run(
            ['./scancompare', '--help'], 
            capture_output=True, 
            text=True,
            env=dict(os.environ, SCANCOMPARE_UPDATED="1")
        )
        
        if "--mock-yes" in output.stdout:
            results.append(("Mock-Yes Flag Test", "PASS", "Mock-yes flag found in help text"))
            log_file.write("Mock-Yes Flag Test: PASS - Flag found in help text\n")
        else:
            results.append(("Mock-Yes Flag Test", "FAIL", "Mock-yes flag not found in help text"))
            log_file.write("Mock-Yes Flag Test: FAIL - Flag not found in help text\n")
    except Exception as e:
        results.append(("Mock-Yes Flag Test", "ERROR", f"Exception occurred: {e}"))
        log_file.write(f"Mock-Yes Flag Test: ERROR - Exception occurred: {e}\n")
    
    # Test --mock-no flag via CLI
    try:
        log_file.write("Testing --mock-no flag...\n")
        output = subprocess.run(
            ['./scancompare', '--help'], 
            capture_output=True, 
            text=True,
            env=dict(os.environ, SCANCOMPARE_UPDATED="1")
        )
        
        if "--mock-no" in output.stdout:
            results.append(("Mock-No Flag Test", "PASS", "Mock-no flag found in help text"))
            log_file.write("Mock-No Flag Test: PASS - Flag found in help text\n")
        else:
            results.append(("Mock-No Flag Test", "FAIL", "Mock-no flag not found in help text"))
            log_file.write("Mock-No Flag Test: FAIL - Flag not found in help text\n")
    except Exception as e:
        results.append(("Mock-No Flag Test", "ERROR", f"Exception occurred: {e}"))
        log_file.write(f"Mock-No Flag Test: ERROR - Exception occurred: {e}\n")
    
    # Test flag conflict detection
    conflict_test_passed = False
    try:
        log_file.write("Testing flag conflict detection...\n")
        output = subprocess.run(
            ['./scancompare', 'nginx:latest', '--auto', '--mock-yes'], 
            capture_output=True, 
            text=True,
            env=dict(os.environ, SCANCOMPARE_UPDATED="1")
        )
        
        if "Only one automation flag" in output.stderr or "Only one automation flag" in output.stdout:
            conflict_test_passed = True
            results.append(("Flag Conflict Test", "PASS", "Multiple flags correctly rejected"))
            log_file.write("Flag Conflict Test: PASS - Multiple flags correctly rejected\n")
        else:
            results.append(("Flag Conflict Test", "FAIL", "Multiple flags should have been rejected but weren't"))
            log_file.write("Flag Conflict Test: FAIL - Multiple flags should have been rejected but weren't\n")
    except Exception as e:
        results.append(("Flag Conflict Test", "ERROR", f"Unexpected exception: {e}"))
        log_file.write(f"Flag Conflict Test: ERROR - Unexpected exception: {e}\n")

# Write results to markdown
with open('test_results/parser_results.md', 'w') as f:
    f.write("| Test Case | Status | Details |\n")
    f.write("|-----------|--------|--------|\n")
    
    for test, status, details in results:
        status_icon = "✅" if status == "PASS" else "❌"
        f.write(f"| {test} | {status_icon} {status} | {details} |\n")
    
    # Summary
    passed = sum(1 for _, status, _ in results if status == "PASS")
    total = len(results)
    f.write(f"\n## Summary\n")
    f.write(f"Passed {passed} out of {total} tests\n")
    
    if not conflict_test_passed:
        f.write("\n⚠️ **Critical Issue**: Flag conflict detection is not working properly\n")

# Exit with error if any test failed
if passed < total:
    sys.exit(1)