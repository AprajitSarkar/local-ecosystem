#!/usr/bin/env bash
# scripts/ipad_live_logs.sh
# Real-time streaming log monitor for connected iPad

UDID="00008112-001264D00206601E"

echo "========================================================="
echo "📱 Streaming Live Logs for Local Ecosystem on iPad ($UDID)..."
echo "👉 Open the app on your iPad now."
echo "🛑 Press Ctrl+C to stop when done."
echo "========================================================="

idevicesyslog -u "$UDID" | grep -iE --line-buffered "Runner\[|LocalEcosystem|flutter|\[Flutter|SIGABRT|EXC_CRASH|Abort trap"
