# PowerShell build script for Windows

# Script parameters - can be passed when calling the script
param(
    [string]$FxcPath = $null  # Path to fxc.exe (optional)
)

# Save initial location to restore at the end
$initialLocation = Get-Location

$logJsclFile = "java_jslc_files.txt"
$logBaseJavaFile = "base_java_files.txt"
$logGraphicsJavaFile = "graphics_java_files.txt"
$logDecoraGraphicsJavaFile = "decora_graphics_java_files.txt"
$logPrismGraphicsJavaFile = "prism_graphics_java_files.txt"
$logMetalGraphicsJavaFile = "metal_graphics_java_files.txt"

# Function to find FXC.exe in common locations
function Find-FxcCompiler {
    param([string]$CustomPath)

    # If custom path provided, use it
    if ($CustomPath -and (Test-Path $CustomPath)) {
        Write-Host "Using provided FXC: $CustomPath" -ForegroundColor Green
        return $CustomPath
    }

    # Check if fxc.exe is in PATH
    $fxcInPath = Get-Command "fxc.exe" -ErrorAction SilentlyContinue
    if ($fxcInPath) {
        Write-Host "Found FXC in PATH: $($fxcInPath.Source)" -ForegroundColor Green
        return $fxcInPath.Source
    }

    # Search in common Windows SDK locations
    $commonPaths = @(
        "${env:ProgramFiles(x86)}\Windows Kits\10\bin\*\x64\fxc.exe",
        "${env:ProgramFiles(x86)}\Windows Kits\10\bin\*\x86\fxc.exe",
        "${env:ProgramFiles}\Windows Kits\10\bin\*\x64\fxc.exe",
        "${env:ProgramFiles}\Windows Kits\10\bin\*\x86\fxc.exe"
    )

    foreach ($pattern in $commonPaths) {
        $found = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) {
            Write-Host "Found FXC in Windows SDK: $($found.FullName)" -ForegroundColor Green
            return $found.FullName
        }
    }

    Write-Host "FXC not found - HLSL shader compilation will be skipped" -ForegroundColor Yellow
    Write-Host "  To enable HLSL compilation:" -ForegroundColor Gray
    Write-Host "    1. Install Windows SDK" -ForegroundColor Gray
    Write-Host "    2. Or run: .\script.ps1 -FxcPath 'C:\path\to\fxc.exe'" -ForegroundColor Gray
    return $null
}

Write-Host "=== Detecting build tools ===" -ForegroundColor Cyan
$fxcExe = Find-FxcCompiler -CustomPath $FxcPath

Write-Host "=== Cleaning build directories ===" -ForegroundColor Cyan
if (Test-Path "files") {
    Remove-Item -Recurse -Force "files"
}
New-Item -ItemType Directory -Path "files" | Out-Null

Set-Location ..
$rootPath = Get-Location
$auxFiles = Join-Path $rootPath "scripts\files"

# ========== javafx.base module ==========
Write-Host "`n=== Building javafx.base module ===" -ForegroundColor Cyan

Set-Location (Join-Path $rootPath "modules\javafx.base")
$basePath = Get-Location
if (Test-Path "build") {
    Remove-Item -Recurse -Force "build"
}

Write-Host "Processing version info..." -ForegroundColor Yellow
# Generate VersionInfo.java from template
$versionInfoDir = Join-Path $basePath "build\gensrc\java\com\sun\javafx\runtime"
New-Item -ItemType Directory -Path $versionInfoDir -Force | Out-Null
Copy-Item (Join-Path $basePath "src\main\version-info\VersionInfo.java") $versionInfoDir

Write-Host "Compiling Java sources..." -ForegroundColor Yellow
# Compile all Java sources in javafx.base
$logFile = Join-Path $auxFiles $logBaseJavaFile
"--release", "24", "-Werror", "-Xlint:removal", "-Xlint:missing-explicit-ctor", "-implicit:none",
"-d", (Join-Path $basePath "build\classes\java\main"),
"-encoding", "UTF-8" | Out-File -FilePath $logFile -Encoding ascii

"--module-source-path",
"$rootPath\modules\*\src\main\java;$rootPath\modules\*\build\gensrc\{java,jsl-decora,jsl-prism}" |
Out-File -FilePath $logFile -Append -Encoding ascii

Get-ChildItem -Path (Join-Path $basePath "src\main\java") -Filter "*.java" -Recurse |
    ForEach-Object { $_.FullName } | Out-File -FilePath $logFile -Append -Encoding ascii

Get-ChildItem -Path (Join-Path $basePath "build\gensrc\java\com\sun\javafx\runtime") -Filter "*.java" -Recurse |
    ForEach-Object { $_.FullName } | Out-File -FilePath $logFile -Append -Encoding ascii

