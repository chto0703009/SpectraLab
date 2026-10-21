"""Convert a locally supplied X-Rite SG Lab table; does not redistribute data."""
import argparse
import hashlib
import json
import re
from pathlib import Path


def convert(source, destination):
    raw = source.read_bytes()
    text = raw.decode('utf-8-sig')
    pattern = re.compile(r'^\s*([A-N](?:10|[1-9]))\s+([-+]?\d+(?:\.\d+)?)\s+([-+]?\d+(?:\.\d+)?)\s+([-+]?\d+(?:\.\d+)?)\s*$')
    patches = []
    notices = []
    for line in text.splitlines():
        match = pattern.fullmatch(line)
        if match:
            patch, *values = match.groups()
            patches.append({'PatchID': patch, 'Lab': list(map(float, values))})
        elif line.strip() and not line.startswith('Patch\t'):
            notices.append(line.strip())
    expected = {f'{letter}{row}' for letter in 'ABCDEFGHIJKLMN' for row in range(1, 11)}
    assert len(patches) == 140 and {p['PatchID'] for p in patches} == expected, 'Expected 140 unique SG patches'
    notice = '\n'.join(notices)
    assert 'illuminant D50 and 2 degree observer' in notice, 'Missing declared colorimetric conditions'
    document = {
        'Schema': 'spectralab.colorchecker-nominal-lab.v1',
        'Target': 'X-Rite ColorChecker Digital SG',
        'DataKind': 'manufacturer_typical_reference_values',
        'ColorSpace': 'CIELAB', 'Illuminant': 'D50', 'ObserverDegrees': 2,
        'LabComponents': ['L*', 'a*', 'b*'], 'PatchCount': len(patches),
        'PatchOrder': 'source_file_order',
        'Source': {'FileName': source.name, 'SHA256': hashlib.sha256(raw).hexdigest(),
                   'Attribution': 'X-Rite, Inc.', 'OriginalNotice': notice},
        'Usage': 'Manufacturer typical Lab values; not measured spectra or a measurement of the individual chart.',
        'License': {'Identifier': None, 'GPLLicensed': False,
                    'Terms': 'Personal and educational use; commercial use requires a license from X-Rite, Inc. See OriginalNotice.'},
        'Patches': patches,
    }
    destination.write_text(json.dumps(document, ensure_ascii=False, indent=2, allow_nan=False) + '\n', encoding='utf-8')
    loaded = json.loads(destination.read_text())
    assert loaded['Patches'] == patches
    return document


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    parser.add_argument('destination', type=Path)
    args = parser.parse_args()
    result = convert(args.source, args.destination)
    print(f"Verified {result['PatchCount']} patches: {args.destination}")
