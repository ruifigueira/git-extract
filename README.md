# Git Extract

A Git utility script that extracts changes from specific files or directories and rebases them in a single commit.

## Overview

`git-extract.sh` solves a specific git workflow problem: when you have a feature branch with changes across multiple files, but you only want to extract and apply changes from specific paths while maintaining a clean commit history.

The script creates a diff of only the specified paths, applies them to a clean branch based on your target branch, and then rebases your current branch onto this clean state.

## ⚠️ Disclaimer

This script was heavily vibe coded. While it includes safety checks and has been tested, use it at your own risk and always ensure you have backups of your work. The script provides revert commands, but it's recommended to test it on non-critical branches first.

## Requirements

- Git (any recent version)
- Bash shell
- Unix-like environment (Linux, macOS, WSL)

## Installation

1. Clone or download the script:
   ```bash
   curl -O https://raw.githubusercontent.com/ruifigueira/git-extract/main/git-extract.sh
   ```

2. Make it executable:
   ```bash
   chmod +x git-extract.sh
   ```

## Usage

### Basic Syntax

```bash
git-extract.sh --base <base-branch> --paths <path1,path2,path3> [--message <commit-message>]
```

### Options

| Option | Short | Description | Required |
|--------|-------|-------------|----------|
| `--base` | `-b` | Base branch to rebase from (e.g., `main`, `staging`) | ✅ |
| `--paths` | `-p` | Comma-separated list of files/folders to extract | ✅ |
| `--message` | `-m` | Custom commit message (auto-generated if not provided) | ❌ |
| `--help` | `-h` | Show usage information | ❌ |

### Examples

#### Extract specific directories
```bash
./git-extract.sh --base staging --paths browser-host,workers/core
```

#### Extract multiple files with custom message
```bash
./git-extract.sh -b main -p src/components,src/utils,package.json -m "feat: update components and utilities"
```

#### Extract single file
```bash
./git-extract.sh --base main --paths README.md
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