javac `@"$logFile"

# ========== javafx.graphics module ==========
Write-Host "`n=== Building javafx.graphics module ===" -ForegroundColor Cyan

Set-Location (Join-Path $rootPath "modules\javafx.graphics")
$graphicsPath = Get-Location
if (Test-Path "build") {
    Remove-Item -Recurse -Force "build"
}

Write-Host "Compiling Java sources..." -ForegroundColor Yellow
# Compile main graphics Java sources
$logFile = Join-Path $auxFiles $logGraphicsJavaFile
"--release", "24", "-Werror", "-Xlint:removal", "-Xlint:missing-explicit-ctor", "-implicit:none",
"-d", (Join-Path $graphicsPath "build\classes\java\main"),
"-encoding", "UTF-8" | Out-File -FilePath $logFile -Encoding ascii

"--module-source-path",
"$rootPath\modules\*\src\main\java;$rootPath\modules\*\build\gensrc\{java,jsl-decora,jsl-prism}" |
Out-File -FilePath $logFile -Append -Encoding ascii

"--module-path",
(Join-Path $basePath "build\classes\java\main\javafx.base") |
Out-File -FilePath $logFile -Append -Encoding ascii

"--add-modules=javafx.base" | Out-File -FilePath $logFile -Append -Encoding ascii

Get-ChildItem -Path (Join-Path $graphicsPath "src\main\java") -Filter "*.java" -Recurse |
    ForEach-Object { $_.FullName } | Out-File -FilePath $logFile -Append -Encoding ascii

javac `@"$logFile"

Write-Host "Downloading ANTLR if needed..." -ForegroundColor Yellow
# Download ANTLR parser generator
$antlrJar = "antlr-4.13.2-complete.jar"
$antlrUrl = "https://www.antlr.org/download/$antlrJar"
$antlrFile = Join-Path $auxFiles $antlrJar

if (-not (Test-Path $antlrFile)) {
    Write-Host "  Downloading ANTLR..." -ForegroundColor Gray
    Invoke-WebRequest -Uri $antlrUrl -OutFile $antlrFile
}

Write-Host "Generating grammar sources..." -ForegroundColor Yellow
# Generate parser from JSL grammar
Set-Location "src\jslc\antlr"
java -cp $antlrFile org.antlr.v4.Tool -o (Join-Path $graphicsPath "build\gensrc\antlr") `
    -package com.sun.scenario.effect.compiler -visitor com/sun/scenario/effect/compiler/JSL.g4
Set-Location $graphicsPath

Write-Host "Compiling JSLC compiler..." -ForegroundColor Yellow
# Compile the JSL compiler itself
$logFile = Join-Path $auxFiles $logJsclFile
"--release", "24", "-nowarn",
"-d", (Join-Path $graphicsPath "build\classes\java\jslc"),
"-encoding", "UTF-8",
"-cp", $antlrFile | Out-File -FilePath $logFile -Encoding ascii

Get-ChildItem -Path (Join-Path $graphicsPath "src\jslc\java") -Filter "*.java" -Recurse |
    ForEach-Object { $_.FullName } | Out-File -FilePath $logFile -Append -Encoding ascii

Get-ChildItem -Path (Join-Path $graphicsPath "build\gensrc\antlr") -Filter "*.java" -Recurse |
    ForEach-Object { $_.FullName } | Out-File -FilePath $logFile -Append -Encoding ascii

javac `@"$logFile"

Write-Host "Compiling Decora shader compilers..." -ForegroundColor Yellow
# Compile Decora effect compilers
$logFile = Join-Path $auxFiles $logDecoraGraphicsJavaFile
"--release", "24", "-nowarn", "-implicit:none",
"-d", (Join-Path $graphicsPath "build\classes\jsl-compilers\decora"),
"-encoding", "UTF-8" | Out-File -FilePath $logFile -Encoding ascii

"-cp",
"$(Join-Path $graphicsPath 'build\classes\java\jslc');$antlrFile" |
Out-File -FilePath $logFile -Append -Encoding ascii

"--module-path",
"$(Join-Path $basePath 'build\classes\java\main');$(Join-Path $graphicsPath 'build\classes\java\main')" |
Out-File -FilePath $logFile -Append -Encoding ascii

"--add-modules=javafx.graphics",
"--add-exports=javafx.graphics/com.sun.scenario.effect=ALL-UNNAMED",
"--add-exports=javafx.graphics/com.sun.scenario.effect.light=ALL-UNNAMED",
"--add-exports=javafx.graphics/com.sun.scenario.effect.impl.state=ALL-UNNAMED" |
Out-File -FilePath $logFile -Append -Encoding ascii

Get-ChildItem -Path (Join-Path $graphicsPath "src\main\jsl-decora") -Filter "*.java" -Recurse |
    ForEach-Object { $_.FullName } | Out-File -FilePath $logFile -Append -Encoding ascii

javac `@"$logFile"

