Unicode True
!define REGEDIT_UNINSTALL "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\@APP_NAME@"

Outfile "..\@APP_NAME@-v@VERSION@-setup.exe"
InstallDir "${OUTPUT_DIR_APP}"

Name "@NAME@ @VERSION@"

Section

# Check to see if already installed
ReadRegStr $R0 HKLM ${REGEDIT_UNINSTALL} "UninstallString"
IfFileExists $R0 0
  Exec $R0

SetOutPath $INSTDIR
CreateDirectory ${OUTPUT_DIR_USER}

# ADD winsw.xml
File "@BUILD_DIR@/winsw.xml"

# ADD log4j2-example.xml
File "/oname=${OUTPUT_DIR_USER}\log4j2-example.xml" "@BUILD_DIR@/log4j2.xml"

# ADD application-example.yml
File "/oname=${OUTPUT_DIR_USER}\application-example.yml" "@BUILD_DIR@/application.yml"

# ADD Jar file
File "/oname=$INSTDIR\@OUTPUT_JAR_NAME@" "@BUILD_DIR@/@OUTPUT_JAR_NAME@"

# ADD WinSW exec
File "/oname=$INSTDIR\winsw.exe" "@WINSW_EXEC_PATH@"

# ADD LICENCE
File "/oname=$INSTDIR\@OUTPUT_LICENCE_FILE@" "@BUILD_DIR@/@OUTPUT_LICENCE_FILE@"

# ADD THIRD-PARTY
File "/oname=$INSTDIR\@OUTPUT_THIRDPARTY_FILE@" "@BUILD_DIR@/@OUTPUT_THIRDPARTY_FILE@"

# ADD Uninstaller
WriteUninstaller $INSTDIR\uninstaller.exe

# Deploy service
ExecWait '"$INSTDIR\winsw.exe" install "$INSTDIR\winsw.xml"'

# Put Uninstall regedit values
WriteRegStr HKLM "${REGEDIT_UNINSTALL}" "DisplayName" "@NAME@"
WriteRegStr HKLM "${REGEDIT_UNINSTALL}" "UninstallString" "$INSTDIR\uninstaller.exe"
WriteRegStr HKLM "${REGEDIT_UNINSTALL}" "DisplayVersion" "@VERSION@"
WriteRegStr HKLM "${REGEDIT_UNINSTALL}" "InstallLocation" "$INSTDIR"
WriteRegStr HKLM "${REGEDIT_UNINSTALL}" "QuietUninstallString" "$\"$INSTDIR\uninstaller.exe$\" /S"
WriteRegDWORD HKLM "${REGEDIT_UNINSTALL}" "NoModify" 1
WriteRegDWORD HKLM "${REGEDIT_UNINSTALL}" "NoRepair" 1
WriteRegDWORD HKLM "${REGEDIT_UNINSTALL}" "URLInfoAbout" "@URL@"
WriteRegDWORD HKLM "${REGEDIT_UNINSTALL}" "Publisher" "@ORG_NAME@ - @ORG_URL@"
# You can add DisplayIcon

# Display ends messages  
DetailPrint ""
DetailPrint "@NAME@ is now correctly installed on $INSTDIR"
DetailPrint "You will found a uninstall script this directory."
DetailPrint "You must create and setup application.yml and log4j2.xml in"
DetailPrint "${OUTPUT_DIR_USER} directory (you will found example in this directory)."
DetailPrint "Also, Windows service in declared, but not started and set to Manual."
DetailPrint "Change this after setup config files."
DetailPrint "Don't forget to setup a compatible JVM (Java @JAVA_VERSION@), and put java.exe directory in PATH."

SectionEnd

Section "Uninstall"

ExecWait '"$INSTDIR\winsw.exe" stop "$INSTDIR\winsw.xml"'
ExecWait '"$INSTDIR\winsw.exe" uninstall "$INSTDIR\winsw.xml"'

Delete "$INSTDIR\uninstaller.exe"
Delete "$INSTDIR\@OUTPUT_JAR_NAME@"
Delete "$INSTDIR\winsw.exe"
Delete "$INSTDIR\winsw.xml"
Delete "$INSTDIR\@OUTPUT_MAN_FILE@"
Delete "$INSTDIR\@OUTPUT_LICENCE_FILE@"
Delete "$INSTDIR\@OUTPUT_THIRDPARTY_FILE@"
Delete "${OUTPUT_DIR_USER}\log4j2-example.xml"
Delete "${OUTPUT_DIR_USER}\application-example.yml"
RMDir "$INSTDIR"

DeleteRegKey HKLM "${REGEDIT_UNINSTALL}"

SectionEnd
