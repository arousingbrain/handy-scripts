#!/bin/bash
# Usage: ./compare_dependencies.sh file1.txt file2.txt

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <dependency_tree_file1> <dependency_tree_file2>"
  exit 1
fi

FILE1="$1"
FILE2="$2"

# Extract dependencies in "group:artifact version" format.
# This grep+awk combo looks for lines with at least 4 colon-separated fields.
# Adjust the regex if your dependency output format differs.
grep -oE '[a-zA-Z0-9_.-]+:[a-zA-Z0-9_.-]+:[^:]+:[^:]+' "$FILE1" | \
  awk -F: '{print $1 ":" $2, $4}' | sort > deps1.txt

grep -oE '[a-zA-Z0-9_.-]+:[a-zA-Z0-9_.-]+:[^:]+:[^:]+' "$FILE2" | \
  awk -F: '{print $1 ":" $2, $4}' | sort > deps2.txt

echo "Common dependencies with different versions:"
# Use join to combine on the dependency key (group:artifact)
# Then use awk to print only lines where the version from file1 ($2) and file2 ($3) differ.
join -j 1 deps1.txt deps2.txt | awk '$2 != $3 {print $1, "version1="$2, "version2="$3}'

# Clean up temporary files
rm deps1.txt deps2.txt