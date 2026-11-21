# 새 컴퓨터에서 Blender MCP 작업 환경을 한 번에 구축하는 스크립트
# 1) uv 설치  2) Blender MCP 애드온 설치·활성화  3) Antigravity / Claude Code MCP 설정에 blender 서버 등록
# 사용법: PowerShell에서  powershell -ExecutionPolicy Bypass -File .\setup.ps1

$ErrorActionPreference = "Stop"

# ---------- 1. uv (uvx) ----------
$uvx = (Get-Command uvx -ErrorAction SilentlyContinue).Source
if (-not $uvx) {
    Write-Host "[1/3] uv 설치 중..."
    powershell -ExecutionPolicy Bypass -c "irm https://astral.sh/uv/install.ps1 | iex"
    $uvx = Join-Path $env:USERPROFILE ".local\bin\uvx.exe"
}
if (-not (Test-Path $uvx)) { throw "uvx를 찾을 수 없습니다. 터미널을 다시 열고 재실행하세요." }
Write-Host "[1/3] uvx: $uvx"

# ---------- 2. Blender 애드온 ----------
$blenderDir = Get-ChildItem "C:\Program Files\Blender Foundation" -Directory -ErrorAction SilentlyContinue |
    Sort-Object { [version]($_.Name -replace '[^\d.]', '') } -Descending | Select-Object -First 1
if (-not $blenderDir) { throw "Blender가 설치돼 있지 않습니다. https://www.blender.org/download/ 에서 설치 후 재실행하세요." }
$blenderExe = Join-Path $blenderDir.FullName "blender.exe"
$ver = $blenderDir.Name -replace '[^\d.]', ''
$addonDir = Join-Path $env:APPDATA "Blender Foundation\Blender\$ver\scripts\addons"
New-Item -ItemType Directory -Force $addonDir | Out-Null
Write-Host "[2/3] Blender $ver 에 애드온 설치 중..."
Invoke-WebRequest "https://raw.githubusercontent.com/ahujasid/blender-mcp/main/addon.py" -OutFile (Join-Path $addonDir "blender_mcp.py")
& $blenderExe --background --python-expr "import bpy, addon_utils; bpy.ops.preferences.addon_enable(module='blender_mcp'); bpy.ops.wm.save_userpref(); print('ADDON_ENABLED', addon_utils.check('blender_mcp'))" 2>&1 |
    Select-String "ADDON_ENABLED"

# ---------- 3. MCP 설정 등록 ----------
Write-Host "[3/3] MCP 설정 등록 중..."
$py = @'
import json, os, sys
uvx = sys.argv[1]
server = {"command": uvx, "args": ["blender-mcp"], "env": {"PYTHONUTF8": "1"}}
home = os.path.expanduser("~")
targets = [
    (os.path.join(home, ".gemini", "config", "mcp_config.json"), False),   # Antigravity
    (os.path.join(home, ".claude.json"), True),                            # Claude Code (있을 때만)
]
for path, only_if_exists in targets:
    if only_if_exists and not os.path.exists(path):
        print("skip (없음):", path); continue
    os.makedirs(os.path.dirname(path), exist_ok=True)
    data = json.load(open(path, encoding="utf-8")) if os.path.exists(path) else {}
    entry = dict(server)
    if path.endswith(".claude.json"):
        entry["type"] = "stdio"
    data.setdefault("mcpServers", {})["blender"] = entry
    json.dump(data, open(path, "w", encoding="utf-8"), indent=2, ensure_ascii=False)
    print("등록:", path)
'@
$py | & (Join-Path (Split-Path $uvx) "uv.exe") run --no-project python - $uvx

# MCP 서버 패키지 미리 받아두기
& $uvx --from blender-mcp python -c "import importlib.metadata as m; print('blender-mcp', m.version('blender-mcp'))"

Write-Host ""
Write-Host "완료! Antigravity / Claude Code를 재시작하고,"
Write-Host "Blender에서 Knight.blend를 연 뒤 N 사이드바 > BlenderMCP 탭에서 서버를 켜세요."
