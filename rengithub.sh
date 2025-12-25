#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
# RenGitHub - Safely Change Your GitHub Username
# https://github.com/YOUR_USERNAME/RenGitHub
#═══════════════════════════════════════════════════════════════════════════════
#
# This script helps you migrate your GitHub username across all repositories.
# It clones your repos, finds all references, shows a report, and only applies
# changes after your confirmation.
#
# Usage: ./rengithub.sh [command]
#   (no args)  - Run full migration workflow
#   clone      - Clone repos only
#   analyze    - Analyze and generate report
#   apply      - Apply changes (requires prior analysis)
#   clean      - Remove work directory
#   --help     - Show help
#
#═══════════════════════════════════════════════════════════════════════════════

#───────────────────────────────────────────────────────────────────────────────
# CONFIGURATION - Edit these values!
#───────────────────────────────────────────────────────────────────────────────

OLD_NAME="mrsamseen"       # Your current/old GitHub username
NEW_NAME="samseenio"       # Your new GitHub username

#───────────────────────────────────────────────────────────────────────────────
# Settings (usually don't need to change)
#───────────────────────────────────────────────────────────────────────────────

WORK_DIR="$HOME/github_migration"
REPOS_FILE="$WORK_DIR/repos.txt"
REPORT_FILE="$WORK_DIR/migration_report.txt"
CHANGES_FILE="$WORK_DIR/pending_changes.txt"
FINAL_REPORT="$WORK_DIR/final_report.txt"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Counters for final report
SUCCESS_COUNT=0
FAILURE_COUNT=0
SKIPPED_COUNT=0

#───────────────────────────────────────────────────────────────────────────────
# Helper Functions
#───────────────────────────────────────────────────────────────────────────────

