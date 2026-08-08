#!/usr/bin/env python3
"""Acquire a ColorChecker sequence in one persistent spotread process.

The process calibrates once, then saves the raw output of every requested
patch before asking for the next one.  This deliberately does not use -O or
start a new spotread process between patches.
"""
import argparse, json, subprocess, sys, time
from pathlib import Path
import pexpect

class OperatorCancelled(Exception):
    pass


def macos_dialog(text, title):
    script = r'''
on run argv
    set messageText to item 1 of argv
    set titleText to item 2 of argv
    set answer to display dialog messageText with title titleText buttons {"Cancel", "Continue"} default button "Continue" cancel button "Cancel" with icon caution
    return button returned of answer
end run
'''
    result = subprocess.run(
        ["osascript", "-e", script, "--", text, title],
        text=True, capture_output=True, check=False)
    if result.returncode != 0:
        raise OperatorCancelled("Operator cancelled the series.")


def ask(text, dialog_mode):
    if dialog_mode == "dialog" and sys.platform == "darwin":
        macos_dialog(text, "SpectraLab — ColorChecker")
        return
    print("\n" + "=" * 60, flush=True)
    print(text, flush=True)
    print("Press ENTER in MATLAB Command Window when ready.", flush=True)
    try:
        input()
    except EOFError as exc:
        raise OperatorCancelled("Operator input was closed.") from exc

def main():
    p=argparse.ArgumentParser()
    p.add_argument("config")
    a=p.parse_args(); c=json.loads(Path(a.config).read_text())
    out=Path(c["output_folder"]); out.mkdir(parents=True, exist_ok=True)
    labels=c["labels"]
    dialog_mode=c.get("operator_ui", "dialog")
    cmd=[c["spotread"]]+c["arguments"]
    child=pexpect.spawn(cmd[0],cmd[1:],encoding="utf-8",timeout=c.get("timeout",300))
    manifest_path=out/"series_manifest.json"
    index=0; active=None; records=[]
    started=time.time()
    def save_manifest(state, message=""):
        out.mkdir(parents=True, exist_ok=True)
        payload={
            "schema":"spectralab.spotread-colorchecker-series.v1",
            "state":state,
            "message":message,
            "started_unix":started,
            "updated_unix":time.time(),
            "requested_patch_count":len(labels),
            "completed_patch_count":len(records),
            "instrument_id":c.get("instrument_id", ""),
            "high_resolution":bool(c.get("high_resolution", False)),
            "chart_name":c.get("chart_name", ""),
            "chart_manufactured_date":c.get("chart_manufactured_date", ""),
            "records":records,
        }
        temporary=manifest_path.with_suffix(".json.tmp")
        temporary.write_text(json.dumps(payload,indent=2),encoding="utf-8")
        temporary.replace(manifest_path)
    save_manifest("running")
    try:
        while True:
            event=child.expect([r"(?i)hit any key to continue",r"(?i)Calibration complete",r"(?i)Hit ESC or Q to exit.*take a reading:",r"(?i)Calibration failed",r"(?i)Communications failure",pexpect.EOF,pexpect.TIMEOUT])
            if event==0:
                ask("Place the i1Pro on its WHITE calibration reference.\n\nDo not place it on the ColorChecker yet.", dialog_mode); child.sendline()
            elif event==1: print("Calibration complete.",flush=True)
            elif event==2:
                if active is not None:
                    raw=child.before
                    path=out/(active+".txt"); path.write_text(raw,encoding="utf-8")
                    records.append({"index":index+1,"coordinate":active,
                                    "raw_file":path.name})
                    save_manifest("running")
                    index+=1
                if index>=len(labels):
                    # ArgyllCMS documents and implements upper-case Q as
                    # the clean exit key. Lower-case q may be treated as a
                    # measurement trigger and leaves MATLAB waiting.
                    child.sendline("Q")
                    try:
                        child.expect(pexpect.EOF, timeout=5)
                    except pexpect.TIMEOUT:
                        # Every requested result is already persisted. Do
                        # not hold MATLAB hostage to a Spotread process
                        # that ignores its documented exit command.
                        child.close(force=True)
                    break
                active=labels[index]
                ask("Measure ColorChecker patch " + active + ".\n\nPlace the i1Pro on this patch, then click Continue.", dialog_mode)
                child.sendline()
            elif event in (3,4): raise RuntimeError(str(child.after))
            elif event==5: break
            else: raise RuntimeError("Timed out waiting for spotread.")
    except (OperatorCancelled, EOFError, KeyboardInterrupt):
        if len(records) == len(labels):
            save_manifest("complete", "All requested patches were measured before interruption.")
            return 0
        save_manifest("cancelled","Operator cancelled the series.")
        return 130
    except Exception as exc:
        save_manifest("failed",str(exc))
        raise
    finally:
        if child.isalive(): child.close(force=True)
    save_manifest("complete")
    return 0
if __name__=='__main__': raise SystemExit(main())
