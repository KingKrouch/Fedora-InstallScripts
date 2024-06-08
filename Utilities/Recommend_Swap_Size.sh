#!/usr/bin/env bash
# This script essentially gives you the recommended amount of RAM that you should use for your swap partition/file if you want to use hibernation mode. At least according to this: https://itsfoss.com/swap-size/

# Get the currently available amount of system memory in GB.
total_memory=$(free -g | awk '/^Mem:/{print $2}')
echo "Total physical RAM: $total_memory GB"

# Check if the total memory is less than or equal to 1.0 GB.
if (( $(echo "$total_memory <= 1.0" | bc -l) )); then
    # Convert swap size to GB (2 times the total memory).
    swap_size=$(awk "BEGIN {printf \"%.2f\", $total_memory * 2}")
else # Calculate the Square root of our RAM, so we can have adequate swap size to enable hibernation.
    # Calculate square root of total memory and round the result to the nearest whole number.
    square_root_memory=$(echo "sqrt($total_memory)" | bc -l)
    rounded_memory=$(printf "%.0f" "$square_root_memory")
    # Sum the rounded square root value with the original total memory.
    swap_size=$(awk "BEGIN {printf \"%.2f\", $rounded_memory + $total_memory}")
fi
# Now we finally give the user the recommended swap size.
echo "Recommended Swap Size: $swap_size GB"