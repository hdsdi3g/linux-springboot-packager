Unicode True
!define REGEDIT_UNINSTALL "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}"

Outfile "..\packages\${APP_NAME}-v${VERSION}-setup.exe"
InstallDir "${INSTALL_PATH}"

Name "${APP_NAME} ${VERSION}"

Section

# Check to see if already installed
ReadRegStr $R0 HKLM ${REGEDIT_UNINSTALL} "UninstallString"
IfFileExists $R0 0
  Exec $R0

SetOutPath $INSTDIR
CreateDirectory ${WORKING_PATH}

# ADD winsw.xml
File ${PROJECT_DIR}/winsw.xml

# ADD log4j2-example.xml
File "/oname=${WORKING_PATH}\log4j2-example.xml" "${PROJECT_DIR}/log4j2-windows.xml"

# ADD application-example.yml
File "/oname=${WORKING_PATH}\application-example.yml" "${PROJECT_DIR}/application.yml"

# ADD Jar file
File "/oname=$INSTDIR\app.jar" "${PROJECT_SPRING_EXEC}"

# ADD WinSW exec
File "/oname=$INSTDIR\winsw.exe" "${WINSW_EXEC_PATH}"

# ADD Uninstaller
WriteUninstaller $INSTDIR\uninstaller.exe

# Deploy service
ExecWait '"$INSTDIR\winsw.exe" install "$INSTDIR\winsw.xml"'

# Put Uninstall regedit values
WriteRegStr HKLM "${REGEDIT_UNINSTALL}" "DisplayName" "${APP_LONG_NAME}"
WriteRegStr HKLM "${REGEDIT_UNINSTALL}" "UninstallString" "$INSTDIR\uninstaller.exe"
WriteRegStr HKLM "${REGEDIT_UNINSTALL}" "DisplayVersion" "${VERSION}"
WriteRegStr HKLM "${REGEDIT_UNINSTALL}" "InstallLocation" "$INSTDIR"
WriteRegStr HKLM "${REGEDIT_UNINSTALL}" "QuietUninstallString" "$\"$INSTDIR\uninstaller.exe$\" /S"
WriteRegDWORD HKLM "${REGEDIT_UNINSTALL}" "NoModify" 1
WriteRegDWORD HKLM "${REGEDIT_UNINSTALL}" "NoRepair" 1
WriteRegDWORD HKLM "${REGEDIT_UNINSTALL}" "URLInfoAbout" "${APP_URL}"
WriteRegDWORD HKLM "${REGEDIT_UNINSTALL}" "Publisher" "${APP_VENDOR}"
# You can add DisplayIcon

# Display ends messages  
DetailPrint ""
DetailPrint "${APP_LONG_NAME} is now correctly installed on $INSTDIR"
DetailPrint "You will found a uninstall script this directory."
DetailPrint "You must create and setup application.yml and log4j2.xml in"
DetailPrint "${WORKING_PATH} directory (you will found example in this directory)."
DetailPrint "Also, Windows service in declared, but not started and set to Manual."
DetailPrint "Change this after setup config files."
DetailPrint "Don't forget to setup a compatible JVM, and put java.exe directory in PATH."

SectionEnd

Section "Uninstall"

ExecWait '"$INSTDIR\winsw.exe" stop "$INSTDIR\winsw.xml"'
ExecWait '"$INSTDIR\winsw.exe" uninstall "$INSTDIR\winsw.xml"'

Delete "$INSTDIR\uninstaller.exe"
Delete "$INSTDIR\app.jar"
Delete "$INSTDIR\winsw.exe"
Delete "$INSTDIR\winsw.xml"
Delete "${WORKING_PATH}\log4j2-example.xml"
Delete "${WORKING_PATH}\application-example.yml"
RMDir "$INSTDIR"

DeleteRegKey HKLM "${REGEDIT_UNINSTALL}"

SectionEnd
