#!/bin/bash
# Get the full battery status (e.g., "Charging", "Discharging", "Not charging")
battery_status=$(acpi -b | awk -F', ' '{print $1}' | sed 's/ battery//')

# Get the battery percentage (e.g., "75%")
battery_percentage=$(acpi -b | grep -oP '(?<=, )\d+%' | head -n 1)

# Output both status and percentage
echo "$battery_status $battery_percentage"