print_header() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_step() {
    echo -e "${BLUE}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

show_help() {
    echo ""
    echo -e "${BOLD}RenGitHub - Safely Change Your GitHub Username${NC}"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  (no args)    Run full migration workflow"
    echo "  clone        Clone repos only"
    echo "  analyze      Analyze repos and generate report"
    echo "  apply        Apply changes (requires prior analysis)"
    echo "  clean        Remove work directory"
    echo "  --help, -h   Show this help"
    echo ""
    echo "Configuration:"
    echo "  Edit the OLD_NAME and NEW_NAME variables at the top of this script"
    echo ""
    echo "Work Directory: $WORK_DIR"
    echo ""
    echo "Example workflow:"
    echo "  1. Edit this script to set OLD_NAME and NEW_NAME"
    echo "  2. Run: ./rengithub.sh"
    echo "  3. Edit ~/github_migration/repos.txt to add your repos"
    echo "  4. Run: ./rengithub.sh again"
    echo ""
    exit 0
}

#───────────────────────────────────────────────────────────────────────────────
# Phase 1: Setup
#───────────────────────────────────────────────────────────────────────────────

setup() {
    print_header "Phase 1: Setup"

    # Validate configuration
    if [[ "$OLD_NAME" == "your_old_username" ]] || [[ "$NEW_NAME" == "your_new_username" ]]; then
        print_error "Please edit the script and set OLD_NAME and NEW_NAME!"
        echo ""
        echo "Open $(realpath "$0") and update these lines:"
        echo ""
        echo '  OLD_NAME="your_old_username"'
        echo '  NEW_NAME="your_new_username"'
        echo ""
        exit 1
    fi

    # Create work directory
    mkdir -p "$WORK_DIR/repos"
    print_success "Created work directory: $WORK_DIR"

    # Check if repos.txt exists
    if [[ ! -f "$REPOS_FILE" ]]; then
        print_warning "repos.txt not found. Creating template..."
        cat > "$REPOS_FILE" << EOF
# RenGitHub - Repository List
# ═══════════════════════════════════════════════════════════════
# Add one repository name per line (just the repo name, not full URL)
# Lines starting with # are ignored
#
# Example:
# MyProject
# another-repo
# homebrew-tap
#
# ───────────────────────────────────────────────────────────────
# TIP: Auto-populate with GitHub CLI:
#
#   gh repo list $OLD_NAME --limit 100 --json name -q '.[].name' >> $REPOS_FILE
#
# (requires: brew install gh && gh auth login)
# ═══════════════════════════════════════════════════════════════

EOF
        echo ""
        print_warning "Please edit the repos.txt file and add your repositories:"
        echo -e "  ${YELLOW}$REPOS_FILE${NC}"
        echo ""
        echo "You can also auto-populate it with GitHub CLI:"
        echo -e "  ${CYAN}gh repo list $OLD_NAME --limit 100 --json name -q '.[].name' >> $REPOS_FILE${NC}"
        echo ""
        exit 0
    fi

    # Check if repos.txt has actual repos (not just comments)
    local repo_count=$(grep -v "^#" "$REPOS_FILE" | grep -v "^$" | wc -l | xargs)
    if [[ "$repo_count" -eq 0 ]]; then
        print_warning "repos.txt is empty. Please add your repository names."
        echo -e "  ${YELLOW}$REPOS_FILE${NC}"
        exit 0
    fi

    print_success "Found repos.txt with $repo_count repositories"
}

#───────────────────────────────────────────────────────────────────────────────
# Phase 2: Clone Repositories
#───────────────────────────────────────────────────────────────────────────────

clone_repos() {
    print_header "Phase 2: Clone Repositories"

    local clone_count=0
    local skip_count=0
    local fail_count=0

    while IFS= read -r repo || [[ -n "$repo" ]]; do
        # Skip comments and empty lines
        [[ "$repo" =~ ^#.*$ ]] && continue
        [[ -z "${repo// }" ]] && continue

        repo=$(echo "$repo" | xargs)  # Trim whitespace
        local repo_path="$WORK_DIR/repos/$repo"

        if [[ -d "$repo_path" ]]; then
            print_warning "Already exists, skipping: $repo"
            ((skip_count++))
            continue
        fi

        print_step "Cloning: $repo"
        
        # Try HTTPS first, then SSH
        if git clone "https://github.com/$OLD_NAME/$repo.git" "$repo_path" 2>/dev/null; then
            print_success "Cloned: $repo"
            ((clone_count++))
        elif git clone "git@github.com:$OLD_NAME/$repo.git" "$repo_path" 2>/dev/null; then
            print_success "Cloned (SSH): $repo"
            ((clone_count++))
        else
            print_error "Failed to clone: $repo"
            ((fail_count++))
        fi

    done < "$REPOS_FILE"

    echo ""
    print_success "Cloned $clone_count repositories"
    [[ $skip_count -gt 0 ]] && echo "  Skipped (already exist): $skip_count"
    [[ $fail_count -gt 0 ]] && print_warning "Failed: $fail_count"
}

#───────────────────────────────────────────────────────────────────────────────
# Phase 3: Analyze & Generate Report
#───────────────────────────────────────────────────────────────────────────────

analyze_repos() {
    print_header "Phase 3: Analyzing Repositories"

    # Clear previous reports
    > "$REPORT_FILE"
    > "$CHANGES_FILE"

    local total_files=0
    local total_occurrences=0

    echo "═══════════════════════════════════════════════════════════════" >> "$REPORT_FILE"
    echo "  MIGRATION REPORT: $OLD_NAME → $NEW_NAME" >> "$REPORT_FILE"
    echo "  Generated: $(date)" >> "$REPORT_FILE"
    echo "═══════════════════════════════════════════════════════════════" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"

    for repo_path in "$WORK_DIR/repos"/*/; do
        [[ ! -d "$repo_path" ]] && continue

        local repo_name=$(basename "$repo_path")
        print_step "Analyzing: $repo_name"

        echo "───────────────────────────────────────────────────────────────" >> "$REPORT_FILE"
        echo "Repository: $repo_name" >> "$REPORT_FILE"
        echo "───────────────────────────────────────────────────────────────" >> "$REPORT_FILE"

        # Find all files with references (excluding .git and common ignored dirs)
        local found_files=$(grep -r "$OLD_NAME" "$repo_path" \
            --exclude-dir=.git \
            --exclude-dir=node_modules \
            --exclude-dir=vendor \
            --exclude-dir=venv \
            --exclude-dir=.venv \
            --exclude-dir=__pycache__ \
            --exclude-dir=dist \
            --exclude-dir=build \
            --exclude="*.pyc" \
            --exclude="*.pyo" \
            --exclude="*.so" \
            --exclude="*.dylib" \
            --exclude="*.dll" \
            --exclude="*.exe" \
            --exclude="*.bin" \
            --exclude="*.o" \
            --exclude="*.a" \
            --exclude="*.jar" \
            --exclude="*.class" \
            --exclude="*.png" \
            --exclude="*.jpg" \
            --exclude="*.jpeg" \
            --exclude="*.gif" \
            --exclude="*.ico" \
            --exclude="*.webp" \
            --exclude="*.svg" \
            --exclude="*.mp4" \
            --exclude="*.mp3" \
            --exclude="*.zip" \
            --exclude="*.tar" \
            --exclude="*.gz" \
            --exclude="*.DS_Store" \
            --exclude="package-lock.json" \
            --exclude="yarn.lock" \
            -l 2>/dev/null)

        if [[ -z "$found_files" ]]; then
            echo "  No references found." >> "$REPORT_FILE"
            echo "" >> "$REPORT_FILE"
            continue
        fi

        while IFS= read -r file; do
            [[ -z "$file" ]] && continue

            local rel_path="${file#$WORK_DIR/repos/}"
            local count=$(grep -o "$OLD_NAME" "$file" 2>/dev/null | wc -l | xargs)

            echo "  📄 $rel_path ($count occurrences)" >> "$REPORT_FILE"
            echo "$file" >> "$CHANGES_FILE"

            # Show preview of changes (first 5 matches)
            grep -n "$OLD_NAME" "$file" 2>/dev/null | head -5 | while read -r line; do
                echo "      $line" >> "$REPORT_FILE"
            done

            ((total_files++))
            ((total_occurrences += count))

        done <<< "$found_files"

        echo "" >> "$REPORT_FILE"
    done

    # Summary
    echo "═══════════════════════════════════════════════════════════════" >> "$REPORT_FILE"
    echo "  SUMMARY" >> "$REPORT_FILE"
    echo "═══════════════════════════════════════════════════════════════" >> "$REPORT_FILE"
    echo "  Files to modify:    $total_files" >> "$REPORT_FILE"
    echo "  Total occurrences:  $total_occurrences" >> "$REPORT_FILE"
    echo "  Old name:           $OLD_NAME" >> "$REPORT_FILE"
    echo "  New name:           $NEW_NAME" >> "$REPORT_FILE"
    echo "═══════════════════════════════════════════════════════════════" >> "$REPORT_FILE"

    echo ""
    print_success "Analysis complete!"
    echo ""
    echo "  Files to modify:   $total_files"
    echo "  Total occurrences: $total_occurrences"
    echo ""
    echo -e "  ${CYAN}Full report: $REPORT_FILE${NC}"
    echo ""
}

#───────────────────────────────────────────────────────────────────────────────
# Phase 4: Show Report & Confirm
#───────────────────────────────────────────────────────────────────────────────

show_report_and_confirm() {
    print_header "Phase 4: Review Changes"

    echo "Here's a preview of the changes:"
    echo ""
    cat "$REPORT_FILE"
    echo ""

    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}  ⚠️  WARNING: This will modify files and push to GitHub!${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${BOLD}Before proceeding, make sure you have already changed your${NC}"
    echo -e "${BOLD}username on GitHub.com: Settings → Account → Change username${NC}"
    echo ""
    echo "Options:"
    echo "  [y] Yes, apply changes and push to GitHub"
    echo "  [n] No, abort (keeps cloned repos for manual review)"
    echo "  [r] Review report again"
    echo ""
    read -p "Proceed with migration? [y/n/r]: " choice

    case "$choice" in
        y|Y)
            return 0
            ;;
        r|R)
            less "$REPORT_FILE"
            show_report_and_confirm
            ;;
        *)
            print_warning "Migration aborted. Cloned repos are in: $WORK_DIR/repos"
            exit 0
            ;;
    esac
}

#───────────────────────────────────────────────────────────────────────────────
# Phase 5: Apply Changes
#───────────────────────────────────────────────────────────────────────────────

apply_changes() {
    print_header "Phase 5: Applying Changes"

    > "$FINAL_REPORT"
    echo "═══════════════════════════════════════════════════════════════" >> "$FINAL_REPORT"
    echo "  FINAL MIGRATION REPORT" >> "$FINAL_REPORT"
    echo "  Completed: $(date)" >> "$FINAL_REPORT"
    echo "═══════════════════════════════════════════════════════════════" >> "$FINAL_REPORT"
    echo "" >> "$FINAL_REPORT"

    # First, update all files
    print_step "Updating file contents..."

    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        [[ ! -f "$file" ]] && continue

        # Detect OS for sed compatibility
        if [[ "$(uname)" == "Darwin" ]]; then
            # macOS
            if sed -i '' "s|$OLD_NAME|$NEW_NAME|g" "$file" 2>/dev/null; then
                print_success "Updated: ${file#$WORK_DIR/repos/}"
            else
                print_error "Failed to update: ${file#$WORK_DIR/repos/}"
            fi
        else
            # Linux
            if sed -i "s|$OLD_NAME|$NEW_NAME|g" "$file" 2>/dev/null; then
                print_success "Updated: ${file#$WORK_DIR/repos/}"
            else
                print_error "Failed to update: ${file#$WORK_DIR/repos/}"
            fi
        fi
    done < "$CHANGES_FILE"

    echo ""
    print_step "Committing and pushing changes..."
    echo ""

    # Now commit and push each repo
    for repo_path in "$WORK_DIR/repos"/*/; do
        [[ ! -d "$repo_path" ]] && continue

        local repo_name=$(basename "$repo_path")

        # Check if there are changes
        if [[ -z $(git -C "$repo_path" status --porcelain 2>/dev/null) ]]; then
            print_warning "$repo_name: No changes to commit"
            echo "⏭️  $repo_name: No changes (skipped)" >> "$FINAL_REPORT"
            ((SKIPPED_COUNT++))
            continue
        fi

        print_step "Processing: $repo_name"

        # Update remote URL to new username
        local old_remote=$(git -C "$repo_path" remote get-url origin 2>/dev/null)
        local new_remote="${old_remote//$OLD_NAME/$NEW_NAME}"
        git -C "$repo_path" remote set-url origin "$new_remote" 2>/dev/null

        # Stage, commit, and push
        git -C "$repo_path" add -A 2>/dev/null

        if git -C "$repo_path" commit -m "chore: migrate username from $OLD_NAME to $NEW_NAME

Updated all references to reflect the new GitHub username.
See: https://github.com/$NEW_NAME" 2>/dev/null; then
            if git -C "$repo_path" push origin HEAD 2>/dev/null; then
                print_success "$repo_name: Pushed successfully"
                echo "✅ $repo_name: Success" >> "$FINAL_REPORT"
                ((SUCCESS_COUNT++))
            else
                print_error "$repo_name: Push failed"
                echo "❌ $repo_name: Push failed (commit created locally)" >> "$FINAL_REPORT"
                ((FAILURE_COUNT++))
            fi
        else
            print_error "$repo_name: Commit failed"
            echo "❌ $repo_name: Commit failed" >> "$FINAL_REPORT"
            ((FAILURE_COUNT++))
        fi
    done

    # Final summary
    echo "" >> "$FINAL_REPORT"
    echo "═══════════════════════════════════════════════════════════════" >> "$FINAL_REPORT"
    echo "  SUMMARY" >> "$FINAL_REPORT"
    echo "═══════════════════════════════════════════════════════════════" >> "$FINAL_REPORT"
    echo "  ✅ Successful: $SUCCESS_COUNT" >> "$FINAL_REPORT"
    echo "  ❌ Failed:     $FAILURE_COUNT" >> "$FINAL_REPORT"
    echo "  ⏭️  Skipped:    $SKIPPED_COUNT" >> "$FINAL_REPORT"
    echo "═══════════════════════════════════════════════════════════════" >> "$FINAL_REPORT"
}

#───────────────────────────────────────────────────────────────────────────────
# Phase 6: Final Report
#───────────────────────────────────────────────────────────────────────────────

show_final_report() {
    print_header "Phase 6: Migration Complete!"

    cat "$FINAL_REPORT"

    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  🎉 Migration Complete!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "  ✅ Successful: $SUCCESS_COUNT"
    echo "  ❌ Failed:     $FAILURE_COUNT"
    echo "  ⏭️  Skipped:    $SKIPPED_COUNT"
    echo ""
    echo "  Reports saved to:"
    echo "    - $REPORT_FILE"
    echo "    - $FINAL_REPORT"
    echo ""

    if [[ $FAILURE_COUNT -gt 0 ]]; then
        print_warning "Some repositories failed. Check the cloned repos in:"
        echo "  $WORK_DIR/repos"
        echo ""
        echo "You may need to manually push these repos after fixing any issues."
    fi

    echo ""
    echo "Next steps:"
    echo "  1. Update your local development repos' remotes:"
    echo "     git remote set-url origin https://github.com/$NEW_NAME/REPO_NAME.git"
    echo ""
    echo "  2. Update any package registries (npm, PyPI, etc.)"
    echo ""
    echo "  3. Update bookmarks, documentation, and external links"
    echo ""
}

#───────────────────────────────────────────────────────────────────────────────
# Main
#───────────────────────────────────────────────────────────────────────────────

main() {
    print_header "🔄 RenGitHub - GitHub Username Migration Tool"
    echo "  From: $OLD_NAME"
    echo "  To:   $NEW_NAME"
    echo ""

    case "${1:-}" in
        --help|-h)
            show_help
            ;;
        clone)
            setup
            clone_repos
            ;;
        analyze)
            analyze_repos
            ;;
        apply)
            apply_changes
            show_final_report
            ;;
        clean)
            print_warning "This will delete: $WORK_DIR"
            read -p "Are you sure? [y/n]: " confirm
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                rm -rf "$WORK_DIR"
                print_success "Cleaned up work directory"
            fi
            ;;
        *)
            setup
            clone_repos
            analyze_repos
            show_report_and_confirm
            apply_changes
            show_final_report
            ;;
    esac
}

main "$@"
