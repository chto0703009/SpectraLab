#!/usr/bin/env python3
"""
SpectraLab manual-safe spotread bridge.

This bridge follows the v0.3.3_clean principle:

- spotread is controlled through pexpect
- the user must actively confirm in MATLAB/terminal before any key is sent
- no automatic measurement is triggered
- one measurement is taken
- raw spotread output is printed and returned to MATLAB

Safety principle:
The bridge must never send a measurement key until the user has confirmed
that the instrument is correctly placed.
"""

import argparse
import shutil
import sys
import time

try:
    import pexpect
except Exception as exc:
    print("SPECTRALAB_ERROR: pexpect is not available: %s" % exc)
    sys.exit(20)


def ask_user(message: str) -> None:
    print("\n" + message, flush=True)
    input("Press ENTER in MATLAB/terminal to continue, or Ctrl-C to abort: ")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--spotread", default="", help="Path to spotread executable")
    parser.add_argument("--options", default="-e -s", help="spotread options")
    parser.add_argument("--timeout", type=int, default=300)
    args = parser.parse_args()

    exe = args.spotread or shutil.which("spotread")
    if not exe:
        print("SPECTRALAB_ERROR: spotread not found", flush=True)
        return 21

    cmd = f'"{exe}" {args.options}'.strip()
    print(f"SPECTRALAB_COMMAND: {cmd}", flush=True)

    child = pexpect.spawn(cmd, encoding="utf-8", timeout=args.timeout)
    log_chunks = []
    reading_taken = False
    result_seen = False

    def capture():
        try:
            if child.before:
                log_chunks.append(child.before)
                print(child.before, end="", flush=True)
        except Exception:
            pass

    def safe_sendline(text: str) -> bool:
        try:
            if not child.isalive():
                return False
            child.sendline(text)
            return True
        except Exception as exc:
            print(f"\nSPECTRALAB_WARNING: could not send input to spotread: {exc}", flush=True)
            return False

    try:
        while True:
            idx = child.expect([
                r"hit any key to continue",
                r"Hit ESC or Q to exit.*take a reading:",
                r"Place instrument on spot to be measured",
                r"Result is XYZ:[^\r\n]*",
                r"Calibration complete",
                r"Calibration failed",
                r"Communications failure",
                r"Instrument initialisation failed",
                pexpect.EOF,
                pexpect.TIMEOUT,
            ])
            capture()

            if idx == 0:
                ask_user(
                    "SpectraLab calibration step:\n"
                    "Place the instrument on its white calibration reference."
                )
                safe_sendline("")

            elif idx == 1:
                if not reading_taken:
                    ask_user(
                        "SpectraLab measurement step:\n"
                        "Place the instrument on the light/spot to be measured."
                    )
                    reading_taken = True
                    safe_sendline("")
                else:
                    # We already measured. Quit without taking another reading.
                    safe_sendline("Q")

            elif idx == 2:
                # Informational line. Wait for the actual key prompt.
                continue

            elif idx == 3:
                matched = child.after
                log_chunks.append(matched)
                print(matched, end="", flush=True)
                result_seen = True
                time.sleep(0.2)
                safe_sendline("Q")

            elif idx == 4:
                log_chunks.append("Calibration complete")
                print("Calibration complete", flush=True)

            elif idx == 5:
                log_chunks.append("Calibration failed")
                print("Calibration failed", flush=True)
                safe_sendline("Q")
                return 24

            elif idx == 6:
                log_chunks.append("Communications failure")
                print("Communications failure", flush=True)
                safe_sendline("Q")
                return 24

            elif idx == 7:
                log_chunks.append("Instrument initialisation failed")
                print("Instrument initialisation failed", flush=True)
                safe_sendline("Q")
                return 24

            elif idx == 8:
                break

            elif idx == 9:
                print("\nSPECTRALAB_ERROR: timeout waiting for spotread", flush=True)
                safe_sendline("Q")
                return 22

        try:
            child.close(force=True)
        except Exception:
            pass

        output = "".join(log_chunks)

        if not result_seen and "Result is XYZ" not in output:
            print("\nSPECTRALAB_ERROR: no measurement result detected", flush=True)
            return 23

        print("\nSPECTRALAB_DONE", flush=True)
        return 0

    except KeyboardInterrupt:
        try:
            child.close(force=True)
        except Exception:
            pass
        print("\nSPECTRALAB_ERROR: interrupted by user", flush=True)
        return 130


if __name__ == "__main__":
    sys.exit(main())
