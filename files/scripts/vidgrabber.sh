#!/bin/bash

# Check if a URL was provided
if [ -z "$1" ]; then
    echo "Error: No URL provided"
    echo "Usage: $0 <youtube-url>"
    exit 1
fi

# Set up the Knowledge directory path
KNOWLEDGE_DIR="$HOME/Knowledge"

# Create Knowledge directory if it doesn't exist
mkdir -p "$KNOWLEDGE_DIR"

# Change to Knowledge directory
cd "$KNOWLEDGE_DIR"

# Get the video title first to create the directory
VIDEO_TITLE=$(yt-dlp --get-title "$1" | sed 's/[^a-zA-Z0-9]/_/g')
VIDEO_DIR="$KNOWLEDGE_DIR/$VIDEO_TITLE"

# Create directory for this video
mkdir -p "$VIDEO_DIR"

# Change to video directory
cd "$VIDEO_DIR"

# Download and process the video
echo "Processing video in $VIDEO_DIR"
yt-dlp --write-auto-sub --sub-lang en --skip-download --write-info-json --write-description --convert-subs srt -o "%(title)s.%(ext)s" "$1" &&
    yt-dlp -f bestvideo+bestaudio --merge-output-format mp4 -o "%(title)s.%(ext)s" "$1" &&
    SUBTITLE_FILE=$(find . -type f -name '*.srt' | head -n 1) &&
    "$HOME/Development/fabric/fabric" -p summarize -v="#input:$SUBTITLE_FILE" -o "$VIDEO_DIR/summary.txt"

# Ensure all files are in the video directory
find . -type f -name "*.srt" -exec mv {} "$VIDEO_DIR/" \;
find . -type f -name "*.info.json" -exec mv {} "$VIDEO_DIR/" \;
find . -type f -name "*.description" -exec mv {} "$VIDEO_DIR/" \;

echo "Video processing complete. Files stored in: $VIDEO_DIR"
