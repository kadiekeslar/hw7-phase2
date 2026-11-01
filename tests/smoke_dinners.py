"""Optional local multiplayer smoke checks; requires Python 3 and Godot 4.7.2.
Run: python3 tests/smoke_dinners.py --godot /path/to/Godot
Uses three temporary game processes; never writes the saved player profile.
"""
import argparse
import pathlib
import subprocess
import time

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--godot", default="godot", help="Godot executable (4.7.2)")
options = parser.parse_args()
godot = options.godot
repo = pathlib.Path(__file__).resolve().parents[1]
results = repo / ".godot" / "smoke-results"
results.mkdir(parents=True, exist_ok=True)

def run_case(case, port, votes, week=0.8, duration=7, extra=None):
    procs=[];files=[]
    common=['--headless','--path',str(repo)]
    for i,name in enumerate(['Ana','Ben','Cal']):
        args=[godot]+common+['--',f'--name={name}',f'--port={port}',f'--quit-after={duration}',f'--week-sec={week}','--discussion-sec=0.6','--voting-sec=0.8','--result-sec=0.2',f'--bot-vote={votes[i]}','--bot-chat=hello']
        args+=['--host','--dev','--autostart=3','--force-ta=Ana'] if i==0 else ['--join=127.0.0.1']
        if extra: args+=extra.get(i,[])
        f=(results/f'{case}-{name}.log').open('w');files.append(f)
        procs.append(subprocess.Popen(args,stdout=f,stderr=subprocess.STDOUT))
        if i==0: time.sleep(.4)
    try:
        for p in procs:
            p.wait(timeout=duration + 10)
    finally:
        for p in procs:
            if p.poll() is None:
                p.terminate()
                p.wait(timeout=5)
        for f in files:
            f.close()
    logs=[(results/f'{case}-{name}.log').read_text() for name in ['Ana','Ben','Cal']]
    for log in logs:
        errors=[line for line in log.splitlines() if 'SCRIPT ERROR' in line or 'Parse Error' in line or 'ERROR:' in line]
        assert not errors, (case,errors)
        assert 'dinner phase: discussion' in log,(case,'no dinner',log)
        assert 'dinner chat: hello' in log,(case,'chat missing',log)
    return logs
logs=run_case('vote-ta',17871,['Ana','Ana','Ana'])
assert all('winner: Students' in s for s in logs)
print('PASS: scheduled dinner, chat, all clients vote, TA voted out, student winner on all peers',flush=True)
logs=run_case('vote-student',17872,['Ben','Ben','Ben'])
assert all('winner: TA' in s for s in logs)
assert all('sees Ben fail' in s for s in logs)
print('PASS: student voted out, elimination synchronized, fewer-than-two-students TA win on all peers',flush=True)
logs=run_case('skip-resume',17873,['skip','skip','skip'],week=.25,duration=11)
assert all(s.count('dinner phase: discussion')==4 for s in logs)
assert all(s.count('dinner phase: result')==4 for s in logs)
assert all('winner: TA; The semester ended' in s for s in logs)
print('PASS: all four scheduled dinners, Skip resumes game, timeout TA win on all peers',flush=True)
logs=run_case('emergency',17874,['Ana','Ana','Ana'],week=60,duration=6,extra={1:['--bot-call-dinner=0.5']})
assert all('winner: Students' in s for s in logs)
print('PASS: living student emergency dinner before week 3 and vote-to-win',flush=True)
