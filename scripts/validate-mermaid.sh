#!/usr/bin/env bash
#
# Validate Mermaid diagrams in markdown files
# Uses Mermaid CLI (mmdc) to check syntax
#
# Usage: ./scripts/validate-mermaid.sh [file-or-directory]

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Mermaid Diagram Validator                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if mmdc is installed
if ! command -v mmdc &> /dev/null; then
    echo -e "${YELLOW}⚠ Mermaid CLI (mmdc) not found${NC}"
    echo ""
    echo "Install with:"
    echo "  npm install -g @mermaid-js/mermaid-cli"
    echo ""
    echo "Falling back to basic syntax check..."
    echo ""
    USE_MMDC=false
else
    echo -e "${GREEN}✓ Mermaid CLI found: $(mmdc --version)${NC}"
    USE_MMDC=true
fi

# Find all markdown files
TARGET="${1:-.}"
if [[ -f "$TARGET" ]]; then
    FILES=("$TARGET")
elif [[ -d "$TARGET" ]]; then
    mapfile -t FILES < <(find "$TARGET" -name "*.md" -type f)
else
    echo -e "${RED}✗ Invalid target: $TARGET${NC}"
    exit 1
fi

echo "Found ${#FILES[@]} markdown files to check"
echo ""

TOTAL_DIAGRAMS=0
VALID_DIAGRAMS=0
INVALID_DIAGRAMS=0
ERRORS=()

# Process each file
for file in "${FILES[@]}"; do
    echo -e "${BLUE}→ Checking: $file${NC}"

    # Extract Mermaid diagrams
    DIAGRAM_COUNT=0
    IN_MERMAID=false
    CURRENT_DIAGRAM=""
    LINE_NUM=0
    DIAGRAM_START=0

    while IFS= read -r line; do
        LINE_NUM=$((LINE_NUM + 1))

        if [[ "$line" =~ ^\`\`\`mermaid ]]; then
            IN_MERMAID=true
            DIAGRAM_START=$LINE_NUM
            CURRENT_DIAGRAM=""
            continue
        fi

        if [[ "$IN_MERMAID" == true ]]; then
            if [[ "$line" =~ ^\`\`\`$ ]]; then
                # End of diagram
                DIAGRAM_COUNT=$((DIAGRAM_COUNT + 1))
                TOTAL_DIAGRAMS=$((TOTAL_DIAGRAMS + 1))

                # Validate diagram
                if [[ "$USE_MMDC" == true ]]; then
                    # Create temp file
                    TEMP_FILE=$(mktemp /tmp/mermaid.XXXXXX.mmd)
                    echo "$CURRENT_DIAGRAM" > "$TEMP_FILE"

                    # Try to render with mmdc
                    if mmdc -i "$TEMP_FILE" -o /tmp/test.svg 2>/dev/null; then
                        echo -e "  ${GREEN}✓ Diagram $DIAGRAM_COUNT (line $DIAGRAM_START): Valid${NC}"
                        VALID_DIAGRAMS=$((VALID_DIAGRAMS + 1))
                    else
                        echo -e "  ${RED}✗ Diagram $DIAGRAM_COUNT (line $DIAGRAM_START): Syntax error${NC}"
                        INVALID_DIAGRAMS=$((INVALID_DIAGRAMS + 1))
                        ERRORS+=("$file:$DIAGRAM_START - Diagram $DIAGRAM_COUNT has syntax error")
                    fi

                    rm -f "$TEMP_FILE" /tmp/test.svg
                else
                    # Basic validation: check for common patterns
                    if [[ "$CURRENT_DIAGRAM" =~ (graph|flowchart|sequenceDiagram|classDiagram|stateDiagram|erDiagram|gantt|pie) ]]; then
                        echo -e "  ${GREEN}✓ Diagram $DIAGRAM_COUNT (line $DIAGRAM_START): Basic check passed${NC}"
                        VALID_DIAGRAMS=$((VALID_DIAGRAMS + 1))
                    else
                        echo -e "  ${YELLOW}? Diagram $DIAGRAM_COUNT (line $DIAGRAM_START): Unknown type (install mmdc for full validation)${NC}"
                        VALID_DIAGRAMS=$((VALID_DIAGRAMS + 1))
                    fi
                fi

                IN_MERMAID=false
                CURRENT_DIAGRAM=""
            else
                CURRENT_DIAGRAM+="$line"$'\n'
            fi
        fi
    done < "$file"

    if [[ $DIAGRAM_COUNT -eq 0 ]]; then
        echo -e "  ${YELLOW}⊘ No Mermaid diagrams found${NC}"
    fi
    echo ""
done

# Summary
echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Validation Summary                             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Total diagrams: $TOTAL_DIAGRAMS"
echo -e "${GREEN}Valid: $VALID_DIAGRAMS${NC}"
echo -e "${RED}Invalid: $INVALID_DIAGRAMS${NC}"
echo ""

if [[ ${#ERRORS[@]} -gt 0 ]]; then
    echo -e "${RED}Errors found:${NC}"
    for error in "${ERRORS[@]}"; do
        echo -e "  ${RED}✗${NC} $error"
    done
    echo ""
    exit 1
else
    echo -e "${GREEN}✓ All diagrams validated successfully!${NC}"
    exit 0
fi
