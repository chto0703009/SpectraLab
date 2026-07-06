#!/usr/bin/env python3
"""
Deprecated.

ArgyllCMS spotread calibration state is process-local. SpectraLab therefore
performs calibration and measurement in the same spotread session via
spotread_manual_measure.py.
"""
print("SPECTRALAB_NOTE: separate calibration bridge is deprecated.")
print("Use sess.measure(), which performs calibration and measurement in one spotread session.")
raise SystemExit(0)
