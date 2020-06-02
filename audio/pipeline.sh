#!/usr/bin/env bash
URL="https://p1.broadcastify.com/t7052dc1spmrn94.mp3"
PIPE="pipe.mp3"
SILENCE="-42db" # Determine this through trial and error
PAUSE="5.0" # How long a pause before we mark a conversation as ended
POLL=60 # How frequently to check for new clips, in seconds

# You probably don't need to change anything after this line

# Path to this script
SCRIPT=$(readlink -f "$0")
# Folder this script is in
SCRIPTPATH=$(dirname "$SCRIPT")
# Make sure all the audio files end up in the intended folder
cd $SCRIPTPATH

rm $PIPE 2>/dev/null
mkfifo $PIPE
echo "Pipe initialized."

curl -L --silent $URL > $PIPE &
echo "Downloading audio stream..."
sox -V3 -t mp3 $PIPE dispatch_part_.mp3 silence 1 0.5 $SILENCE 1 $PAUSE $SILENCE : newfile : restart &
echo "Splitting audio stream based on silence."

echo "Will now check for audio clips every $POLL seconds."
while[ 1 -eq 1 ]; do
	sleep 60
	$SCRIPTPATH/refresh.rb
done
