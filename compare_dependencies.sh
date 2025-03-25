#!/bin/bash
# Usage: compare-deps.sh [-l] <dependency_tree_file1> <dependency_tree_file2>
#   -l  : Show only dependencies from FILE1 that have a lower version than those in FILE2.

# Check for the -l flag.
ONLY_LESS=0
if [ "$#" -lt 2 ]; then
  echo "Usage: $0 [-l] <dependency_tree_file1> <dependency_tree_file2>"
  exit 1
fi

if [ "$1" == "-l" ]; then
  ONLY_LESS=1
  shift
fi

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 [-l] <dependency_tree_file1> <dependency_tree_file2>"
  exit 1
fi

FILE1="$1"
FILE2="$2"

# If the -l flag is set, ensure dpkg is available.
if [ "$ONLY_LESS" -eq 1 ] && ! command -v dpkg > /dev/null; then
    echo "Error: dpkg command not found. Please install dpkg or remove the -l flag."
    exit 1
fi

# Extract dependencies in "group:artifact version" format.
# Adjust the regex if your Maven dependency output differs.
grep -oE '[a-zA-Z0-9_.-]+:[a-zA-Z0-9_.-]+:[^:]+:[^:]+' "$FILE1" | \
  awk -F: '{print $1 ":" $2, $4}' | sort > deps1.txt

grep -oE '[a-zA-Z0-9_.-]+:[a-zA-Z0-9_.-]+:[^:]+:[^:]+' "$FILE2" | \
  awk -F: '{print $1 ":" $2, $4}' | sort > deps2.txt

echo "Common dependencies with different versions:"

if [ "$ONLY_LESS" -eq 1 ]; then
    # For each common dependency, print it only if the version from FILE1 is less than FILE2's.
    join -j 1 deps1.txt deps2.txt | while read -r key ver1 ver2; do
         # dpkg --compare-versions returns 0 if the first version is less than the second.
         if dpkg --compare-versions "$ver1" lt "$ver2"; then
             echo "$key version1=$ver1 version2=$ver2"
         fi
    done
else
    # Show all common dependencies where the versions differ.
    join -j 1 deps1.txt deps2.txt | awk '$2 != $3 {print $1, "version1="$2, "version2="$3}'
fi

# Clean up temporary files.
rm deps1.txt deps2.txt
