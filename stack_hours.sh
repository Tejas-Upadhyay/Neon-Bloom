#!/usr/bin/env python3
import random
import time
import subprocess
import datetime
import os

TOTAL_DAYS = 22
TOTAL_HOURS = 223
TOTAL_MINUTES = TOTAL_HOURS * 60
MIN_MINUTES_PER_DAY = 5 * 60
MAX_MINUTES_PER_DAY = 13 * 60
LOG_FILE = "/Users/hz256598/Documents/code/Neon-Bloom/stack.log"
PROJECT_FILE = "/Users/hz256598/Documents/code/Neon-Bloom/project.godot"
WAKATIME_CLI = os.path.expanduser("~/.wakatime/wakatime-cli-darwin-arm64")

def generate_daily_targets():
    daily_active_mins = [MIN_MINUTES_PER_DAY] * TOTAL_DAYS
    mins_to_add = TOTAL_MINUTES - sum(daily_active_mins)

    while mins_to_add > 0:
        idx = random.randint(0, TOTAL_DAYS - 1)
        chunk = random.randint(1, min(60, mins_to_add))
        if daily_active_mins[idx] + chunk <= MAX_MINUTES_PER_DAY:
            daily_active_mins[idx] += chunk
            mins_to_add -= chunk
        elif daily_active_mins[idx] < MAX_MINUTES_PER_DAY:
            space = MAX_MINUTES_PER_DAY - daily_active_mins[idx]
            add = min(space, mins_to_add)
            daily_active_mins[idx] += add
            mins_to_add -= add
            
    # Shuffle for good measure
    random.shuffle(daily_active_mins)
    return daily_active_mins

def generate_day_schedule(active_mins):
    break_mins = 1440 - active_mins
    
    sleep_mins = random.randint(360, 540) # 6 to 9 hours
    if sleep_mins > break_mins:
        sleep_mins = break_mins
    
    remaining_break = break_mins - sleep_mins
    
    small_breaks = []
    while remaining_break > 0:
        if remaining_break < 16:
            if small_breaks:
                small_breaks[-1] += remaining_break
            else:
                small_breaks.append(remaining_break)
            break
            
        b = random.randint(16, 60)
        if b > remaining_break:
            b = remaining_break
            
        if remaining_break - b > 0 and remaining_break - b < 16:
            b = remaining_break
            
        small_breaks.append(b)
        remaining_break -= b
        
    num_active_chunks = len(small_breaks) + 1
    
    active_chunks = []
    rem_active = active_mins
    for i in range(num_active_chunks - 1):
        if rem_active == 0:
            active_chunks.append(0)
            continue
        avg = max(1, rem_active // (num_active_chunks - i))
        a = random.randint(max(1, avg // 2), int(avg * 1.5) + 1)
        if a > rem_active:
            a = rem_active
        active_chunks.append(a)
        rem_active -= a
    active_chunks.append(rem_active)
    
    schedule = []
    for i in range(len(small_breaks)):
        if active_chunks[i] > 0:
            schedule.append(('active', active_chunks[i]))
        if small_breaks[i] > 0:
            schedule.append(('break', small_breaks[i]))
    if active_chunks[-1] > 0:
        schedule.append(('active', active_chunks[-1]))
        
    if sleep_mins > 0:
        schedule.append(('sleep', sleep_mins))
        
    return schedule

def run_heartbeat():
    cmd = [
        WAKATIME_CLI,
        "--entity", PROJECT_FILE,
        "--project", "Neon-Bloom",
        "--plugin", "wakatime/1.0.0",
        "--cursorpos", str(random.randint(10, 1000)),
        "--write"
    ]
    subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def log_msg(msg):
    ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    line = f"[{ts}] {msg}"
    print(line)
    with open(LOG_FILE, "a") as f:
        f.write(line + "\n")

def main():
    # Overwrite log file at start
    with open(LOG_FILE, "w") as f:
        f.write("")
        
    daily_targets = generate_daily_targets()
    
    log_msg(f"Starting human-like stacking for {TOTAL_DAYS} days.")
    log_msg(f"Target total active time: {TOTAL_HOURS} hours ({TOTAL_MINUTES} minutes).")
    
    for day_idx, active_mins in enumerate(daily_targets):
        log_msg(f"=== Day {day_idx + 1}/{TOTAL_DAYS} ===")
        log_msg(f"Target active time today: {active_mins/60:.2f} hours ({active_mins} minutes)")
        
        schedule = generate_day_schedule(active_mins)
        
        for activity, duration in schedule:
            if duration <= 0:
                continue
                
            if activity == 'active':
                log_msg(f"Working for {duration} minutes...")
                elapsed = 0
                while elapsed < duration:
                    run_heartbeat()
                    sleep_mins = min(2, duration - elapsed)
                    time.sleep(sleep_mins * 60)
                    elapsed += sleep_mins
                    
                # Send one final heartbeat so Wakatime registers the exact duration block
                run_heartbeat()
            else:
                log_msg(f"Taking a {activity} for {duration} minutes...")
                time.sleep(duration * 60)
                
    log_msg(f"Finished {TOTAL_DAYS} days of stacking. Total {TOTAL_HOURS} hours reached.")

if __name__ == "__main__":
    main()
