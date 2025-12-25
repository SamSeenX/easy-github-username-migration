# RenGitHub - Safely Change Your GitHub Username

[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux-blue.svg)]()
[![Shell](https://img.shields.io/badge/Shell-Bash-orange.svg)]()

**RenGitHub** is a powerful bash script that helps you safely migrate your GitHub username across all your repositories. It clones your repos, finds all references to your old username, shows you a detailed report, and only applies changes after your confirmation.

## 🤔 Why Change Your GitHub Username?

Common reasons developers want to change their username:
- Your username feels **outdated or unprofessional** (e.g., `coolgamer2005` → `jsmith`)
- You want to **rebrand** to a simpler name
- Your username contains **prefixes you no longer like** (e.g., `MrSamSeen` → `SamSeenDev`)
- You're **transitioning** to using your real name professionally

## ⚠️ What Happens When You Change Your GitHub Username?

When you change your username on GitHub:
- ✅ **Repositories stay intact** - all your repos move to the new username
- ✅ **GitHub creates redirects** - old URLs forward to new ones temporarily
- ✅ **Stars and forks preserved** - nothing is lost
- ⚠️ **Old URLs expire** - when someone else claims your old username
- ⚠️ **References in code break** - README links, package configs, etc.
- ⚠️ **Local git remotes break** - your local repos point to old URLs

**This script fixes the last three problems automatically!**

## ✨ Features

- 📥 **Batch clone** all your repositories
- 🔍 **Deep scan** for username references in all files
- 📊 **Detailed report** before any changes
- ✋ **Confirmation required** - nothing happens without your approval
- 🔄 **Automatic commit & push** to all repos
- 📋 **Final report** with success/failure summary
- 🎨 **Beautiful CLI** with colors and progress indicators

## 📸 How It Works

```
┌─────────────────────────────────────────────────────────────┐
│  Phase 1: Setup                                             │
│  └─ Creates work directory, checks for repos.txt           │
├─────────────────────────────────────────────────────────────┤
│  Phase 2: Clone                                             │
│  └─ Downloads all repos listed in repos.txt                │
├─────────────────────────────────────────────────────────────┤
│  Phase 3: Analyze                                           │
│  └─ Scans all files, generates detailed change report      │
├─────────────────────────────────────────────────────────────┤
│  Phase 4: Review & Confirm                                  │
│  └─ Shows report, waits for your approval                  │
├─────────────────────────────────────────────────────────────┤
│  Phase 5: Apply Changes                                     │
│  └─ Replaces text, commits, pushes to GitHub               │
├─────────────────────────────────────────────────────────────┤
│  Phase 6: Final Report                                      │
│  └─ Shows success/failure summary for each repo            │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### 1. Clone this repository
```bash
git clone https://github.com/YOUR_USERNAME/RenGitHub.git
cd RenGitHub
chmod +x rengithub.sh
```

### 2. Configure your usernames
Edit the script and update these lines at the top:
```bash
OLD_NAME="your_old_username"
NEW_NAME="your_new_username"
```

### 3. First run (creates repos.txt template)
```bash
./rengithub.sh
```
This creates `~/github_migration/repos.txt` - add your repository names there.

### 4. Auto-populate with GitHub CLI (optional)
```bash
# Install GitHub CLI if needed
brew install gh
gh auth login

# List all your repos automatically
gh repo list YOUR_OLD_USERNAME --limit 100 --json name -q '.[].name' >> ~/github_migration/repos.txt
```

### 5. Run the migration
```bash
./rengithub.sh
```

The script will:
1. Clone all listed repositories
2. Scan for references to your old username
3. Show you a detailed report
4. **Wait for your confirmation**
5. Apply changes and push
6. Show final results

## 📋 Step-by-Step Guide

### Before Running the Script

1. **Choose your new username** - Check availability on GitHub first!
2. **Change your username on GitHub.com**
   - Go to: Settings → Account → Change username
   - GitHub will set up redirects from old URLs
3. **Install prerequisites:**
   ```bash
   # macOS
   brew install git gh
   
   # Linux (Ubuntu/Debian)
   sudo apt install git gh
   ```

### The Migration Workflow

```bash
# Step 1: Clone the tool
git clone https://github.com/YOUR_USERNAME/RenGitHub.git
cd RenGitHub

# Step 2: Edit configuration
nano rengithub.sh  # Change OLD_NAME and NEW_NAME

# Step 3: First run - creates repos list
./rengithub.sh

# Step 4: Edit repos list (or use gh CLI to auto-fill)
nano ~/github_migration/repos.txt

# Step 5: Run full migration
./rengithub.sh

# Step 6: Review report and confirm when prompted
```

## 🛠️ Commands

| Command | Description |
|---------|-------------|
| `./rengithub.sh` | Run full migration workflow |
| `./rengithub.sh clone` | Clone repos only |
| `./rengithub.sh analyze` | Analyze and generate report |
| `./rengithub.sh apply` | Apply changes (requires prior analysis) |
| `./rengithub.sh clean` | Remove work directory |
| `./rengithub.sh --help` | Show help |

## 📁 Work Directory Structure

All work happens in `~/github_migration/`:

```
~/github_migration/
├── repos.txt            # Your list of repositories
├── repos/               # Cloned repositories
│   ├── repo1/
│   ├── repo2/
│   └── ...
├── migration_report.txt # Detailed change report
├── pending_changes.txt  # List of files to modify
└── final_report.txt     # Success/failure summary
```

## 🔒 Safety Features

- **Dry run by default** - Reports are generated before any changes
- **Explicit confirmation required** - You must type 'y' to proceed
- **Original repos untouched** - Works on fresh clones, not your local repos
- **Detailed logging** - Every action is logged for review
- **Excludes binary files** - Only text files are modified

## ❓ FAQ

### Will this break my existing local repos?
No! The script clones fresh copies into `~/github_migration/repos/`. Your existing local repositories are completely untouched.

### What if I have private repos?
Make sure you're authenticated with GitHub CLI (`gh auth login`) or have SSH keys set up.

### What file types are scanned?
The script scans: `.md`, `.txt`, `.sh`, `.py`, `.rb`, `.html`, `.json`, `.yml`, `.yaml`, `.toml`, `.js`, `.ts`, `.go`, `.rs`, and more.

### Can I run this multiple times?
Yes! If repos are already cloned, they'll be skipped. You can re-run analysis and apply as needed.

### What about package registries (npm, PyPI, etc.)?
This script updates references in your code. You may still need to:
- Update package.json `repository` field
- Re-publish to npm with new URLs
- Update PyPI package metadata

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📝 License

MIT License - see [LICENSE](LICENSE) file for details.

## ☕ Support

If this tool saved you hours of manual work, consider:
- ⭐ Starring this repository
- 🐛 Reporting issues
- 💡 Suggesting improvements

---

Created with ❤️ by [SamSeen](https://github.com/samseenio)
