"""Local work-race smoke checks. Run with --godot /path/to/Godot (4.7.2)."""
import argparse
import subprocess
import time
import pathlib

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--godot", default="godot")
options = parser.parse_args()
godot = options.godot
repo = pathlib.Path(__file__).resolve().parents[1]
results = repo / ".godot" / "work-smoke-results"
results.mkdir(parents=True, exist_ok=True)

def run(case, port, actors, duration=20):
 processes=[];files=[]
 for i,(name,flags) in enumerate(actors):
  args=[godot,'--headless','--path',str(repo),'--',f'--name={name}',f'--port={port}',f'--quit-after={duration}']
  args+=['--host','--dev',f'--autostart={len(actors)}','--force-ta=Ana'] if i==0 else ['--join=127.0.0.1']
  args+=flags
  f=(results/f'{case}-{name}.log').open('w');files.append(f)
  processes.append(subprocess.Popen(args,stdout=f,stderr=subprocess.STDOUT))
  if i==0:time.sleep(.4)
 try:
  for p in processes:p.wait(timeout=duration+10)
 finally:
  for p in processes:
   if p.poll() is None:p.terminate();p.wait(timeout=5)
  for f in files:f.close()
 logs=[(results/f'{case}-{name}.log').read_text() for name,_ in actors]
 for log in logs:
  errors=[line for line in log.splitlines() if 'ERROR:' in line or 'SCRIPT ERROR' in line or 'Parse Error' in line]
  assert not errors,(case,errors)
 return logs
workers=['--bot-work','--bot-collab','--bot-respond=accept','--bot-play','--bot-program']
logs=run('coursework-win',17881,[('Ana',[]),('Ben',workers),('Cal',workers)],24)
assert all('winner: Students; All assigned coursework is complete.' in log for log in logs)
assert 'private grading:' not in logs[1] and 'private grading:' not in logs[2]
print('PASS: original collaborative puzzle + new solo programming, all assignments tracked, student work victory, grading remains private',flush=True)
logs=run('grading-win',17882,[('Ana',['--bot-goto=88,184','--bot-grade','--grading-sec=0.3','--grading-batches=2']),('Ben',[]),('Cal',[])],13)
assert all('winner: TA; The TA finished grading first.' in log for log in logs)
assert 'private grading: 2/2' in logs[0]
assert 'private grading:' not in logs[1] and 'private grading:' not in logs[2]
print('PASS: timed grading batches, private TA counter, grading victory on all clients',flush=True)
logs=run('ta-cover',17883,[('Ana',['--bot-goto=478,236','--bot-program','--bot-call-dinner=12']),('Ben',[]),('Cal',[])],16)
assert 'Programming Assignment complete!' in logs[0]
assert all('coursework at dinner: 0%' in log for log in logs)
print('PASS: TA can finish cover programming; it contributes zero student coursework',flush=True)
