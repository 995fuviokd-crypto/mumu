#!/system/bin/sh
echo "=== displays ==="
dumpsys SurfaceFlinger --display-id
echo "=== display state ==="
dumpsys display | grep -E "mDisplayId=|uniqueId=|state=" | head -30
echo "=== resumed ==="
dumpsys activity activities | grep -E "ResumedActivity" | head -8
echo "=== focus ==="
dumpsys window | grep -E "mCurrentFocus|mFocusedApp" | head -8
echo "=== via proc ==="
ps -A | grep -i via