Write-Host "Generating Decora shaders..." -ForegroundColor Yellow
# Generate Decora effect shaders (GLSL, HLSL, Metal)
New-Item -ItemType Directory -Path (Join-Path $graphicsPath "build\gensrc\mtl-headers") -Force | Out-Null

$javaArgs = @(
    "--module-path=$(Join-Path $basePath 'build\classes\java\main');$(Join-Path $graphicsPath 'build\classes\java\main')",
    "--add-modules=javafx.graphics",
    "--add-exports=javafx.graphics/com.sun.scenario.effect=ALL-UNNAMED",
    "--add-exports=javafx.graphics/com.sun.scenario.effect.light=ALL-UNNAMED",
    "--add-exports=javafx.graphics/com.sun.scenario.effect.impl.state=ALL-UNNAMED",
    "-cp", "$(Join-Path $basePath 'build\classes\java\main');$antlrFile;$(Join-Path $graphicsPath 'build\classes\java\jslc');$(Join-Path $graphicsPath 'src\jslc\resources');$(Join-Path $graphicsPath 'build\classes\jsl-compilers\decora');$(Join-Path $graphicsPath 'src\main\jsl-decora')",
    "-Dfile.encoding=UTF-8",
    "GenAllDecoraShaders",
    "-i", (Join-Path $graphicsPath "src\main\jsl-decora"),
    "-o", (Join-Path $graphicsPath "build\gensrc\jsl-decora"),
    "-t", "-pkg", "com/sun/scenario/effect", "-all", "GenAllDecoraShaders"
)
& java $javaArgs

Write-Host "Processing Decora HLSL shaders..." -ForegroundColor Yellow
# Compile HLSL shaders for DirectX (requires FXC.exe)
$hlslDir = Join-Path $graphicsPath "build\hlsl\Decora\com\sun\scenario\effect\impl\hw\d3d\hlsl"
New-Item -ItemType Directory -Path $hlslDir -Force | Out-Null

$decoraHlslFiles = Get-ChildItem -Path (Join-Path $graphicsPath "build\gensrc\jsl-decora\com\sun\scenario\effect\impl\hw\d3d\hlsl") -Filter "*.hlsl" -ErrorAction SilentlyContinue

