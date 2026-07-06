#!/usr/bin/env python3
"""
SpectraLab manual-safe spotread bridge.

This helper provides concise user-facing status text and returns raw spotread output to MATLAB for parsing.
"""

import argparse
import shutil
import sys
import tempfile
import signal
from pathlib import Path

try:
    import pexpect
except Exception as exc:
    print("SpectraLab error: pexpect is not available: %s" % exc)
    sys.exit(20)


def step_box(title: str, lines) -> None:
    width = 52
    rule = "-" * width
    print(f"\n+-{rule}-+", flush=True)
    print(f"| {title.upper():<{width}} |", flush=True)
    print(f"+-{rule}-+", flush=True)
    for line in lines:
        print(f"| {line:<{width}} |", flush=True)
    print(f"+-{rule}-+", flush=True)


class UserInputTimeout(Exception):
    pass


def _input_timeout_handler(signum, frame):
    raise UserInputTimeout()


def ask_user(title: str, lines, timeout_seconds: int = 180) -> None:
    step_box(title, lines)
    print("", flush=True)
    print("Press ENTER in the MATLAB Command Window when ready.", flush=True)
    print("If this prompt does not respond, stop with Ctrl-C and run startup again.", flush=True)

    old_handler = None
    try:
        old_handler = signal.signal(signal.SIGALRM, _input_timeout_handler)
        signal.alarm(max(1, int(timeout_seconds)))
    except Exception:
        old_handler = None

    try:
        input("Press ENTER when ready: ")
    except UserInputTimeout:
        print("SpectraLab error: no ENTER received by the bridge.", flush=True)
        print("This can happen if MATLAB does not pass keyboard input to the Python bridge.", flush=True)
        sys.exit(26)
    finally:
        try:
            signal.alarm(0)
            if old_handler is not None:
                signal.signal(signal.SIGALRM, old_handler)
        except Exception:
            pass


def write_raw_file(text: str) -> str:
    path = Path(tempfile.gettempdir()) / "spectralab_spotread_last_output.txt"
    path.write_text(text, encoding="utf-8")
    return str(path)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--spotread", default="")
    parser.add_argument("--options", default="-e -s")
    parser.add_argument("--timeout", type=int, default=300)
    args = parser.parse_args()

    exe = args.spotread or shutil.which("spotread")
    if not exe:
        print("SpectraLab error: spotread not found", flush=True)
        return 21

    child = pexpect.spawn(f'"{exe}" {args.options}'.strip(), encoding="utf-8", timeout=args.timeout)
    log_chunks = []
    reading_taken = False

    def capture():
        try:
            if child.before:
                log_chunks.append(child.before)
        except Exception:
            pass

    def send(text=""):
        try:
            if child.isalive():
                child.sendline(text)
        except Exception:
            pass

    try:
        while True:
            idx = child.expect([
                r"hit any key to continue",
                r"Calibration complete",
                r"Place instrument on spot to be measured",
                r"Hit ESC or Q to exit.*take a reading:",
                r"Result is XYZ:[^\r\n]*",
                r"Calibration failed",
                r"Communications failure",
                r"Instrument initialisation failed",
                pexpect.EOF,
                pexpect.TIMEOUT,
            ])
            capture()

            if idx == 0:
                ask_user("Calibration", [
                    "Place the instrument on the white reference.",
                ], timeout_seconds=args.timeout)
                send("")

            elif idx == 1:
                log_chunks.append("Calibration complete")
                print("Calibration complete.", flush=True)

            elif idx == 2:
                continue

            elif idx == 3:
                if not reading_taken:
                    ask_user("Measurement", [
                        "Place the instrument on the light source.",
                    ], timeout_seconds=args.timeout)
                    reading_taken = True
                    send("")
                else:
                    try:
                        child.close(force=True)
                    except Exception:
                        pass
                    print("SpectraLab error: repeated measurement prompt.", flush=True)
                    return 25

            elif idx == 4:
                log_chunks.append(child.after)
                raw_path = write_raw_file("".join(log_chunks))

                try:
                    child.close(force=True)
                except Exception:
                    pass

                print("Measurement complete.", flush=True)
                return 0

            elif idx in (5, 6, 7):
                try:
                    child.close(force=True)
                except Exception:
                    pass
                print("SpectraLab error: spotread calibration/communication failure.", flush=True)
                return 24

            elif idx == 8:
                break

            elif idx == 9:
                try:
                    child.close(force=True)
                except Exception:
                    pass
                print("SpectraLab error: timeout waiting for measurement.", flush=True)
                return 22

        try:
            child.close(force=True)
        except Exception:
            pass
        print("SpectraLab error: no measurement result detected.", flush=True)
        return 23

    except KeyboardInterrupt:
        try:
            child.close(force=True)
        except Exception:
            pass
        print("SpectraLab error: interrupted by user.", flush=True)
        return 130


if __name__ == "__main__":
    sys.exit(main())
