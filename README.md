# Axe

**WORK IN PROGRESS**

With the advent of AULS (Apple Unified Logging System - [1](https://developer.apple.com/reference/os/logging) [2](http://devstreaming.apple.com/videos/wwdc/2016/721wh2etddp4ghxhpcg/721/721_unified_logging_and_activity_tracing.pdf) [3](https://developer.apple.com/videos/play/wwdc2016/721/)), application developers are now free to totally stop logging to syslog built into macOS. This is great for them, bad if getting logs to an external logging service like Papertrail is still on the agenda.

This is where Axe comes in. The goal is to capture logs from Apple's Unified Logging System and send them to Papertrail. It's hacky and can probably be done more efficiently, but Apple has chosen to go the way of `journald` with their own twist.

## System Requirements

* macOS 10.12 (this is hard minimum requirement, 10.11 did not feature AULS)
* Ruby 2.2.1 (pre-installed; the goal is to add as few things as possible to the system to make this work)

## Installation

**(this doesn't do anything yet)**

Run `sudo install.sh` and it'll do the following:

1. Copy `src/axe.rb` to `/etc/papertrail/axe/axe.rb`
2. Copy `src/com.johnathanlyman.axe.plist` to `/Library/LaunchDaemons/com.johnathanlyman.axe.plist` so it can be run
3. Load the Global Daemon
4. Prompt for configuration params
5. Write out the config file to `/etc/papertrail/axe/config.yml`
6. Start the Daemon

## Configuration Options

There are a few bits of information we'll need during the configuration step:

1. Papertrail log destination and port (think `logsX.papertrailapp.com:YYYYY`), replacing `X` and `YYYYY` with what you find [here](https://papertrailapp.com/systems/setup) or [here](https://papertrailapp.com/account/destinations).
2. Determine logging level. This is incredibly important. AULS is chatty. Like really chatty. Expect `DEBUG` to churn out 4-6000 messages per second.

## TODO

- [ ] Support TLS. Currently logs are transmitted in plain-text TCP.
- [ ] Allow Axe to attempt a restart of either thread before giving up and dying. `launchd` will also attempt to restart so this might not be a big deal.

## License

The MIT License is found here: [License](LICENSE)
