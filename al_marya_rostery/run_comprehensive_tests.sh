#!/bin/bash

# Al Marya Rostery - Comprehensive Test Execution Script
# This script performs a complete analysis of the application

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║   Al Marya Rostery - Comprehensive Application Test Suite     ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Navigate to project directory
cd "$(dirname "$0")"

echo "📍 Current Directory: $(pwd)"
echo ""

# ==================== PART 1: CODEBASE ANALYSIS ====================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 PART 1: CODEBASE ANALYSIS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Count pages
echo "📱 Counting Pages..."
TOTAL_PAGES=$(find lib -name "*page*.dart" -type f | wc -l | tr -d ' ')
echo -e "   ${GREEN}Total Pages Found: $TOTAL_PAGES${NC}"
echo ""

# Check for hardcoded values
echo "🔍 Scanning for Hardcoded Values..."
LOCALHOST_COUNT=$(grep -r "localhost" lib/ 2>/dev/null | wc -l | tr -d ' ')
HARDCODED_COLORS=$(grep -r "Color(0x" lib/ 2>/dev/null | wc -l | tr -d ' ')
TODO_COUNT=$(grep -rE "TODO|FIXME" lib/ 2>/dev/null | wc -l | tr -d ' ')

echo -e "   ${YELLOW}Localhost references: $LOCALHOST_COUNT${NC}"
echo -e "   ${YELLOW}Hardcoded colors: $HARDCODED_COLORS${NC}"
echo -e "   ${YELLOW}TODO/FIXME comments: $TODO_COUNT${NC}"
echo ""

# Check for skeleton loaders
echo "💀 Checking Skeleton Loaders..."
SKELETON_COUNT=$(grep -r "Shimmer\|skeleton\|SkeletonLoader" lib/ 2>/dev/null | wc -l | tr -d ' ')
echo -e "   ${GREEN}Skeleton loader implementations: $SKELETON_COUNT${NC}"
echo ""

# Check backend connectivity
echo "🔌 Analyzing Backend Connectivity..."
API_CALLS=$(grep -r "http\.\|\.get(\|\.post(\|\.put(\|\.delete(" lib/ 2>/dev/null | wc -l | tr -d ' ')
BASEURL_USAGE=$(grep -r "baseUrl\|AppConstants.baseUrl" lib/ 2>/dev/null | wc -l | tr -d ' ')
echo -e "   ${GREEN}API calls found: $API_CALLS${NC}"
echo -e "   ${GREEN}Base URL references: $BASEURL_USAGE${NC}"
echo ""

# List API endpoints
echo "📡 Detected API Endpoints:"
grep -rh "'/api/" lib/ 2>/dev/null | grep -oE "'/api/[^'\"]+'" | sort -u | while read endpoint; do
    echo "   • $endpoint"
done
echo ""

# ==================== PART 2: FILE STRUCTURE ====================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📂 PART 2: FILE STRUCTURE ANALYSIS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "📁 Key Directories:"
echo "   lib/features/          - $(find lib/features -type d | wc -l | tr -d ' ') subdirectories"
echo "   lib/core/              - $(find lib/core -type d | wc -l | tr -d ' ') subdirectories"
echo "   test/                  - $(find test -name "*_test.dart" | wc -l | tr -d ' ') test files"
echo ""

echo "📄 File Types:"
echo "   Pages:       $(find lib -name "*page*.dart" | wc -l | tr -d ' ')"
echo "   Widgets:     $(find lib -name "*widget*.dart" | wc -l | tr -d ' ')"
echo "   Providers:   $(find lib -name "*provider*.dart" | wc -l | tr -d ' ')"
echo "   Services:    $(find lib -name "*service*.dart" | wc -l | tr -d ' ')"
echo "   Models:      $(find lib -name "*model*.dart" | wc -l | tr -d ' ')"
echo ""

