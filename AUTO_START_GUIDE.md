# 🚀 Auto-Start Setup Complete!

## ✅ What's Been Configured

Your Claude Proxy Server is now set to **automatically start** when you log in to Windows!

### Files Created:

1. **[`start-claude-proxy.bat`](./start-claude-proxy.bat)** - Single-click script to start the proxy
2. **Startup Shortcut** - Located in your Windows Startup folder
   - Path: `C:\Users\Administrator\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\Claude-Proxy.lnk`

### How It Works:

- When you log in to Windows, the shortcut runs automatically
- It executes `pm2 resurrect` which restores your saved PM2 processes
- The proxy server starts in the background
- A window briefly appears showing the status, then minimizes

## 🔄 After Restart

**Automatic (Recommended):**
- Just log in to Windows - the proxy starts automatically!
- Wait 5-10 seconds for it to fully start
- Open VSCode and use Claude Code immediately

**Manual (If Needed):**
If for any reason the auto-start doesn't work, just double-click:
```
C:\Users\Administrator\Downloads\free-claude-code\start-claude-proxy.bat
```

## 🎯 Single-Action Commands

### To Start the Proxy (if stopped):
```cmd
start-claude-proxy.bat
```
Or from anywhere:
```cmd
pm2 resurrect
```

### To Check Status:
```cmd
pm2 status
```

### To Restart:
```cmd
pm2 restart claude-proxy
```

### To Stop:
```cmd
pm2 stop claude-proxy
```

## 📍 Quick Access

You can also create a desktop shortcut for easy access:

1. Right-click on your Desktop
2. Select **New > Shortcut**
3. Enter location: `C:\Users\Administrator\Downloads\free-claude-code\start-claude-proxy.bat`
4. Name it: "Start Claude Proxy"
5. Click Finish

## 🧪 Test It Now

To test if auto-start will work after restart:

1. Stop the current proxy:
   ```cmd
   pm2 delete claude-proxy
   ```

2. Run the startup script:
   ```cmd
   start-claude-proxy.bat
   ```

3. Check if it started:
   ```cmd
   pm2 status
   ```

You should see `claude-proxy` as `online`!

## 🔧 Disable Auto-Start (Optional)

If you ever want to disable auto-start:

**Option 1: Delete the shortcut**
```cmd
del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\Claude-Proxy.lnk"
```

**Option 2: Use Windows Settings**
1. Press `Win + R`
2. Type: `shell:startup`
3. Delete the "Claude-Proxy" shortcut

## 💡 Pro Tips

1. **Check if running:** Before manually starting, check `pm2 status` to avoid duplicates

2. **View logs:** If something's wrong, check logs with `pm2 logs claude-proxy`

3. **Save changes:** After modifying `.env`, restart with `pm2 restart claude-proxy`

4. **Multiple restarts:** The proxy survives multiple restarts - PM2 remembers it!

## 🎉 Summary

**Before:** You had to manually run commands after every restart

**Now:** 
- ✅ Restart your computer
- ✅ Log in to Windows
- ✅ Proxy starts automatically
- ✅ Open VSCode and code with Claude immediately!

**Single action needed:** Just log in to Windows! 🚀

---

**Everything is ready!** Your Claude Code setup will work automatically after every restart.
