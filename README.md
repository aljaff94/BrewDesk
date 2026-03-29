# BrewDesk

A native macOS GUI for [Homebrew](https://brew.sh) -- manage packages, casks, taps, services, and more without touching the terminal.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift 6](https://img.shields.io/badge/Swift-6-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Install

**Homebrew (recommended):**

```bash
brew install --cask --no-quarantine https://raw.githubusercontent.com/aljaff94/BrewDesk/main/Casks/brewdesk.rb
```

**Download:**

Grab the latest `.dmg` or `.zip` from [Releases](https://github.com/aljaff94/BrewDesk/releases/latest).

**Build from source:**

```bash
git clone https://github.com/aljaff94/BrewDesk.git
cd BrewDesk
brew install xcodegen
xcodegen generate
open BrewDesk.xcodeproj
```

## Features

### Package Management
- Browse, search, install, upgrade, and uninstall formulae and casks
- Online search across all of Homebrew -- find and install any package
- Version picker for formulae with multiple versions (e.g. `node@20`, `node@22`)
- Bulk select and upgrade/uninstall multiple packages at once
- Inline upgrade button for outdated packages
- Sort by name, type, status, or install date

### Dashboard
- At-a-glance stats: installed formulae, casks, outdated count, disk usage
- Quick actions: Update Homebrew, Upgrade All, Cleanup, Run Doctor
- Recent operation history

### Services
- Start, stop, and restart Homebrew services (PostgreSQL, Redis, etc.)
- View status, user, and PID at a glance

### Taps
- View installed taps with formula/cask counts
- Add and remove third-party taps

### Dependencies
- Interactive dependency tree for any installed formula
- Reverse dependency lookup -- see what depends on a package before removing it

### Maintenance
- Run `brew doctor` and view warnings
- Preview and run cleanup to free disk space
- Cache size monitoring

### Brewfile
- Export your setup as a Brewfile, JSON, or plain text
- Import a Brewfile to reproduce your setup on another machine
- Drag & drop Brewfile import

### More
- Global search bar -- search from any view
- Disk usage per package in detail view
- Install date tracking
- Open installed cask apps directly from the list
- Operation history with full terminal output
- Cancel running operations
- Menu bar extra with outdated package count
- Auto-update on launch and periodic update checks
- macOS notifications for new updates
- Skeleton loading states

## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `Cmd+F` | Focus search |
| `Cmd+Shift+H` | Operation history |
| `Delete` | Uninstall selected packages |

## Requirements

- macOS 14.0 (Sonoma) or later
- [Homebrew](https://brew.sh) installed

## License

MIT
