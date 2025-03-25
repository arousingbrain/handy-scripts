#!/bin/bash
# This script compares two Maven dependency tree files and reports dependencies
# that exist in both files but have different versions.
# When ONLY_LESS is set to 1, only those dependencies where FILE1's version is less than FILE2's are shown.

# Hardcoded configuration:
FILE1="dependency_tree_file1.txt"
FILE2="dependency_tree_file2.txt"
ONLY_LESS=1  # Set to 1 to filter for FILE1 version < FILE2 version; 0 to show all differing versions.

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
  echo "Error: $FILE1 not found." >&2
  exit 1
fi

if [ ! -f "$FILE2" ]; then
  echo "Error: $FILE2 not found." >&2
  exit 1
fi

# Extract dependencies in "group:artifact version" format.
# This assumes Maven dependency output lines like:
#   groupId:artifactId:packaging:version[:scope]
# We remove duplicates using sort -u.
grep -oE '[a-zA-Z0-9_.-]+:[a-zA-Z0-9_.-]+:[^:]+:[^:]+' "$FILE1" | \
  awk -F: '{print $1 ":" $2, $4}' | sort -u > deps1.txt

grep -oE '[a-zA-Z0-9_.-]+:[a-zA-Z0-9_.-]+:[^:]+:[^:]+' "$FILE2" | \
  awk -F: '{print $1 ":" $2, $4}' | sort -u > deps2.txt

echo "Common dependencies with different versions:"
if [ "$ONLY_LESS" -eq 1 ]; then
    # Use process substitution to avoid subshell issues with a piped while loop.
    while IFS= read -r line; do
         key=$(echo "$line" | awk '{print $1}')
         ver1=$(echo "$line" | awk '{print $2}')
         ver2=$(echo "$line" | awk '{print $3}')
         # Only show if versions differ and FILE1's version is less than FILE2's.
         if [ "$ver1" != "$ver2" ] && version_lt "$ver1" "$ver2"; then
             echo "$key version1=$ver1 version2=$ver2"
         fi
    done < <(join -j 1 deps1.txt deps2.txt)
else
    join -j 1 deps1.txt deps2.txt | awk '$2 != $3 {print $1, "version1="$2, "version2="$3}'
fi

# Clean up temporary files.
rm deps1.txt deps2.txt
