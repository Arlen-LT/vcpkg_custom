& $env:VCPKG_ROOT/vcpkg install python3:x64-windows

$PYTHON3_ARITFACT_DIR="$env:VCPKG_ROOT/installed/x64-windows/tools/python3"
& ${PYTHON3_ARITFACT_DIR}/python --version
& ${PYTHON3_ARITFACT_DIR}/python -m ensurepip
& ${PYTHON3_ARITFACT_DIR}/python -m pip install --upgrade pip yt-dlp
Get-ChildItem -Path ${PYTHON3_ARITFACT_DIR} -include "__pycache__","*.py[co]" -Recurse | rm -r -Force
7z a python3_windows.zip ${PYTHON3_ARITFACT_DIR}/*