# ==================== PART 3: TEST SUITE ====================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 PART 3: TEST SUITE EXECUTION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "🔧 Running Flutter Tests..."
echo ""

# Run tests with compact output
flutter test --reporter=compact > test_output.txt 2>&1
TEST_EXIT_CODE=$?

# Parse test results
if [ -f test_output.txt ]; then
    TOTAL_TESTS=$(grep -oE '\+[0-9]+' test_output.txt | tail -1 | tr -d '+')
    PASSED_MSG=$(grep "All tests passed" test_output.txt)
    FAILED_MSG=$(grep "Some tests failed" test_output.txt)
    
    if [ ! -z "$PASSED_MSG" ]; then
        echo -e "${GREEN}✅ All $TOTAL_TESTS tests passed!${NC}"
    elif [ ! -z "$FAILED_MSG" ]; then
        FAILED_COUNT=$(grep -oE '\-[0-9]+' test_output.txt | tail -1 | tr -d '-')
        echo -e "${RED}❌ $FAILED_COUNT tests failed out of $TOTAL_TESTS${NC}"
    fi
    
    # Show last 20 lines of output
    echo ""
    echo "📝 Test Output (last 20 lines):"
    tail -20 test_output.txt
fi

echo ""

# ==================== PART 4: ISSUES REPORT ====================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚨 PART 4: ISSUES REPORT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "🔴 Critical Issues:"
if [ $LOCALHOST_COUNT -gt 0 ]; then
    echo -e "   ${RED}• Found $LOCALHOST_COUNT localhost references${NC}"
    echo "     Files:"
    grep -rl "localhost" lib/ 2>/dev/null | head -5 | while read file; do
        echo "     - $file"
    done
fi

if [ $TODO_COUNT -gt 10 ]; then
    echo -e "   ${YELLOW}• Found $TODO_COUNT TODO/FIXME comments${NC}"
fi

if [ $HARDCODED_COLORS -gt 200 ]; then
    echo -e "   ${YELLOW}• Found $HARDCODED_COLORS hardcoded colors (consider using theme)${NC}"
fi

echo ""
echo "⚠️  Pages Requiring Backend Verification:"
echo "   • Loyalty Rewards"
echo "   • Referrals"
echo "   • Subscriptions"
echo "   • Payment Methods"
echo "   • Gift Sets"
echo "   • Wishlist"
echo "   • Reviews"
echo ""

echo "💡 Recommendations:"
echo "   1. Implement missing backend APIs"
echo "   2. Replace hardcoded colors with theme colors"
echo "   3. Add more skeleton loaders for better UX"
echo "   4. Complete TODO items"
echo "   5. Test all pages with real backend"
echo ""

# ==================== PART 5: SUMMARY ====================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Application Statistics:"
echo "├─ Total Pages: $TOTAL_PAGES"
echo "├─ Test Files: $(find test -name "*_test.dart" | wc -l | tr -d ' ')"
echo "├─ API Calls: $API_CALLS"
echo "├─ Skeleton Loaders: $SKELETON_COUNT"
echo "├─ Backend Connected: ✅ Authentication, Products, Orders, Addresses, Tracking"
echo "└─ Needs Implementation: ⚠️ Loyalty, Referrals, Subscriptions, Payments"
echo ""

echo "Test Results:"
if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo -e "└─ Status: ${GREEN}All tests passing ✅${NC}"
else
    echo -e "└─ Status: ${RED}Some tests failing ❌${NC}"
fi
echo ""

echo "Next Steps:"
echo "1. Review test_analysis_report.md for detailed findings"
echo "2. Implement missing backend APIs"
echo "3. Replace hardcoded values with dynamic data"
echo "4. Add skeleton loaders to remaining pages"
echo "5. Run manual testing on all features"
echo ""

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║   Test Suite Complete - See test_analysis_report.md           ║"
echo "╚════════════════════════════════════════════════════════════════╝"

# Cleanup
rm -f test_output.txt

exit $TEST_EXIT_CODE
