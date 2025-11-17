# Mermaid Diagram Validation

This document explains how to validate Mermaid diagrams before deploying to GitHub Pages.

## Why Validate?

Mermaid diagrams with syntax errors will show "Syntax error in text" messages instead of rendering properly. Validation catches these errors before deployment.

## Validation Tools

### 1. Automated Script (Recommended)

Use the validation script to check all diagrams:

```bash
# Validate all reports
./scripts/validate-mermaid.sh reports/

# Validate specific file
./scripts/validate-mermaid.sh reports/sprint-03-final-report.md

# Validate everything
./scripts/validate-mermaid.sh .
```

The script will:
- ✅ Check syntax using Mermaid CLI if installed
- ✅ Report line numbers for errors
- ✅ Provide clear pass/fail status
- ✅ Exit with error code if validation fails

### 2. Mermaid CLI Installation

For full validation, install Mermaid CLI:

```bash
# Install globally
npm install -g @mermaid-js/mermaid-cli

# Verify installation
mmdc --version
```

Without Mermaid CLI, the script will perform basic pattern matching.

### 3. Online Validation

Use the [Mermaid Live Editor](https://mermaid.live) to test diagrams:

1. Copy your diagram code
2. Paste into the live editor
3. Fix any syntax errors shown
4. Copy corrected code back to markdown

## Common Syntax Issues

### HTML in Labels

**Problem:** HTML tags like `<br/>` can cause issues in some Mermaid versions.

**Solution:** Use alternative syntax:

```mermaid
# Instead of:
SDL[Self-Driving Labs<br/>$3.11B by 2033]

# Use line breaks:
SDL["Self-Driving Labs
$3.11B by 2033"]

# Or use backticks for special characters:
SDL["`Self-Driving Labs
$3.11B by 2033`"]
```

### Special Characters

**Problem:** Characters like `[]`, `{}`, `()` in labels need escaping.

**Solution:**

```mermaid
# Quote labels with special characters:
A["Label with [brackets]"]
B["Label with {braces}"]
C["Label with (parens)"]
```

### Arrow Syntax

**Problem:** Incorrect arrow syntax.

**Solution:**

```mermaid
# Valid arrows:
A --> B     # Solid arrow
A -.-> B    # Dotted arrow
A ==> B     # Thick arrow
A --- B     # Line (no arrow)

# Invalid:
A -> B      # Too few dashes
```

## Pre-Commit Hook

Add validation to your git workflow:

Create `.git/hooks/pre-commit`:

```bash
#!/bin/bash
./scripts/validate-mermaid.sh reports/
if [ $? -ne 0 ]; then
    echo "❌ Mermaid diagram validation failed!"
    echo "Fix errors before committing."
    exit 1
fi
```

Make it executable:
```bash
chmod +x .git/hooks/pre-commit
```

## CI/CD Integration

Add to GitHub Actions workflow:

```yaml
- name: Validate Mermaid Diagrams
  run: |
    npm install -g @mermaid-js/mermaid-cli
    ./scripts/validate-mermaid.sh reports/
```

## Version Compatibility

Current setup:
- **Mermaid.js in HTML**: v10.9.5 (from CDN)
- **Mermaid CLI (mmdc)**: v11.9.0 (for validation)

Most diagrams are forward/backward compatible, but test after version changes.

## Troubleshooting

### Diagram Shows "Syntax error in text"

1. **Validate locally:**
   ```bash
   ./scripts/validate-mermaid.sh path/to/file.md
   ```

2. **Check browser console:**
   - Open DevTools (F12)
   - Look for Mermaid error messages
   - Note the specific syntax issue

3. **Test in live editor:**
   - Go to https://mermaid.live
   - Paste diagram code
   - Fix errors shown

4. **Update HTML export:**
   ```bash
   /export-findings <sprint-num> html
   ```

5. **Redeploy:**
   ```bash
   cp reports/sprint-*-final-report.html docs/reports/
   git add docs/reports/*.html
   git commit -m "Fix Mermaid diagram syntax"
   git push
   ```

### Different Rendering in Browser vs CLI

Some features work in CLI but not browser (or vice versa):

- **CLI supports**: All diagram types
- **Browser supports**: Most types, may lag behind CLI
- **Solution**: Test in both environments

### Performance Issues

Large diagrams (100+ nodes) may render slowly:

1. **Simplify diagram**: Break into multiple smaller diagrams
2. **Use subgraphs**: Organize complex diagrams
3. **Consider static images**: For very complex diagrams, render to SVG/PNG offline

## Best Practices

1. **Validate before commit**: Run validation script
2. **Test in browser**: Check actual HTML rendering
3. **Keep diagrams simple**: < 50 nodes per diagram
4. **Use consistent syntax**: Pick one style and stick to it
5. **Add alt text**: For accessibility
6. **Version control**: Keep diagram source in markdown

## Example Validation Output

```
╔════════════════════════════════════════════════════╗
║     Mermaid Diagram Validator                      ║
╚════════════════════════════════════════════════════╝

✓ Mermaid CLI found: 11.9.0
Found 3 markdown files to check

→ Checking: reports/sprint-01-final-report.md
  ✓ Diagram 1 (line 245): Valid
  ✓ Diagram 2 (line 389): Valid

→ Checking: reports/sprint-02-final-report.md
  ✓ Diagram 1 (line 156): Valid

→ Checking: reports/sprint-03-final-report.md
  ✓ Diagram 1 (line 430): Valid

╔════════════════════════════════════════════════════╗
║     Validation Summary                             ║
╚════════════════════════════════════════════════════╝

Total diagrams: 4
Valid: 4
Invalid: 0

✓ All diagrams validated successfully!
```

## Resources

- [Mermaid Documentation](https://mermaid.js.org/)
- [Mermaid Live Editor](https://mermaid.live)
- [Mermaid CLI](https://github.com/mermaid-js/mermaid-cli)
- [Diagram Syntax Reference](https://mermaid.js.org/intro/syntax-reference.html)
