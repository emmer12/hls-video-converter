#!/bin/bash

# Input MP4 file
input_file="video2.mp4"

# Output directory for HLS playlists and segments
output_dir="output_hls"

# Create the output directory if it doesn't exist
mkdir -p "$output_dir"

# Resolutions and corresponding bitrates
resolutions=("256x144" "426x240" "640x360" "854x480" "1280x720")
bitrates=("200k" "400k" "800k" "1200k" "2500k")

# Function to convert video for a given resolution and bitrate
convert_video() {
    resolution=$1
    bitrate=$2
    ffmpeg -i "$input_file" -vf "scale=$resolution" -c:v h264 -b:v $bitrate -hls_time 10 -hls_list_size 0 -hls_segment_filename "$output_dir/${resolution}_%03d.ts" "$output_dir/${resolution}.m3u8"
}

# Loop through each resolution and initiate FFmpeg conversion in the background
for i in "${!resolutions[@]}"; do
    resolution="${resolutions[$i]}"
    bitrate="${bitrates[$i]}"
    
    convert_video "$resolution" "$bitrate" &
done

# Wait for all background jobs to finish
wait

# Generate the master playlist (M3U8) with references to the individual playlists
echo -e "#EXTM3U\n" > "$output_dir/master_playlist.m3u8"
for i in "${!resolutions[@]}"; do
    resolution="${resolutions[$i]}"
    echo -e "#EXT-X-STREAM-INF:BANDWIDTH=${bitrates[$i]},RESOLUTION=${resolution}\n${resolution}.m3u8" >> "$output_dir/master_playlist.m3u8"
done
