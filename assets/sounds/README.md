# App Sound Effects

Drop **.mp3** files into this folder with these exact names:

| File                     | When it plays                                  |
| ------------------------ | ---------------------------------------------- |
| `message_sent.mp3`       | You send a chat message or photo               |
| `message_received.mp3`   | A new message arrives in an open chat          |
| `tap.mp3`                | Reserved — short button-tap click              |
| `success.mp3`            | Toggle "In-App Sounds" on; success confirmations |
| `error.mp3`              | Reserved — error / failure feedback            |
| `xp_gained.mp3`          | You gain XP (any positive amount)              |
| `level_up.mp3`           | You level up                                   |
| `achievement.mp3`        | Reserved — badge unlocked                      |
| `streak.mp3`             | Reserved — streak milestone                    |

## Where to get free sounds (CC0 / no attribution needed)

- **https://pixabay.com/sound-effects/** — search "message sent", "level up", "ding"
- **https://freesound.org/** — register, filter by CC0 license
- **https://mixkit.co/free-sound-effects/** — direct downloads, free for commercial use

## Recommendations

Keep each clip **short** (0.2–1.5 seconds). Long sounds annoy users. The
`AudioPlayer` is configured with `lowLatency` mode, so short crisp samples
play instantly without lag.

## Falling back

`SoundService` silently no-ops if a file is missing — the UI never breaks.
You can ship the app without sounds and add them later.
