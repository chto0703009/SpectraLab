#!/usr/bin/env python3
"""Package a clean SpectraLab Git commit with a per-file SHA-256 manifest."""
from pathlib import Path
import argparse
import hashlib
import json
import subprocess
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def sha(path):
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(8*1024*1024), b''):
            digest.update(block)
    return digest.hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True, type=Path)
    args = parser.parse_args()
    if subprocess.check_output(['git', 'status', '--porcelain'], cwd=ROOT).strip():
        raise SystemExit('Commit reviewed changes before release packaging.')
    version = (ROOT/'VERSION').read_text().strip()
    commit = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    args.output.mkdir(parents=True, exist_ok=True)
    name = 'SpectraLab_v'+version
    output = args.output/(name+'.zip')
    if output.exists():
        raise SystemExit('Refusing to overwrite an existing release ZIP.')
    with tempfile.TemporaryDirectory() as temp:
        source = Path(temp)/'source.zip'
        subprocess.run(['git', 'archive', '--format=zip', '-o', str(source), commit], cwd=ROOT, check=True)
        root = Path(temp)/name
        with zipfile.ZipFile(source) as archive:
            archive.extractall(root)
            for entry in archive.infolist():
                file = root/entry.filename
                if file.is_file():
                    file.chmod((entry.external_attr >> 16) & 0o777 or 0o644)
        # Keep historical source notes in Git; they are not runtime/package content.
        for rel in ['spectralab/+spectralab/+analysis/C41 status A and M.txt',
                    'tests/classdef Report.txt', 'back.log', 'rp017_cleanup_1.sh']:
            file = root/rel
            if file.exists():
                file.unlink()  # New staging directory only.
        # Old published ZIPs remain in Git, but are never nested in a new release.
        for old_archive in (root/'releases').glob('*.zip'):
            old_archive.unlink()  # New staging directory only.
        files = sorted(p for p in root.rglob('*') if p.is_file())
        for path in files:
            relative = path.relative_to(root)
            if any(part in {'.git', '.venv', '.python', '__pycache__', 'work'} for part in relative.parts):
                raise SystemExit('Private/runtime content in package: '+str(relative))
            if path.suffix.lower() in {'.cr2', '.cr3', '.nef', '.arw', '.dng', '.zip'}:
                raise SystemExit('Unexpected capture or nested archive: '+str(relative))
        manifest = dict(Schema='spectralab.release-manifest.v1', Version=version, GitCommit=commit,
                        IncludesPrivateMeasurements=False,
                        Files=[dict(Path=p.relative_to(root).as_posix(), Bytes=p.stat().st_size, SHA256=sha(p)) for p in files])
        (root/'RELEASE_MANIFEST.json').write_text(json.dumps(manifest, indent=2)+'\n')
        with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
            for path in sorted(p for p in root.rglob('*') if p.is_file()):
                archive.write(path, name+'/'+path.relative_to(root).as_posix())
    (args.output/'SHA256SUMS.txt').write_text(sha(output)+'  '+output.name+'\n')
    print(output)


if __name__ == '__main__':
    main()
