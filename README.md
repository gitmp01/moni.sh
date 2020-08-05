# moni.sh

Pipe your logs to moni.sh and get an SMS when something is wrong!

## Usage

```bash
tail -n 0 -f a.log | ./moni.sh "Error*"
```

```bash
adb logcat | ./moni.sh "Exception*"
```
