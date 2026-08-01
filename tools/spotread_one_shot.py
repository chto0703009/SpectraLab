#!/usr/bin/env python3
"""Run one bounded external command for SpectraLab.

The JSON configuration keeps executable arguments out of shell parsing.  The
helper always writes stdout, stderr and process metadata into the supplied
working directory.  Exit code 0 means that the helper completed; the external
process exit code is recorded in process.json.
"""

from __future__ import annotations

import json
import subprocess
import sys
import time
from pathlib import Path


def write_text(path: Path, value: str) -> None:
    path.write_text(value or "", encoding="utf-8")


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: spotread_one_shot.py CONFIG.json", file=sys.stderr)
        return 2

    config_path = Path(sys.argv[1]).resolve()
    config = json.loads(config_path.read_text(encoding="utf-8"))
    work_dir = Path(config["working_directory"]).resolve()
    work_dir.mkdir(parents=True, exist_ok=True)

    command = [str(config["executable"])]
    command.extend(str(arg) for arg in config.get("arguments", []))
    timeout_seconds = float(config.get("timeout_seconds", 120))
    keep_stdin_open = bool(config.get("keep_stdin_open", False))

    started = time.time()
    stdout = ""
    stderr = ""
    exit_code = -1
    timed_out = False
    launch_error = ""
    instrument_prompt_seen = False

    try:
        if keep_stdin_open:
            import pexpect

            child = pexpect.spawn(
                command[0],
                command[1:],
                cwd=str(work_dir),
                encoding="utf-8",
                codec_errors="replace",
                timeout=timeout_seconds,
            )
            chunks: list[str] = []
            try:
                index = child.expect([
                    r"(?i)hit any key to continue",
                    r"(?i)instrument switch or any other key to take a reading:",
                    pexpect.EOF,
                    pexpect.TIMEOUT,
                ])
                chunks.append(child.before or "")
                if index in (0, 1):
                    chunks.append(child.after or "")
                    instrument_prompt_seen = True
                    print(
                        "\nSPECTRALAB_READY: Spotread is ready. "
                        "Press the button on the i1Pro2 now.",
                        flush=True,
                    )
                    child.expect(pexpect.EOF)
                    chunks.append(child.before or "")
                elif index == 3:
                    timed_out = True
                    exit_code = 124

                if not timed_out:
                    child.close()
                    if child.exitstatus is not None:
                        exit_code = int(child.exitstatus)
                    elif child.signalstatus is not None:
                        exit_code = 128 + int(child.signalstatus)
                    else:
                        exit_code = 0
            except pexpect.TIMEOUT:
                chunks.append(child.before or "")
                timed_out = True
                exit_code = 124
            finally:
                if child.isalive():
                    child.close(force=True)
            stdout = "".join(chunks)
        else:
            completed = subprocess.run(
                command,
                cwd=work_dir,
                stdin=subprocess.DEVNULL,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                encoding="utf-8",
                errors="replace",
                timeout=timeout_seconds,
                check=False,
            )
            stdout = completed.stdout
            stderr = completed.stderr
            exit_code = int(completed.returncode)
    except subprocess.TimeoutExpired as exc:
        timed_out = True
        exit_code = 124
        stdout = exc.stdout or ""
        stderr = exc.stderr or ""
        if isinstance(stdout, bytes):
            stdout = stdout.decode("utf-8", errors="replace")
        if isinstance(stderr, bytes):
            stderr = stderr.decode("utf-8", errors="replace")
    except OSError as exc:
        exit_code = 127
        launch_error = str(exc)
        stderr = launch_error

    finished = time.time()
    write_text(work_dir / "stdout.txt", stdout)
    write_text(work_dir / "stderr.txt", stderr)

    metadata = {
        "command": command,
        "exit_code": exit_code,
        "timed_out": timed_out,
        "launch_error": launch_error,
        "started_unix": started,
        "finished_unix": finished,
        "duration_seconds": finished - started,
        "kept_stdin_open": keep_stdin_open,
        "instrument_prompt_seen": instrument_prompt_seen,
    }
    (work_dir / "process.json").write_text(
        json.dumps(metadata, indent=2), encoding="utf-8"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
