# Show restic activity


## systemctl

```bash
$ sudo systemctl list-timers|grep restic
Tue 2024-04-16 21:30:00 CDT    10min Tue 2024-04-16 21:15:43 CDT  4min 15s ago kurtis-restic-crit15.timer    kurtis-restic-crit.service
Tue 2024-04-16 23:40:00 CDT 2h 20min Tue 2024-04-16 21:17:26 CDT  2min 32s ago kurtis-restic-prune2340.timer kurtis-restic-prune.service
```

```bash
$ sudo systemctl start kurtis-restic-prune2340.timer
```

## journalctl

```bash
$ journalctl -b 0 | grep "kurtis-restic-crit.service: Consumed"
```