if ($fxcExe -and $decoraHlslFiles) {
    Write-Host "  Compiling $($decoraHlslFiles.Count) HLSL shaders with FXC..." -ForegroundColor Gray
    $decoraHlslFiles | ForEach-Object {
        $outFile = Join-Path $hlslDir "$($_.BaseName).obj"
        & $fxcExe /nologo /T ps_3_0 /Fo $outFile $_.FullName
    }

    # Copy compiled .obj files to output
    Get-ChildItem -Path (Join-Path $graphicsPath "build\hlsl\Decora") -Filter "*.obj" -Recurse |
    ForEach-Object {
        $relativePath = $_.FullName.Substring((Join-Path $graphicsPath "build\hlsl\Decora\").Length)
        $targetPath = Join-Path $graphicsPath "build\classes\java\main\javafx.graphics\$relativePath"
        $targetDir = Split-Path -Parent $targetPath
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        Copy-Item $_.FullName $targetPath
    }
} elseif ($decoraHlslFiles) {
    Write-Host "  Skipping HLSL compilation (FXC not available) - found $($decoraHlslFiles.Count) files" -ForegroundColor Yellow
}

Write-Host "Copying Decora fragment shaders..." -ForegroundColor Yellow
# Copy GLSL fragment shaders to output
$fragCount = 0
Get-ChildItem -Path (Join-Path $graphicsPath "build\gensrc\jsl-decora") -Filter "*.frag" -Recurse |
ForEach-Object {
    $fragCount++
    $relativePath = $_.FullName.Substring((Join-Path $graphicsPath "build\gensrc\jsl-decora\").Length)
    $targetPath = Join-Path $graphicsPath "build\classes\java\main\javafx.graphics\$relativePath"
    $targetDir = Split-Path -Parent $targetPath
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    Copy-Item $_.FullName $targetPath
}
Write-Host "  Copied $fragCount fragment shader files" -ForegroundColor Gray

Write-Host "Compiling Prism shader compilers..." -ForegroundColor Yellow
# Compile Prism rendering pipeline compilers
$logFile = Join-Path $auxFiles $logPrismGraphicsJavaFile
"--release", "24", "-nowarn", "-implicit:none",
"-d", (Join-Path $graphicsPath "build\classes\jsl-compilers\prism"),
"-encoding", "UTF-8" | Out-File -FilePath $logFile -Encoding ascii

"-cp",
"$(Join-Path $graphicsPath 'build\classes\java\jslc');$antlrFile" |
Out-File -FilePath $logFile -Append -Encoding ascii

"--module-path",
"$(Join-Path $basePath 'build\classes\java\main');$(Join-Path $graphicsPath 'build\classes\java\main')" |
Out-File -FilePath $logFile -Append -Encoding ascii

"--add-modules=javafx.graphics",
"--add-exports=javafx.graphics/com.sun.scenario.effect=ALL-UNNAMED",
"--add-exports=javafx.graphics/com.sun.scenario.effect.light=ALL-UNNAMED",
"--add-exports=javafx.graphics/com.sun.scenario.effect.impl.state=ALL-UNNAMED" |
Out-File -FilePath $logFile -Append -Encoding ascii

Get-ChildItem -Path (Join-Path $graphicsPath "src\main\jsl-prism") -Filter "*.java" -Recurse |
    ForEach-Object { $_.FullName } | Out-File -FilePath $logFile -Append -Encoding ascii

javac `@"$logFile"

Write-Host "Generating Prism shaders..." -ForegroundColor Yellow
# Generate Prism rendering shaders from JSL files
$jslFiles = Get-ChildItem -Path (Join-Path $graphicsPath "src\main\jsl-prism") -Filter "*.jsl"
Write-Host "  Compiling $($jslFiles.Count) JSL files..." -ForegroundColor Gray
$jslFiles | ForEach-Object {
    $javaArgs = @(
        "--module-path=$(Join-Path $basePath 'build\classes\java\main');$(Join-Path $graphicsPath 'build\classes\java\main')",
        "--add-modules=javafx.graphics",
        "-cp", "$(Join-Path $basePath 'build\classes\java\main');$antlrFile;$(Join-Path $graphicsPath 'build\classes\java\jslc');$(Join-Path $graphicsPath 'src\jslc\resources');$(Join-Path $graphicsPath 'build\classes\jsl-compilers\prism');$(Join-Path $graphicsPath 'src\main\jsl-prism')",
        "-Dfile.encoding=UTF-8",
        "CompileJSL",
        "-i", (Join-Path $graphicsPath "src\main\jsl-prism"),
        "-o", (Join-Path $graphicsPath "build\gensrc\jsl-prism"),
        "-t", "-pkg", "com/sun/prism", "-d3d", "-es2", "-mtl", "-name", $_.FullName
    )
    & java $javaArgs
}

Write-Host "Processing Prism HLSL shaders..." -ForegroundColor Yellow
# Compile Prism HLSL shaders for DirectX
$hlslDir = Join-Path $graphicsPath "build\hlsl\Prism\com\sun\prism\d3d\hlsl"
New-Item -ItemType Directory -Path $hlslDir -Force | Out-Null

$prismHlslFiles = Get-ChildItem -Path (Join-Path $graphicsPath "build\gensrc\jsl-prism\com\sun\prism\d3d\hlsl") -Filter "*.hlsl" -ErrorAction SilentlyContinue

if ($fxcExe -and $prismHlslFiles) {
    Write-Host "  Compiling $($prismHlslFiles.Count) HLSL shaders with FXC..." -ForegroundColor Gray
    $prismHlslFiles | ForEach-Object {
        $outFile = Join-Path $hlslDir "$($_.BaseName).obj"
        & $fxcExe /nologo /T ps_3_0 /Fo $outFile $_.FullName
    }

    # Copy compiled .obj files to output
    Get-ChildItem -Path (Join-Path $graphicsPath "build\hlsl\Prism") -Filter "*.obj" -Recurse |
    ForEach-Object {
        $relativePath = $_.FullName.Substring((Join-Path $graphicsPath "build\hlsl\Prism\").Length)
        $targetPath = Join-Path $graphicsPath "build\classes\java\main\javafx.graphics\$relativePath"
        $targetDir = Split-Path -Parent $targetPath
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        Copy-Item $_.FullName $targetPath
    }
} elseif ($prismHlslFiles) {
    Write-Host "  Skipping HLSL compilation (FXC not available) - found $($prismHlslFiles.Count) files" -ForegroundColor Yellow
}

Write-Host "Copying Prism fragment shaders..." -ForegroundColor Yellow
# Copy GLSL fragment shaders to output
$fragCount = 0
Get-ChildItem -Path (Join-Path $graphicsPath "build\gensrc\jsl-prism") -Filter "*.frag" -Recurse |
ForEach-Object {
    $fragCount++
    $relativePath = $_.FullName.Substring((Join-Path $graphicsPath "build\gensrc\jsl-prism\").Length)
    $targetPath = Join-Path $graphicsPath "build\classes\java\main\javafx.graphics\$relativePath"
    $targetDir = Split-Path -Parent $targetPath
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    Copy-Item $_.FullName $targetPath
}
Write-Host "  Copied $fragCount fragment shader files" -ForegroundColor Gray

Write-Host "`n=== Build complete! ===" -ForegroundColor Green

# Return to initial location
Set-Location $initialLocation
