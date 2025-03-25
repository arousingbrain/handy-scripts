#!/bin/bash
# This script compares two Maven dependency tree files and reports dependencies
# that exist in both files but have different versions.
# When ONLY_LESS is set to 1, only those dependencies where FILE1's version is less than FILE2's are shown.

# Hardcoded configuration:
FILE1="dependency_tree_file1.txt"
FILE2="dependency_tree_file2.txt"
ONLY_LESS=1  # Set to 1 to show only dependencies with FILE1's version < FILE2's; set to 0 to show all differing versions.

# Function to compare two version strings.
# Returns 0 (true) if $1 is strictly less than $2.
version_lt() {
    if [ "$1" = "$2" ]; then
       return 1
    fi
    if [ "$(printf "%s\n%s\n" "$1" "$2" | sort -V | head -n1)" = "$1" ]; then
       return 0
    else
       return 1
    fi
}

# Check that the required files exist.
if [ ! -f "$FILE1" ]; then
  echo "Error: $FILE1 not found."
  exit 1
fi

if [ ! -f "$FILE2" ]; then
  echo "Error: $FILE2 not found."
  exit 1
fi

# Extract dependencies in "group:artifact version" format.
# This assumes Maven output lines are in the format:
#   groupId:artifactId:packaging:version[:scope]
grep -oE '[a-zA-Z0-9_.-]+:[a-zA-Z0-9_.-]+:[^:]+:[^:]+' "$FILE1" | \
  awk -F: '{print $1 ":" $2, $4}' | sort > deps1.txt

grep -oE '[a-zA-Z0-9_.-]+:[a-zA-Z0-9_.-]+:[^:]+:[^:]+' "$FILE2" | \
  awk -F: '{print $1 ":" $2, $4}' | sort > deps2.txt

echo "Common dependencies with different versions:"
if [ "$ONLY_LESS" -eq 1 ]; then
    # For each common dependency, show it only if FILE1's version is less than FILE2's.
    join -j 1 deps1.txt deps2.txt | while read -r key ver1 ver2; do
         if version_lt "$ver1" "$ver2"; then
             echo "$key version1=$ver1 version2=$ver2"
         fi
    done
else
    # Otherwise, show all common dependencies where the versions differ.
    join -j 1 deps1.txt deps2.txt | awk '$2 != $3 {print $1, "version1="$2, "version2="$3}'
fi

# Clean up temporary files.
rm deps1.txt deps2.txt
