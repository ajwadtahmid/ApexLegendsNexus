!include "MUI2.nsh"
!include "x64.nsh"

; Basic settings
Name "Apex Legends Nexus"
OutFile "$%GITHUB_WORKSPACE%\apex-legends-nexus-installer.exe"
InstallDir "$PROGRAMFILES\Apex Legends Nexus"
RequestExecutionLevel admin

; MUI Settings
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

Section "Install"
  SetOutPath "$INSTDIR"

  ; Copy all files from the Release folder
  File /r "$%GITHUB_WORKSPACE%\build\windows\x64\runner\Release\*.*"

  ; Create uninstaller
  WriteUninstaller "$INSTDIR\uninstall.exe"

  ; Create Start Menu shortcuts
  CreateDirectory "$SMPROGRAMS\Apex Legends Nexus"
  CreateShortcut "$SMPROGRAMS\Apex Legends Nexus\Apex Legends Nexus.lnk" "$INSTDIR\apex_legends_nexus.exe" "" "$INSTDIR\apex_legends_nexus.exe" 0
  CreateShortcut "$SMPROGRAMS\Apex Legends Nexus\Uninstall.lnk" "$INSTDIR\uninstall.exe"

  ; Create Desktop shortcut
  CreateShortcut "$DESKTOP\Apex Legends Nexus.lnk" "$INSTDIR\apex_legends_nexus.exe" "" "$INSTDIR\apex_legends_nexus.exe" 0

  ; Add to Add/Remove Programs
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ApexLegendsNexus" "DisplayName" "Apex Legends Nexus"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ApexLegendsNexus" "UninstallString" "$INSTDIR\uninstall.exe"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ApexLegendsNexus" "DisplayVersion" "0.9.0"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ApexLegendsNexus" "Publisher" "Ajwad Tahmid"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ApexLegendsNexus" "DisplayIcon" "$INSTDIR\apex_legends_nexus.exe"
SectionEnd

Section "Uninstall"
  ; Remove shortcuts
  RMDir /r "$SMPROGRAMS\Apex Legends Nexus"
  Delete "$DESKTOP\Apex Legends Nexus.lnk"

  ; Remove files
  RMDir /r "$INSTDIR"

  ; Remove registry entries
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ApexLegendsNexus"
SectionEnd
