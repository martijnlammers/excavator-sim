# Install-ConanDependencies.ps1
# Script to install Conan dependencies into the build folder

# Ensure build folder exists
$buildDir = Join-Path (Get-Location) "build"
if (-Not (Test-Path $buildDir)) 
{
    New-Item -ItemType Directory -Path $buildDir | Out-Null
    Write-Host "Created build directory at $buildDir"
}

# Detect Conan profile (forces regeneration if needed)
Write-Host "Detecting Conan profile..."
conan profile detect --force

# Install dependencies into build folder
Write-Host "Installing Conan dependencies..."
conan install . --output-folder=build --build=missing

# Confirm toolchain file exists
$toolchainFile = Join-Path $buildDir "conan_toolchain.cmake"
if (Test-Path $toolchainFile) 
{
    Write-Host "Conan toolchain generated: $toolchainFile"
} 
else 
{
    Write-Warning "Toolchain file not found. Check Conan output for errors."
}
