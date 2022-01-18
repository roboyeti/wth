$ruby_version = "https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-3.0.3-1/rubyinstaller-devkit-3.0.3-1-x64.exe"
$install_path = "c:/Ruby30-x64"
Write-Host ""
Write-Host "=============================================================================================="
Write-Host "  What The Hash? - Windows installer"
Write-Host "                       Please be patient, it takes a long while..."
Write-Host "=============================================================================================="
Write-Host ""
Write-Host "Downloading Ruby Installer ..." –NoNewLine -ForegroundColor Cyan
Invoke-WebRequest $ruby_version -OutFile 'ruby_installer.exe'
Write-Host "Done" -ForegroundColor Green
Write-Host "Running Ruby Win32 Installer ..." –NoNewLine -ForegroundColor Cyan
Start-Process -FilePath ".\ruby_installer.exe" -ArgumentList "/silent","/dir=$install_path",'/tasks="assocfiles,modpath,noridkinstall"','/components="ruby,msys2"' -Wait
Write-Host "Done" -ForegroundColor Green
Write-Host "Installing MSYS dev kit ..." –NoNewLine -ForegroundColor Cyan
ridk install 1 3
Write-Host "Done" -ForegroundColor Green
Write-Host "Installing Ruby Gems ..." –NoNewLine -ForegroundColor Cyan
gem install openssl
bundle install
Write-Host "Done" -ForegroundColor Green
rm .\ruby_installer.exe
Write-Output "Installation is done!"
