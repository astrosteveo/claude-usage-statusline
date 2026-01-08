#!/bin/bash
set -e

# Claude Usage Status Line Installer
# https://github.com/YOUR_USERNAME/claude-usage-statusline

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

echo "Claude Usage Status Line Installer"
echo "==================================="
echo

# Check dependencies
echo "Checking dependencies..."
command -v jq >/dev/null 2>&1 || { echo "Error: jq is required. Install with: sudo apt install jq (or brew install jq)"; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "Error: python3 is required."; exit 1; }
echo "  jq: OK"
echo "  python3: OK"
echo

# Create .claude directory
mkdir -p "$CLAUDE_DIR"

# Copy files
echo "Installing files..."
cp "$SCRIPT_DIR/statusline.sh" "$CLAUDE_DIR/"
cp "$SCRIPT_DIR/usage_server.py" "$CLAUDE_DIR/"
chmod +x "$CLAUDE_DIR/statusline.sh" "$CLAUDE_DIR/usage_server.py"
echo "  ~/.claude/statusline.sh: OK"
echo "  ~/.claude/usage_server.py: OK"
echo

# Update settings.json
echo "Configuring Claude Code..."
if [ -f "$SETTINGS_FILE" ]; then
    # Check if statusLine already exists
    if grep -q '"statusLine"' "$SETTINGS_FILE" 2>/dev/null; then
        echo "  statusLine already configured in settings.json"
    else
        # Add statusLine to existing settings
        tmp=$(mktemp)
        jq '. + {"statusLine": {"type": "command", "command": "~/.claude/statusline.sh", "padding": 0}}' "$SETTINGS_FILE" > "$tmp"
        mv "$tmp" "$SETTINGS_FILE"
        echo "  Added statusLine to settings.json"
    fi
else
    # Create new settings file
    cat > "$SETTINGS_FILE" << 'EOF'
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh",
    "padding": 0
  }
}
EOF
    echo "  Created settings.json with statusLine"
fi
echo

# Get org ID
echo "==================================="
echo "SETUP: Get your Organization ID"
echo "==================================="
echo
echo "1. Go to https://claude.ai/settings/usage"
echo "2. Open browser console (F12 → Console)"
echo "3. Run this command:"
echo
echo '   document.cookie.match(/lastActiveOrg=([^;]+)/)?.[1] || "Check Network tab"'
echo
echo "4. Copy the org ID (looks like: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)"
echo

read -p "Enter your Organization ID (or press Enter to skip): " ORG_ID

if [ -n "$ORG_ID" ]; then
    echo
    echo "==================================="
    echo "YOUR BOOKMARKLET"
    echo "==================================="
    echo
    echo "Create a bookmark in your browser with this URL:"
    echo
    echo "javascript:(async()=>{const r=await fetch('/api/organizations/${ORG_ID}/usage',{credentials:'include'});const d=await r.json();await fetch('http://localhost:9847/',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(d)});alert('Updated!')})()"
    echo

    # Save org ID for reference
    echo "$ORG_ID" > "$CLAUDE_DIR/.usage_org_id"
fi

echo
echo "==================================="
echo "INSTALLATION COMPLETE"
echo "==================================="
echo
echo "To use:"
echo "  1. Start the server:  python3 ~/.claude/usage_server.py &"
echo "  2. Click your bookmarklet while on claude.ai"
echo "  3. Restart Claude Code to see the status line"
echo
echo "Optional: Auto-start server on login by adding to ~/.bashrc:"
echo '  pgrep -f usage_server.py >/dev/null || nohup python3 ~/.claude/usage_server.py >/dev/null 2>&1 &'
echo
