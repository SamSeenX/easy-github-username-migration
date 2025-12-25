# Easy GitHub Username Migration

[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux-blue.svg)]()
[![Shell](https://img.shields.io/badge/Shell-Bash-orange.svg)]()

I recently changed my GitHub username and realized there's no easy way to update all the references scattered across my repositories — README links, git remotes, package configs, you name it. So I built **easy-github-username-migration** to handle it for me. It clones all your repos, finds every reference to your old username (case-insensitive!), shows you exactly what it'll change, and only applies updates after you confirm. I figured if I needed this, others probably do too — so here it is!

## 🤔 Why Change Your GitHub Username?

Common reasons developers want to change their username:
- Your username feels **outdated or unprofessional** (e.g., `coolgamer2005` → `jsmith`)
- You want to **rebrand** to a simpler name
- Your username contains **prefixes you no longer like** (e.g., `MrSamSeen` → `SamSeenX`)
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

- 🔐 **Interactive prompts** - enter usernames at runtime, no script editing needed
- 🔍 **Case-insensitive search** - finds `MrSamSeen`, `mrsamseen`, `MRSAMSEEN`, etc.
- 📥 **Batch clone** all your repositories
- 📊 **Sequential reports** - multiple runs create numbered reports (report.txt, report_1.txt, etc.)
- ✋ **Confirmation required** - nothing happens without your approval
- 🔄 **Automatic commit & push** to all repos
- 📋 **Final report** with success/failure summary
- 🎨 **Beautiful CLI** with colors and progress indicators

## 📸 How It Works

```
┌─────────────────────────────────────────────────────────────┐
│  Username Prompt                                            │
│  └─ Interactively asks for old and new usernames           │
├─────────────────────────────────────────────────────────────┤
│  Phase 1: Setup                                             │
│  └─ Creates work directory, checks for repos.txt           │
├─────────────────────────────────────────────────────────────┤
│  Phase 2: Clone                                             │
│  └─ Downloads all repos listed in repos.txt                │
├─────────────────────────────────────────────────────────────┤
│  Phase 3: Analyze                                           │
│  └─ Case-insensitive scan, generates detailed report       │
├─────────────────────────────────────────────────────────────┤
│  Phase 4: Review & Confirm                                  │
│  └─ Shows report, waits for your approval                  │
├─────────────────────────────────────────────────────────────┤
│  Phase 5: Apply Changes                                     │
│  └─ Replaces text (case-insensitive), commits, pushes      │
├─────────────────────────────────────────────────────────────┤
│  Phase 6: Final Report                                      │
│  └─ Shows success/failure summary for each repo            │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### 1. Clone this repository
```bash
git clone https://github.com/SamSeenX/easy-github-username-migration.git
cd easy-github-username-migration
chmod +x migrate.sh
```

### 2. First run (creates repos.txt template)
```bash
./migrate.sh
```
Enter your old and new usernames when prompted. This creates `~/github_migration/repos.txt`.

### 3. Populate your repository list

> **📋 Choose the right command based on your situation:**

#### If you HAVEN'T changed your username on GitHub yet:
```bash
# Use your CURRENT (old) username
gh repo list YOUR_OLD_USERNAME --limit 100 --json name -q '.[].name' >> ~/github_migration/repos.txt
```

#### If you HAVE already changed your username on GitHub:
```bash
# Use your NEW username
gh repo list YOUR_NEW_USERNAME --limit 100 --json name -q '.[].name' >> ~/github_migration/repos.txt
```

> 💡 **Requires GitHub CLI**: `brew install gh && gh auth login`

### 4. Run the migration
```bash
./migrate.sh
```

## 📋 Step-by-Step Guide

### Before Running the Script

1. **Choose your new username** - Check availability on GitHub first!
2. **Change your username on GitHub.com** (optional - can be done after cloning)
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
git clone https://github.com/SamSeenX/easy-github-username-migration.git
cd easy-github-username-migration

# Step 2: First run - prompts for usernames, creates repos list
./migrate.sh

# Step 3: Populate repos list (choose the appropriate command)
#   BEFORE renaming: gh repo list OLD_USERNAME --limit 100 --json name -q '.[].name' >> ~/github_migration/repos.txt
#   AFTER renaming:  gh repo list NEW_USERNAME --limit 100 --json name -q '.[].name' >> ~/github_migration/repos.txt

# Step 4: Run full migration
./migrate.sh

# Step 5: Review report and confirm when prompted
```

## 🛠️ Commands

| Command | Description |
|---------|-------------|
| `./migrate.sh` | Run full migration workflow |
| `./migrate.sh clone` | Clone repos only |
| `./migrate.sh analyze` | Analyze and generate report |
| `./migrate.sh apply` | Apply changes (requires prior analysis) |
| `./migrate.sh clean` | Remove work directory |
| `./migrate.sh --help` | Show help |

## 📁 Work Directory Structure

All work happens in `~/github_migration/`:

```
~/github_migration/
├── .config                    # Saved username configuration
├── .current_run               # Current run state
├── repos.txt                  # Your list of repositories
├── repos/                     # Cloned repositories
│   ├── repo1/
│   ├── repo2/
│   └── ...
├── migration_report.txt       # First run report
├── migration_report_1.txt     # Second run report
├── migration_report_2.txt     # Third run report (etc.)
├── migration_report_1_changes.txt  # Files to modify
└── final_report.txt           # Success/failure summary
```

## 🔒 Safety Features

- **Interactive prompts** - No need to edit script files, enter usernames at runtime
- **Case-insensitive matching** - Catches all variations of your username
- **Dry run by default** - Reports are generated before any changes
- **Explicit confirmation required** - You must type 'y' to proceed
- **Original repos untouched** - Works on fresh clones, not your local repos
- **Sequential reports** - Multiple runs don't overwrite previous reports
- **Detailed logging** - Every action is logged for review
- **Excludes binary files** - Only text files are modified

## ❓ FAQ

### Will this break my existing local repos?
No! The script clones fresh copies into `~/github_migration/repos/`. Your existing local repositories are completely untouched.

### What if I have private repos?
Make sure you're authenticated with GitHub CLI (`gh auth login`) or have SSH keys set up.

### Will it find `MrSamSeen` if I search for `mrsamseen`?
Yes! The search is **case-insensitive**, so it will find all variations like `MrSamSeen`, `mrsamseen`, `MRSAMSEEN`, etc.

### What file types are scanned?
The script scans: `.md`, `.txt`, `.sh`, `.py`, `.rb`, `.html`, `.json`, `.yml`, `.yaml`, `.toml`, `.js`, `.ts`, `.go`, `.rs`, and more.

### Can I run this multiple times?
Yes! Each run creates sequentially numbered reports (e.g., `migration_report.txt`, `migration_report_1.txt`, `migration_report_2.txt`). If repos are already cloned, they'll be skipped.

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
- ☕ Supporting me on [BuyMeACoffee](https://buymeacoffee.com/samseen)

---

Created with ❤️ by [SamSeen](https://buymeacoffee.com/samseen)
