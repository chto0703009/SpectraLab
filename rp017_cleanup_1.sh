#!/usr/bin/env bash
set -euo pipefail

EXPECTED_BRANCH="v0.8.0-dev"
COMMIT_MESSAGE="Remove obsolete pre-DocumentModel report pipeline"
MATLAB_BIN="${MATLAB_BIN:-/Applications/MATLAB_R2025b.app/bin/matlab}"

if [[ ! -x "$MATLAB_BIN" ]]; then
    echo "ERROR: MATLAB executable not found: $MATLAB_BIN"
    exit 1
fi

echo
echo "=== RP-017 Cleanup 1 ==="
echo "Remove obsolete pre-DocumentModel report architecture"
echo

CURRENT_BRANCH="$(git branch --show-current)"

if [[ "$CURRENT_BRANCH" != "$EXPECTED_BRANCH" ]]; then
    echo "ERROR: Expected branch '$EXPECTED_BRANCH', but current branch is '$CURRENT_BRANCH'."
    exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
    echo "ERROR: Working tree is not clean."
    echo
    git status --short
    exit 1
fi

FILES_TO_REMOVE=(
    "spectralab/+spectralab/+report/+internal/renderManifest.m"
    "spectralab/+spectralab/+report/+internal/createRendererRegistry.m"
    "tests/test_report_renderManifest.m"
    "tests/create.m"
)

DIRECTORY_TO_REMOVE="spectralab/+spectralab/+report/+internal/+renderers"

echo "Files scheduled for removal:"
printf '  %s\n' "${FILES_TO_REMOVE[@]}"
echo "  $DIRECTORY_TO_REMOVE/"
echo

for file in "${FILES_TO_REMOVE[@]}"; do
    if [[ ! -f "$file" ]]; then
        echo "ERROR: Expected file does not exist: $file"
        exit 1
    fi
done

if [[ ! -d "$DIRECTORY_TO_REMOVE" ]]; then
    echo "ERROR: Expected directory does not exist: $DIRECTORY_TO_REMOVE"
    exit 1
fi

echo "Removing obsolete files..."
git rm "${FILES_TO_REMOVE[@]}"
git rm -r "$DIRECTORY_TO_REMOVE"

echo
echo "Checking for remaining legacy references..."

if grep -RIn \
    --include='*.m' \
    -E 'renderManifest|createRendererRegistry|internal\.renderers\.|spectralab\.report\.(create|Report|validate)' \
    spectralab examples tests 2>/dev/null
then
    echo
    echo "ERROR: Legacy report references remain."
    echo "No commit has been created."
    exit 1
fi

echo "No legacy references found."

echo
echo "=== Git diff summary ==="
git diff --stat
git diff --check

echo
echo "=== Focused report tests ==="

"$MATLAB_BIN" -batch "results = runtests([\"tests/test_report_buildManifest.m\"; \"tests/test_report_documentModel.m\"; \"tests/test_report_documentContent.m\"; \"tests/test_report_renderContract.m\"; \"tests/test_report_layoutEngine.m\"; \"tests/test_report_pdfBackend.m\"; \"tests/test_report_pngExport.m\"; \"tests/test_report_referenceReport.m\"]); disp(table(results)); assert(all([results.Passed]), \"Focused report tests failed.\");"

echo
echo "=== Full regression suite ==="

"$MATLAB_BIN" -batch "results = runtests(\"tests\"); disp(table(results)); assert(all([results.Passed]), \"Regression test suite failed.\");"

echo
echo "=== Cleanup check ==="

TEMP_FILES="$(
    find . \
        -type f \
        \( -name '*~' \
        -o -name '*.bak' \
        -o -name '*.orig' \
        -o -name '*.rej' \
        -o -name '.DS_Store' \
        \) \
        -not -path './.git/*' \
        -print
)"

if [[ -n "$TEMP_FILES" ]]; then
    echo "ERROR: Temporary or backup files found:"
    echo "$TEMP_FILES"
    echo
    echo "Remove or review them before committing."
    exit 1
fi

echo "No temporary or backup files found."

echo
echo "=== Final staged change ==="
git status --short
git diff --cached --stat
git diff --cached --check

echo
echo "Creating commit..."
git commit -m "$COMMIT_MESSAGE"

echo
echo "Pushing $EXPECTED_BRANCH..."
git push origin "$EXPECTED_BRANCH"

echo
echo "=== Completed ==="
git status --short --branch