# ServiceDispatch

ServiceDispatch automatically logs emergency services like police and fire department dispatch channels. Given an audio stream on the web for emergency announcements, this software will record all non-silence as individual audio clips, record the timestamp and duration of each conversation, and make all of it available through a web interface. This is the codebase originally used for [Troy Dispatch](https://troydispatch.com/), open sourced to empower other cities to create their own dispatch logs.

## Installation Quick Guide

**This guide assumes you've created a new debian or ubuntu-like server to host ServiceDispatch**

Install package dependencies:

```
apt install nginx ruby sox libsox-fmt-mp3 curl redis-server lsof
```

Edit `audio/pipeline.rb` to set the URL of your emergency service broadcast.

Move the contents of this directory to wherever you'll be hosting from (`/var/www/dispatch` is a good choice), then run:

```
./install.sh
```

Now move `nginx_servicedispatch` into `/etc/nginx/sites_available/default`.

Finally, from the directory you've installed the website into, start this website with:

```
unicorn -c unicorn.rb -E deployment -D
nohup audio/pipeline.rb
```

Now, if nginx and redis are running, everything _should_ be available over http. Congratulations!

## Technical Overview

ServiceDispatch consists of about 3 components:

* A shell script that downloads the audio stream and feeds it into `sox`, which chops it into MP3s based on silence

* A ruby script that checks for new audio clips every minute, and upon finding them adds their metadata to a database and moves them into a web folder

* A ruby web backend which pulls the metadata from the database and renders it as a browseable page

## Silence Tuning

If ServiceDispatch is ignoring real audio, is triggered by static too easily, or is breaking conversations into too many audio clips, you may need to adjust the variables at the start of `audio/pipeline.rb`. SILENCE controls the decibel threshold that `sox` will recognize as speech, and PAUSE controls how many seconds of silence before `sox` marks the conversation as "over" and ends the audio clip.
