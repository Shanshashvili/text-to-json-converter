#!/bin/bash

# Check if output file is provided
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 output.txt"
  exit 1
fi

input_file="$1"

# Parse the test name
test_name=$(grep '\[ Asserts Samples \]' "$input_file" | sed 's/\[ \([^]]*\) \],.*/\1/')

# Parse individual test results and format as JSON
tests=$(awk '/(not ok|ok)/ {
    status=($1=="ok") ? "true" : "false";
    duration=$(NF); # Get the last field (duration)
    $1=$2=$NF=""; # Remove status, test number, and duration fields
    name=substr($0, 1); # Extract full line after status
    gsub(/^[[:space:]]*[0-9]+[[:space:]]+/, "", name); # Remove leading numbers and spaces
    gsub(/[[:space:]]*,[[:space:]]*$/, "", name); # Remove trailing comma and spaces
    gsub(/^[[:space:]]*/, "", name); # Remove leading spaces
    gsub(/[[:space:]]*$/, "", name); # Remove trailing spaces
    if (name !~ /^[[:space:]]*$/) { # Check if name is not empty
        printf "{\"name\":\"" name "\",\"status\":" status ",\"duration\":\"" duration "\"},"
    }
}' "$input_file")

# Remove trailing comma from tests array
tests=$(echo "$tests" | sed 's/,$//')

# Parse summary information
summary=$(grep "tests passed" "$input_file" | sed -E 's/([0-9]+) \(of ([0-9]+)\) tests passed, ([0-9]+) tests failed, rated as ([0-9.]+)%, spent ([0-9]+ms)/{"success":\1,"failed":\3,"rating":\4,"duration":"\5"}/')

# Construct JSON using jq
echo "{\"testName\":\"$test_name\",\"tests\":[$tests],\"summary\":$summary}" | ./jq '.' > output.json

echo "JSON output written to output.json"
