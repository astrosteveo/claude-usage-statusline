#!/bin/bash

# Claude.ai Usage Status Line for Claude Code
# https://github.com/YOUR_USERNAME/claude-usage-statusline

# Configuration
CACHE_FILE="${CLAUDE_USAGE_CACHE:-$HOME/.claude/usage_cache.json}"
CACHE_WARN_AGE=3600  # Warn if cache is older than 1 hour (in seconds)

# Read input from Claude Code (optional, for context)
input=$(cat)

# Check cache file exists
if [ ! -f "$CACHE_FILE" ]; then
    if [ -n "$input" ]; then
        context_size=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
        usage=$(echo "$input" | jq '.context_window.current_usage')
        if [ "$usage" != "null" ]; then
            current=$(echo "$usage" | jq '.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens')
            pct=$((current * 100 / context_size))
            echo "Ctx: ${pct}% | [No usage cache]"
        else
            echo "[No usage cache]"
        fi
    else
        echo "[No usage cache]"
    fi
    exit 0
fi

# Read cache
usage_json=$(cat "$CACHE_FILE")

# Check if cache is valid JSON
if ! echo "$usage_json" | jq -e . >/dev/null 2>&1; then
    echo "[Invalid cache]"
    exit 0
fi

# Check cache age and add warning indicator
cache_age=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)))
stale_indicator=""
if [ "$cache_age" -gt "$CACHE_WARN_AGE" ]; then
    stale_indicator=" [stale]"
fi

# Extract utilization percentages
five_hour=$(echo "$usage_json" | jq -r '.five_hour.utilization // 0' | awk '{printf "%.0f", $1}')
seven_day=$(echo "$usage_json" | jq -r '.seven_day.utilization // 0' | awk '{printf "%.0f", $1}')
seven_day_sonnet=$(echo "$usage_json" | jq -r '.seven_day_sonnet.utilization // 0' | awk '{printf "%.0f", $1}')

# Extract reset times
five_hour_reset=$(echo "$usage_json" | jq -r '.five_hour.resets_at // ""')
if [ -n "$five_hour_reset" ] && [ "$five_hour_reset" != "null" ]; then
    # Calculate time until reset (works on both Linux and macOS)
    if date -d "$five_hour_reset" +%s >/dev/null 2>&1; then
        reset_epoch=$(date -d "$five_hour_reset" +%s)
    else
        # macOS fallback
        reset_epoch=$(date -jf "%Y-%m-%dT%H:%M:%S" "${five_hour_reset%%.*}" +%s 2>/dev/null || echo 0)
    fi
    now_epoch=$(date +%s)
    mins_left=$(( (reset_epoch - now_epoch) / 60 ))
    if [ "$mins_left" -gt 0 ]; then
        if [ "$mins_left" -ge 60 ]; then
            hours_left=$((mins_left / 60))
            mins_remain=$((mins_left % 60))
            reset_display="${hours_left}h${mins_remain}m"
        else
            reset_display="${mins_left}m"
        fi
    else
        reset_display="now"
    fi
else
    reset_display=""
fi

# Color codes based on utilization
color_for_pct() {
    local pct=$1
    if [ "$pct" -ge 80 ]; then
        echo -e "\033[31m"  # Red
    elif [ "$pct" -ge 50 ]; then
        echo -e "\033[33m"  # Yellow
    else
        echo -e "\033[32m"  # Green
    fi
}
reset="\033[0m"

# Build status line
c5=$(color_for_pct "$five_hour")
c7=$(color_for_pct "$seven_day")
cs=$(color_for_pct "$seven_day_sonnet")

# Format output
if [ -n "$reset_display" ] && [ "$reset_display" != "now" ]; then
    echo -e "5h: ${c5}${five_hour}%${reset} (${reset_display}) | 7d: ${c7}${seven_day}%${reset} | Son: ${cs}${seven_day_sonnet}%${reset}${stale_indicator}"
else
    echo -e "5h: ${c5}${five_hour}%${reset} | 7d: ${c7}${seven_day}%${reset} | Son: ${cs}${seven_day_sonnet}%${reset}${stale_indicator}"
fi
