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

# Download subtitles, info, and description first
yt-dlp --write-auto-sub --sub-lang en --skip-download --write-info-json --write-description --convert-subs srt -o "%(title)s.%(ext)s" "$1"

# Download the actual video
yt-dlp -f bestvideo+bestaudio --merge-output-format mp4 -o "%(title)s.%(ext)s" "$1"

# Find the subtitle file
SUBTITLE_FILE=$(find . -type f -name '*.srt' | head -n 1)

if [ -n "$SUBTITLE_FILE" ]; then
    # Create markdown transcription
    echo "Creating markdown transcription..."
    {
        echo "# ${VIDEO_TITLE//_/ }"
        echo
        echo "## Transcription"
        echo
        # Convert SRT to plain text, removing timestamps and line numbers
        sed -E 's/^[0-9]+$//' "$SUBTITLE_FILE" | # Remove line numbers
        sed -E 's/^[0-9]{2}:[0-9]{2}:[0-9]{2},[0-9]{3} --> [0-9]{2}:[0-9]{2}:[0-9]{2},[0-9]{3}$//' | # Remove timestamps
        sed -E '/^$/d' | # Remove empty lines
        sed -E 's/^/> /' # Add markdown quote formatting
    } > "$VIDEO_DIR/transcription.md"

    # Generate summary using fabric
    echo "Generating summary..."
    "$HOME/Development/fabric/fabric" -p summarize -v="#input:$SUBTITLE_FILE" -o "$VIDEO_DIR/summary.txt"
else
    echo "Warning: No subtitle file found. Transcription and summary could not be generated."
fi

# Ensure all files are in the video directory and organize them
find . -type f -name "*.srt" -exec mv {} "$VIDEO_DIR/" \;
find . -type f -name "*.info.json" -exec mv {} "$VIDEO_DIR/" \;
find . -type f -name "*.description" -exec mv {} "$VIDEO_DIR/" \;

# Create a README.md with metadata
{
    echo "# ${VIDEO_TITLE//_/ }"
    echo
    echo "## Overview"
    echo
    echo "- Source URL: $1"
    echo "- Download Date: $(date '+%Y-%m-%d')"
    echo
    echo "## Contents"
    echo
    echo "- [Transcription](transcription.md)"
    echo "- [Summary](summary.txt)"
    echo "- Video file (MP4)"
    echo "- Metadata (JSON)"
    echo "- Description"
} > "$VIDEO_DIR/README.md"

echo "Video processing complete. Files stored in: $VIDEO_DIR"
echo "Generated files:"
echo "- Full video (MP4)"
echo "- Transcription (Markdown)"
echo "- Summary (Text)"
echo "- Metadata (JSON)"
echo "- README"
