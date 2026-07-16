#!/usr/bin/env python3
"""
SpectraLab manual-safe spotread bridge.

Calibration and measurement are performed in one spotread process.
Important events are appended to back.log, including failures that occur
after a successful calibration.
"""

import argparse
import datetime as dt
import shutil
import signal
import sys
import tempfile
from pathlib import Path

try:
    import pexpect
except Exception as exc:
    print(f"SpectraLab error: pexpect is not available: {exc}", flush=True)
    sys.exit(20)


class UserInputTimeout(Exception):
    pass


def _input_timeout_handler(signum, frame):
    raise UserInputTimeout()


def step_box(title: str, lines) -> None:
    width = 52
    rule = "-" * width
    print(f"\n+-{rule}-+", flush=True)
    print(f"| {title.upper():<{width}} |", flush=True)
    print(f"+-{rule}-+", flush=True)
    for line in lines:
        print(f"| {line:<{width}} |", flush=True)
    print(f"+-{rule}-+", flush=True)


def ask_user(title: str, lines, timeout_seconds: int = 180) -> None:
    step_box(title, lines)
    print("Preparation complete.", flush=True)
    print(
        "When the instrument is correctly positioned, press ENTER "
        "in the MATLAB Command Window.",
        flush=True,
    )

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
        print(
            "This can happen if MATLAB does not pass keyboard input "
            "to the Python bridge.",
            flush=True,
        )
        raise
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


def timestamp() -> str:
    return dt.datetime.now().astimezone().isoformat(timespec="seconds")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--spotread", default="")
    parser.add_argument("--options", default="-e -s")
    parser.add_argument("--timeout", type=int, default=300)
    parser.add_argument("--log", default="back.log")
    args = parser.parse_args()

    log_path = Path(args.log).expanduser()
    if not log_path.is_absolute():
        log_path = Path.cwd() / log_path

    def log_event(message: str) -> None:
        try:
            log_path.parent.mkdir(parents=True, exist_ok=True)
            with log_path.open("a", encoding="utf-8") as stream:
                stream.write(f"{timestamp()}  {message}\n")
        except Exception:
            # Logging must never prevent a measurement.
            pass

    exe = args.spotread or shutil.which("spotread")
    if not exe:
        log_event("ERROR status=21 spotread not found")
        print("SpectraLab error: spotread not found", flush=True)
        return 21

    log_chunks = []
    reading_taken = False
    calibration_complete = False
    child = None

    def capture() -> None:
        if child is None:
            return
        try:
            if child.before:
                log_chunks.append(child.before)
        except Exception:
            pass

    def save_raw_output() -> str:
        capture()
        return write_raw_file("".join(log_chunks))

    def close_child() -> None:
        if child is None:
            return
        try:
            child.close(force=True)
        except Exception:
            pass

    def send(text: str = "") -> bool:
        if child is None:
            return False
        try:
            if not child.isalive():
                log_event("ERROR attempted to send ENTER after spotread exited")
                return False
            child.sendline(text)
            return True
        except Exception as exc:
            log_event(f"ERROR failed to send ENTER: {exc}")
            return False

    command = f'"{exe}" {args.options}'.strip()
    log_event("------------------------------------------------------------")
    log_event(f"spotread bridge started: {command}")

    try:
        child = pexpect.spawn(
            command,
            encoding="utf-8",
            timeout=args.timeout,
        )
        log_event(f"spotread process started pid={child.pid}")

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
                log_event("calibration requested")
                ask_user(
                    "Calibration",
                    ["Place the instrument on the white reference."],
                    timeout_seconds=args.timeout,
                )
                log_event("user confirmed calibration position")
                if not send(""):
                    save_raw_output()
                    close_child()
                    log_event("ERROR status=23 ENTER not sent for calibration")
                    print("SpectraLab error: could not start calibration.", flush=True)
                    return 23

            elif idx == 1:
                log_chunks.append(str(child.after))
                calibration_complete = True
                log_event("calibration complete")

            elif idx == 2:
                log_event("measurement position requested")

            elif idx == 3:
                if not reading_taken:
                    ask_user(
                        "Measurement",
                        ["Place the instrument on the light source."],
                        timeout_seconds=args.timeout,
                    )
                    reading_taken = True
                    log_event("user confirmed measurement position")
                    if not send(""):
                        save_raw_output()
                        close_child()
                        log_event("ERROR status=23 ENTER not sent for measurement")
                        print("SpectraLab error: could not start measurement.", flush=True)
                        return 23
                    log_event("measurement started")
                else:
                    raw_path = save_raw_output()
                    close_child()
                    log_event(
                        f"ERROR status=25 repeated measurement prompt; raw={raw_path}"
                    )
                    print("SpectraLab error: repeated measurement prompt.", flush=True)
                    return 25

            elif idx == 4:
                log_chunks.append(str(child.after))
                raw_path = write_raw_file("".join(log_chunks))
                close_child()
                log_event(f"measurement complete; raw={raw_path}")
                print("Measurement complete.", flush=True)
                return 0

            elif idx in (5, 6, 7):
                failure_text = str(child.after).strip()
                log_chunks.append(str(child.after))
                raw_path = write_raw_file("".join(log_chunks))
                close_child()
                log_event(
                    f"ERROR status=24 spotread failure: {failure_text}; "
                    f"calibration_complete={calibration_complete}; raw={raw_path}"
                )
                print(
                    "SpectraLab error: spotread calibration/communication failure.",
                    flush=True,
                )
                return 24

            elif idx == 8:
                raw_path = save_raw_output()
                close_child()
                exit_status = getattr(child, "exitstatus", None)
                signal_status = getattr(child, "signalstatus", None)
                log_event(
                    "ERROR status=23 EOF before measurement result; "
                    f"calibration_complete={calibration_complete}; "
                    f"exitstatus={exit_status}; signalstatus={signal_status}; "
                    f"raw={raw_path}"
                )
                print("SpectraLab error: no measurement result detected.", flush=True)
                return 23

            elif idx == 9:
                raw_path = save_raw_output()
                close_child()
                log_event(
                    "ERROR status=22 timeout waiting for spotread; "
                    f"calibration_complete={calibration_complete}; raw={raw_path}"
                )
                print("SpectraLab error: timeout waiting for measurement.", flush=True)
                return 22

    except UserInputTimeout:
        raw_path = save_raw_output()
        close_child()
        log_event(
            "ERROR status=26 no ENTER received; "
            f"calibration_complete={calibration_complete}; raw={raw_path}"
        )
        return 26

    except KeyboardInterrupt:
        raw_path = save_raw_output()
        close_child()
        log_event(
            "ERROR status=130 interrupted by user; "
            f"calibration_complete={calibration_complete}; raw={raw_path}"
        )
        print("SpectraLab error: interrupted by user.", flush=True)
        return 130

    except Exception as exc:
        raw_path = save_raw_output()
        close_child()
        log_event(
            "ERROR status=23 unexpected bridge exception: "
            f"{type(exc).__name__}: {exc}; "
            f"calibration_complete={calibration_complete}; raw={raw_path}"
        )
        print(f"SpectraLab error: unexpected bridge failure: {exc}", flush=True)
        return 23


if __name__ == "__main__":
    sys.exit(main())
