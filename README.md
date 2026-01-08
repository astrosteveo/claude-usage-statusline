# Claude Code Usage Status Line

Display your real-time Claude.ai usage limits (session quota, weekly quota) in Claude Code's status bar.

![Status Line Example](https://img.shields.io/badge/5h-8%25-green) ![](https://img.shields.io/badge/7d-2%25-green) ![](https://img.shields.io/badge/Sonnet-1%25-green)

## Features

- Shows 5-hour session usage with countdown to reset
- Shows 7-day total usage
- Shows 7-day Sonnet-specific usage
- Color-coded: green (<50%), yellow (50-79%), red (80%+)
- Warns when cache is stale (>1 hour old)

## Requirements

- Claude Code CLI
- Python 3.6+
- `jq` command-line tool
- Firefox (or any browser with console access)

## Quick Install

```bash
git clone https://github.com/YOUR_USERNAME/claude-usage-statusline.git
cd claude-usage-statusline
./install.sh
```

## Manual Install

1. Copy files to `~/.claude/`:
   ```bash
   cp statusline.sh usage_server.py ~/.claude/
   chmod +x ~/.claude/statusline.sh ~/.claude/usage_server.py
   ```

2. Add to your `~/.claude/settings.json`:
   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "~/.claude/statusline.sh",
       "padding": 0
     }
   }
   ```

3. Get your Organization ID:
   - Go to https://claude.ai/settings/usage
   - Open browser console (F12)
   - Run: `console.log(JSON.parse(localStorage.getItem('lastActiveOrg') || document.cookie.match(/lastActiveOrg=([^;]+)/)?.[1] || 'Check Network tab'))`
   - Or look at the Network tab for requests to `/api/organizations/YOUR_ORG_ID/usage`

4. Create the bookmarklet (see below)

## Usage

### Option 1: Browser Console (Manual)

While on claude.ai, open F12 console and run:

```javascript
// Replace YOUR_ORG_ID with your actual org ID
fetch('/api/organizations/YOUR_ORG_ID/usage',{credentials:'include'})
  .then(r=>r.json())
  .then(d=>{
    console.log(JSON.stringify(d));
    navigator.clipboard.writeText(JSON.stringify(d));
    alert('Copied to clipboard!');
  })
```

Then save to file:
```bash
# Linux
xclip -selection clipboard -o > ~/.claude/usage_cache.json

# macOS
pbpaste > ~/.claude/usage_cache.json
```

### Option 2: Local Server + Bookmarklet (Recommended)

1. Start the server:
   ```bash
   # Run in background
   nohup python3 ~/.claude/usage_server.py > /dev/null 2>&1 &

   # Or run in foreground to see updates
   python3 ~/.claude/usage_server.py
   ```

2. Create a bookmarklet in your browser. Add a new bookmark with this URL (replace `YOUR_ORG_ID`):
   ```
   javascript:(async()=>{const r=await fetch('/api/organizations/YOUR_ORG_ID/usage',{credentials:'include'});const d=await r.json();await fetch('http://localhost:9847/',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(d)});alert('Usage updated!')})()
   ```

3. Click the bookmarklet while on any claude.ai page to update your usage cache.

### Auto-start Server on Login (Optional)

Add to your `~/.bashrc` or `~/.zshrc`:
```bash
# Start Claude usage server if not running
if ! pgrep -f "usage_server.py" > /dev/null; then
    nohup python3 ~/.claude/usage_server.py > /dev/null 2>&1 &
fi
```

## How It Works

1. Cloudflare protects claude.ai with TLS fingerprinting, blocking automated tools like curl
2. Your browser can access the API normally (it passes Cloudflare's checks)
3. The bookmarklet fetches your usage data and POSTs it to a local server
4. The server saves the data to `~/.claude/usage_cache.json`
5. Claude Code's status line reads from this cache file

## Files

| File | Description |
|------|-------------|
| `statusline.sh` | Status line script that reads cache and formats output |
| `usage_server.py` | Local HTTP server that receives usage data from browser |
| `install.sh` | Installation script |

## Troubleshooting

**Status line shows `[No usage data]`**
- Make sure `~/.claude/usage_cache.json` exists
- Update it using the bookmarklet or console method

**Status line shows `[stale]`**
- Your cache is over 1 hour old
- Click the bookmarklet to refresh

**Bookmarklet doesn't work**
- Make sure you're on a claude.ai page
- Check that the server is running: `pgrep -f usage_server.py`
- Check browser console for errors

**Server won't start**
- Port 9847 might be in use: `lsof -i :9847`
- Kill existing process: `pkill -f usage_server.py`

## Security Notes

- The server only listens on localhost (127.0.0.1)
- Only accepts POST requests from claude.ai (CORS restricted)
- No sensitive data is transmitted externally

## License

MIT - Do whatever you want with it.

## Credits

Built with Claude Code, ironically to monitor Claude Code usage.
