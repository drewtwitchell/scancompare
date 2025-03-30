#!/usr/bin/env python3
import sys
import os
import importlib.util

# Create test results directory if it doesn't exist
os.makedirs("test_results", exist_ok=True)

# Save original stdout to restore later
original_stdout = sys.stdout

# Create a log file for output
log_file = open('test_results/parser_log.txt', 'w')
sys.stdout = log_file

# Import functions from scancompare script directly
try:
    print("Attempting to import from scancompare script...")
    
    # Path to the scancompare script file - adjust if needed
    script_path = "scancompare"
    
    # Dynamic import of the script as a module
    spec = importlib.util.spec_from_file_location("scancompare_module", script_path)
    scancompare_module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(scancompare_module)
    
    # Get the required functions
    handle_cli_args = scancompare_module.handle_cli_args
    get_automation_mode = scancompare_module.get_automation_mode
    
    print("Successfully imported functions from scancompare script")
except Exception as e:
    print(f"Failed to import from scancompare script: {e}")
    # Create a basic report to prevent the cat command from failing
    with open('test_results/parser_results.md', 'w') as f:
        f.write("| Test Case | Status | Details |\n")
        f.write("|-----------|--------|--------|\n")
        f.write(f"| Import Test | ❌ FAIL | {e} |\n\n")
        f.write("## Summary\n")
        f.write("Passed 0 out of 1 tests\n")
        f.write("\n⚠️ **Critical Issue**: Failed to import from scancompare script\n")
    sys.stdout = original_stdout
    log_file.close()
    sys.exit(1)

# Test results tracking
results = []

# Test --auto flag
try:
    # Save original args
    original_argv = sys.argv.copy()
    
    # Set up test args
    sys.argv = ['scancompare', 'nginx:latest', '--auto']
    
    # Call the function to parse args
    auto_args = handle_cli_args()
    
    # Get the automation mode
    auto_mode = get_automation_mode(auto_args)
    
    # Check if it worked correctly
    if auto_args.auto and auto_mode == "auto":
        results.append(("Auto Flag Test", "PASS", f"Auto flag detected correctly: {auto_args.auto}, Mode: {auto_mode}"))
        print(f"Auto Flag Test: PASS - Auto flag detected correctly: {auto_args.auto}, Mode: {auto_mode}")
    else:
        results.append(("Auto Flag Test", "FAIL", f"Auto flag not detected correctly: {auto_args.auto}, Mode: {auto_mode}"))
        print(f"Auto Flag Test: FAIL - Auto flag not detected correctly: {auto_args.auto}, Mode: {auto_mode}")
    
    # Restore original args
    sys.argv = original_argv.copy()
except Exception as e:
    results.append(("Auto Flag Test", "ERROR", f"Exception occurred: {e}"))
    print(f"Auto Flag Test: ERROR - Exception occurred: {e}")
    # Restore original args
    sys.argv = original_argv.copy() if 'original_argv' in locals() else sys.argv

# Test --mock-yes flag
try:
    # Save original args
    original_argv = sys.argv.copy()
    
    # Set up test args
    sys.argv = ['scancompare', 'nginx:latest', '--mock-yes']
    
    # Call the function to parse args
    yes_args = handle_cli_args()
    
    # Get the automation mode
    yes_mode = get_automation_mode(yes_args)
    
    # Check if it worked correctly
    if yes_args.mock_yes and yes_mode == "yes":
        results.append(("Mock-Yes Flag Test", "PASS", f"Mock-yes flag detected correctly: {yes_args.mock_yes}, Mode: {yes_mode}"))
        print(f"Mock-Yes Flag Test: PASS - Mock-yes flag detected correctly: {yes_args.mock_yes}, Mode: {yes_mode}")
    else:
        results.append(("Mock-Yes Flag Test", "FAIL", f"Mock-yes flag not detected correctly: {yes_args.mock_yes}, Mode: {yes_mode}"))
        print(f"Mock-Yes Flag Test: FAIL - Mock-yes flag not detected correctly: {yes_args.mock_yes}, Mode: {yes_mode}")
    
    # Restore original args
    sys.argv = original_argv.copy()
except Exception as e:
    results.append(("Mock-Yes Flag Test", "ERROR", f"Exception occurred: {e}"))
    print(f"Mock-Yes Flag Test: ERROR - Exception occurred: {e}")
    # Restore original args
    sys.argv = original_argv.copy() if 'original_argv' in locals() else sys.argv

# Test --mock-no flag
try:
    # Save original args
    original_argv = sys.argv.copy()
    
    # Set up test args
    sys.argv = ['scancompare', 'nginx:latest', '--mock-no']
    
    # Call the function to parse args
    no_args = handle_cli_args()
    
    # Get the automation mode
    no_mode = get_automation_mode(no_args)
    
    # Check if it worked correctly
    if no_args.mock_no and no_mode == "no":
        results.append(("Mock-No Flag Test", "PASS", f"Mock-no flag detected correctly: {no_args.mock_no}, Mode: {no_mode}"))
        print(f"Mock-No Flag Test: PASS - Mock-no flag detected correctly: {no_args.mock_no}, Mode: {no_mode}")
    else:
        results.append(("Mock-No Flag Test", "FAIL", f"Mock-no flag not detected correctly: {no_args.mock_no}, Mode: {no_mode}"))
        print(f"Mock-No Flag Test: FAIL - Mock-no flag not detected correctly: {no_args.mock_no}, Mode: {no_mode}")
    
    # Restore original args
    sys.argv = original_argv.copy()
except Exception as e:
    results.append(("Mock-No Flag Test", "ERROR", f"Exception occurred: {e}"))
    print(f"Mock-No Flag Test: ERROR - Exception occurred: {e}")
    # Restore original args
    sys.argv = original_argv.copy() if 'original_argv' in locals() else sys.argv

# Test conflict detection
conflict_test_passed = False
try:
    # Save original args and globals
    original_argv = sys.argv.copy()
    
    # Track exit calls instead of actually exiting
    class ExitCatcher:
        def __init__(self):
            self.exit_called = False
            self.exit_code = None
        
        def exit(self, code=0):
            self.exit_called = True
            self.exit_code = code
            raise SystemExit(code)
    
    # Create exit catcher
    exit_catcher = ExitCatcher()
    original_sys_exit = sys.exit
    sys.exit = exit_catcher.exit
    
    # Set up test args
    sys.argv = ['scancompare', 'nginx:latest', '--auto', '--mock-yes']
    
    try:
        # This should raise SystemExit if the conflict detection works
        handle_cli_args()
        # If we get here, the conflict detection failed
        results.append(("Flag Conflict Test", "FAIL", "Multiple flags should have been rejected but weren't"))
        print("Flag Conflict Test: FAIL - Multiple flags should have been rejected but weren't")
    except SystemExit:
        # This is expected behavior
        conflict_test_passed = True
        results.append(("Flag Conflict Test", "PASS", "Multiple flags correctly rejected"))
        print("Flag Conflict Test: PASS - Multiple flags correctly rejected")
    
    # Restore original sys.exit
    sys.exit = original_sys_exit
    
    # Restore original args
    sys.argv = original_argv.copy()
except Exception as e:
    results.append(("Flag Conflict Test", "ERROR", f"Unexpected exception: {e}"))
    print(f"Flag Conflict Test: ERROR - Unexpected exception: {e}")
    # Restore original sys.exit if changed
    if 'original_sys_exit' in locals():
        sys.exit = original_sys_exit
    # Restore original args
    sys.argv = original_argv.copy() if 'original_argv' in locals() else sys.argv

# Restore stdout
sys.stdout = original_stdout
log_file.close()

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