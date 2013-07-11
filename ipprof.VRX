/*:VRX         Main
*/
/*  Main
*/
Main:
/*  Process the arguments.
    Get the parent window.
*/
    parse source . calledAs .
    parent = ""
    argCount = arg()
    argOff = 0
    if( calledAs \= "COMMAND" )then do
        if argCount >= 1 then do
            parent = arg(1)
            argCount = argCount - 1
            argOff = 1
        end
    end; else do
        call VROptions 'ImplicitNames'
        call VROptions 'NoEchoQuit'
    end
    InitArgs.0 = argCount
    if( argCount > 0 )then do i = 1 to argCount
        InitArgs.i = arg( i + argOff )
    end
    drop calledAs argCount argOff

/*  Load the windows
*/
    call VRInit
    parse source . . spec
    _VREPrimaryWindowPath = ,
        VRParseFileName( spec, "dpn" ) || ".VRW"
    _VREPrimaryWindow = ,
        VRLoad( parent, _VREPrimaryWindowPath )
    drop parent spec
    if( _VREPrimaryWindow == "" )then do
        call VRMessage "", "Cannot load window:" VRError(), ,
            "Error!"
        _VREReturnValue = 32000
        signal _VRELeaveMain
    end

/*  Process events
*/
    call Init
    signal on halt
    do while( \ VRGet( _VREPrimaryWindow, "Shutdown" ) )
        _VREEvent = VREvent()
        interpret _VREEvent
    end
_VREHalt:
    _VREReturnValue = Fini()
    call VRDestroy _VREPrimaryWindow
_VRELeaveMain:
    call VRFini
exit _VREReturnValue

VRLoadSecondary:
    __vrlsWait = abbrev( 'WAIT', translate(arg(2)), 1 )
    if __vrlsWait then do
        call VRFlush
    end
    __vrlsHWnd = VRLoad( VRWindow(), VRWindowPath(), arg(1) )
    if __vrlsHWnd = '' then signal __vrlsDone
    if __vrlsWait \= 1 then signal __vrlsDone
    call VRSet __vrlsHWnd, 'WindowMode', 'Modal' 
    __vrlsTmp = __vrlsWindows.0
    if( DataType(__vrlsTmp) \= 'NUM' ) then do
        __vrlsTmp = 1
    end
    else do
        __vrlsTmp = __vrlsTmp + 1
    end
    __vrlsWindows.__vrlsTmp = VRWindow( __vrlsHWnd )
    __vrlsWindows.0 = __vrlsTmp
    do while( VRIsValidObject( VRWindow() ) = 1 )
        __vrlsEvent = VREvent()
        interpret __vrlsEvent
    end
    __vrlsTmp = __vrlsWindows.0
    __vrlsWindows.0 = __vrlsTmp - 1
    call VRWindow __vrlsWindows.__vrlsTmp 
    __vrlsHWnd = ''
__vrlsDone:
return __vrlsHWnd

/*:VRX         ApplyProfile
*/
ApplyProfile:  PROCEDURE EXPOSE config. profiles.
    PARSE ARG prfname

    prfdir = config.!basepath'\'prfname

    setupcmd = config.!mptsbin'\SETUP.CMD'
    dhcpcfg  = config.!etc'\DHCPCD.CFG'
    resolv   = config.!etc'\RESOLV2'

    /* Copy the profile's configuration files. 
     */
    ADDRESS CMD '@copy' prfdir'\SETUP.CMD'  setupcmd '>NUL'
    IF rc \= 0 THEN RETURN rc
    ADDRESS CMD '@copy' prfdir'\DHCPCD.CFG' dhcpcfg  '>NUL'
    IF rc \= 0 THEN RETURN rc
    ADDRESS CMD '@copy' prfdir'\RESOLV2'    resolv   '>NUL'
    IF rc \= 0 THEN RETURN rc

    /* Flush the old configuration.
     */
    CALL FlushConfig

    /* Now initialize the new configuration.
     */

    ADDRESS CMD setupcmd '>nul 2>nul'
    retcode = rc

    IF retcode == 0 THEN
        CALL VRMessage VRWindow(), 'Profile' prfname 'has been applied.', 'Profile Changed', 'I'
    ELSE
        CALL VRMessage VRWindow(), 'Error code' retcode 'was returned.', 'Error', 'E'

RETURN

/*:VRX         CHK_COPYFROM_Click
*/
CHK_COPYFROM_Click: 
    set = VRGet('CHK_COPYFROM', 'Set')
    CALL VRSet 'CB_COPYFROM', 'Enabled', set
return

/*:VRX         CN_PROFILES_Click
*/
CN_PROFILES_Click: PROCEDURE EXPOSE config. profiles. rfName
    ok = VRMethod( "CN_PROFILES", "GetRecordList", "Selected", "selected." )
    IF selected.0 > 0 THEN DO
        value = VRMethod( "CN_PROFILES", "GetFieldData", selected.1, rfName )
        IF value == '[current]' THEN
            selectable = 0
        ELSE 
            selectable = 1
        CALL VRSet 'PB_DELETE',   'Enabled', selectable
        CALL VRSet 'PB_ACTIVATE', 'Enabled', selectable
    END
RETURN

/*:VRX         CN_PROFILES_EndEdit
*/
CN_PROFILES_EndEdit: PROCEDURE EXPOSE config. profiles. rfName rfDesc
    record = VRInfo('Record')
    fname  = VRInfo('FieldName')
    cancel = VRInfo('Cancelled')

    IF record == '' THEN RETURN
    IF cancel == 1  THEN RETURN
    IF fname <> 'DescField' THEN RETURN

    prfname = VRMethod('CN_PROFILES', 'GetFieldData', record, rfName )
    newdesc = VRMethod('CN_PROFILES', 'GetFieldData', record, rfDesc )
    olddesc = GetDescription( prfname )
    IF newdesc <> olddesc THEN DO
        CALL SetDescription prfname, newdesc
    END
RETURN

/*:VRX         EditProfile
*/
EditProfile: PROCEDURE EXPOSE config. profiles.
    PARSE ARG prfname

    prfdir  = config.!basepath'\'prfname
    prfcopy = ''

    setupcmd = config.!mptsbin'\SETUP.CMD'
    dhcpcfg  = config.!etc'\DHCPCD.CFG'
    resolv   = config.!etc'\RESOLV2'

    /* First, back up the existing configuration files */
    /* TODO: make sure these exist; if they don't, no need to abort on failure. */

    ADDRESS CMD '@copy' setupcmd config.!basepath '>NUL'
    IF rc \= 0 THEN RETURN rc
    ADDRESS CMD '@copy' dhcpcfg  config.!basepath '>NUL'
    IF rc \= 0 THEN RETURN rc
    ADDRESS CMD '@copy' resolv   config.!basepath '>NUL'
    IF rc \= 0 THEN RETURN rc

    /* Now copy the profile's files */
    ADDRESS CMD '@copy' prfdir'\SETUP.CMD'  setupcmd '>NUL'
    IF rc \= 0 THEN RETURN rc
    ADDRESS CMD '@copy' prfdir'\DHCPCD.CFG' dhcpcfg  '>NUL'
    IF rc \= 0 THEN RETURN rc
    ADDRESS CMD '@copy' prfdir'\RESOLV2'    resolv   '>NUL'
    IF rc \= 0 THEN RETURN rc

    /* Call the TCP/IP configuration program */
    rc = RunTcpConfig()
    IF rc \= 0 THEN
        CALL VRMessage 'WN_MAIN', ,
                       "The configuration program '"config.!tcpconfig"' could not be executed.",,
                       'Error', 'E'
    ELSE IF SaveProfile( prfname, prfcopy ) \= 0 THEN 
        CALL VRMessage 'WN_MAIN', 'Error saving profile.', 'Error', 'E'

    /* Now restore the backed-up configuration */
    ADDRESS CMD '@copy' config.!basepath'\SETUP.CMD'  setupcmd '>NUL'
    IF rc \= 0 THEN RETURN rc
    ADDRESS CMD '@copy' config.!basepath'\DHCPCD.CFG' dhcpcfg  '>NUL'
    IF rc \= 0 THEN RETURN rc
    ADDRESS CMD '@copy' config.!basepath'\RESOLV2'    resolv   '>NUL'
    IF rc \= 0 THEN RETURN rc

    ADDRESS CMD '@del' config.!basepath'\SETUP.CMD  >NUL'
    ADDRESS CMD '@del' config.!basepath'\DHCPCD.CFG >NUL'
    ADDRESS CMD '@del' config.!basepath'\RESOLV2    >NUL'

RETURN 0

/*:VRX         Fini
*/
Fini:
    window = VRWindow()
    call VRSet window, "Visible", 0
    drop window
return 0

/*:VRX         FlushConfig
*/
FlushConfig: PROCEDURE 

    'dhcpmon -t'
    'route -f >nul'
    DO i = 1 TO 7
        'ifconfig lan'i 'down   >nul 2>nul'
        'ifconfig lan'i 'delete >nul 2>nul'
    END
    'arp -f >nul'

RETURN

/*:VRX         GetDescription
*/
GetDescription: PROCEDURE EXPOSE config.
    PARSE ARG profiledir 

    /* Just so we can support both relative and FQ paths...
     */
    prfname = SUBSTR( profiledir, LASTPOS('\', profiledir ) + 1 )
    profiledir = config.!basepath'\'prfname

    IF SysGetEA( profiledir, '.SUBJECT', 'eadata') == 0 THEN
        PARSE VAR eadata 5 description
    ELSE
        description = ''

RETURN description

/*:VRX         GetProfiles
*/
GetProfiles: PROCEDURE EXPOSE profiles. config.

    /* Check the profiles directory.
     * If there are no profiles, prompt to copy the current configuration as
     * a profile.
     * Always show the current configuration as a pseudo-profile in any case.
     */
    profiles.0 = 0
    CALL SysFileTree config.!basepath'\*', 'profiles.', 'DO'
    IF profiles.0 == 0 THEN DO
        message = 'No TCP/IP profiles are currently defined.', 
                  '0d0a0d0a'x || 'An initial profile will be created using',
                  'your current TCP/IP configuration.'
        buttons.0 = 2
        buttons.1 = '~OK'
        buttons.2 = '~Cancel'
        btn = VRMessage('WN_MAIN', message, 'Create Initial Profile', 'I', 'buttons.', 1, 2 )
        IF btn \= 1 THEN RETURN
        prfname = 'Default'
        valid = 0
        DO UNTIL valid == 1
            btn = VRPrompt('WN_MAIN', 'Enter a name for this profile:',,
                        'prfname', 'Create Profile', 'buttons.', 1, 2 )
            IF btn \= 1 THEN RETURN

            IF prfname == '' THEN
                CALL VRMessage 'SW_ADD', 'You must enter a name.', 'Missing Name', 'E'
            ELSE IF VERIFY( prfname, '*?;,&<|>', 'M') > 0 THEN
                CALL VRMessage 'SW_ADD', 'The profile name cannot contain any of the following characters: * ? ; , & < > |', 'Invalid Name', 'E'
            ELSE valid = 1
        END
        IF SaveProfile( prfname ) \= 0 THEN DO
            CALL VRMessage 'WN_MAIN', 'Error creating profile.', 'Error', 'E'
            RETURN
        END
        CALL SetDescription prfname, 'Default profile'
        prfcount = profiles.0 + 1
        profiles.prfcount = prfname
        profiles.0 = prfcount
    END
    DO i = 1 TO profiles.0
        prfDesc.i  = GetDescription( profiles.i ) 
        profiles.i = SUBSTR( profiles.i, LASTPOS('\', profiles.i ) + 1 )
        prfRecs.i  = ';'profiles.i';Application;;Last;NameField;'profiles.i';IconField;#3;DescField;'prfDesc.i
    END
    prfRecs.0 = profiles.0
    CALL VRMethod 'CN_PROFILES', 'AddRecordList',,, 'prfRecs.'

RETURN

/*:VRX         GetTcpConfig
*/
GetTcpConfig: PROCEDURE EXPOSE config.

    IF SysSearchPath('PATH', 'TCPCFG2.CMD') \= '' THEN 
        config.!cfgtype = 1
    ELSE 
        config.!cfgtype = 2

/*
    tcpbase = FILESPEC('DRIVE', SysSearchPath('PATH', 'INETD.EXE')) || '\TCPIP'
    tcpjava = tcpbase'\JAVA'
    tcplang = VALUE('TCPLANG',,'OS2ENVIRONMENT')
    IF tcplang = '' THEN tcplang = VALUE('LANG',,'OS2ENVIRONMENT')
    classpath = tcpjava'\tcpauth.jar;'tcpjava'\jvc2.jar;'tcpjava'\ddnssgui.jar;'tcpjava'\tcpcfg2.jar;'tcpjava'\'tcplang'\cfg2res.jar;'tcpjava'\netdiver.jar;'tcpjava'\'tcplang'\tcpares.jar;'VALUE('CLASSPATH',,'OS2ENVIRONMENT')

    java = SysSearchPath('PATH', 'JAVA.EXE')
    IF java == '' THEN DO
        javadir = VALUE('JAVA_HOME',,'OS2ENVIRONMENT')
        IF javadir == '' THEN javadir = VALUE('GCD_JAVA_HOME',,'OS2ENVIRONMENT')
        java = STREAM( javadir'\bin\java.exe', 'C', 'QUERY EXISTS')
    END
*/
    IF config.!cfgtype = 2 THEN
        config.!tcpconfig = 'TCPCFG.EXE'
    ELSE 
        config.!tcpconfig = 'TCPCFG2.CMD'
/*
        config.!tcpconfig = java '-classpath' classpath 'COM.ibm.raleigh.tcp.tcpcfg2.client.Tcpcfg2c' tcplang 'local notrace'
*/
RETURN

/*:VRX         Halt
*/
Halt:
    signal _VREHalt
return

/*:VRX         Init
*/
Init:

    CALL RxFuncAdd 'SysLoadFuncs', 'REXXUTIL', 'SysLoadFuncs'
    CALL SysLoadFuncs

    CALL VRSet 'Console', 'WindowListTitle', ''

    workdir = DIRECTORY()
    config.!basepath = workdir'\PROFILES'
    config.!mptsbin = VRParseFileName( SysSearchPath('PATH', 'IFCONFIG.EXE'), 'DP')
    config.!etc = STRIP( VALUE('ETC',,'OS2ENVIRONMENT'), 'T', ';')

    CALL SysFileTree config.!basepath, 'profbase.', 'DO'
    IF profbase.0 < 1 THEN DO
        ok = SysMkDir( config.!basepath )
        IF ok \= 0 THEN DO
            CALL VRMessage 'WN_MAIN', 'Unable to create profile directory.', 'Error', 'E'
            CALL Quit
        END
    END

    /* Set up the container */
    rfIcon = VRMethod('CN_PROFILES', 'AddField', 'Icon',   '',            'IconField')
    rfName = VRMethod('CN_PROFILES', 'AddField', 'String', 'Profile',     'NameField')
    rfDesc = VRMethod('CN_PROFILES', 'AddField', 'String', 'Description', 'DescField')
    CALL VRMethod 'CN_PROFILES', 'SetFieldAttr', rfIcon, 'HorizSeparator', 0, 'ReadOnly', 1
    CALL VRMethod 'CN_PROFILES', 'SetFieldAttr', rfName, 'ReadOnly',       1
    CALL VRMethod 'CN_PROFILES', 'SetFieldAttr', rfDesc, 'VertSeparator',  0
    CALL VRSet 'CN_PROFILES', 'DetailSort', rfName

    rec = VRMethod('CN_PROFILES', 'AddRecord',,, '[current]', '#4')
    CALL VRMethod 'CN_PROFILES', 'SetFieldData', rec, rfName, '[current]', rfIcon, '#2',,
                                                 rfDesc, '-- The currently-active configuration --'
    CALL VRMethod 'CN_PROFILES', 'SetRecordAttr', rec, 'ReadOnly', 1

    CALL VRSet 'DT_STATUS', 'Caption', 'Select a TCP/IP profile to use.'

    CALL GetProfiles

    IF profiles.0 == 0 THEN 
        CALL Quit
    ELSE
        CALL LoadSettings

RETURN

/*:VRX         LoadSettings
*/
LoadSettings: PROCEDURE EXPOSE config.

    wleft   = VRGetIni('IPProfiles', 'X', 'User', 'NoClose')
    wtop    = VRGetIni('IPProfiles', 'Y', 'User', 'NoClose')

    PARSE VALUE VRGetIni('IPProfiles', 'ConfigProgram', 'User', 'NoClose') WITH tcpconfig '00'x .
    IF tcpconfig == '' THEN 
        CALL GetTcpConfig
    ELSE DO
        config.!cfgtype = 2
        config.!tcpconfig = tcpconfig
    END
    PARSE VALUE VRGetIni('IPProfiles', 'QuickEditor', 'User') WITH config.!quickedit '00'x .
    IF config.!quickedit == '' THEN
        config.!quickedit = 'E.EXE'

    window = VRWindow()
    IF ( wleft == '' | wtop == '' ) THEN 
        call VRMethod window, "CenterWindow"
    ELSE DO
        call VRSet window, "Left", wleft
        call VRSet window, "Top",  wtop
    END
    call VRSet window, "Visible", 1
    call VRMethod window, "Activate"
    drop window

RETURN

/*:VRX         PB_ABOUTOK_Click
*/
PB_ABOUTOK_Click: 
    CALL SW_ABOUT_Close
return

/*:VRX         PB_ACTIVATE_Click
*/
PB_ACTIVATE_Click: 
    IF ( VRMethod('CN_PROFILES', 'GetRecordList', 'Selected', 'selected.') \= 1 ) | ( selected.0 < 1 ) THEN 
        RETURN
    prfname = VRMethod('CN_PROFILES', 'GetFieldData', selected.1, rfName )
    DROP selected.

    IF prfname == '' THEN RETURN
    IF prfname == '[current]' THEN RETURN

    CALL ApplyProfile prfname

RETURN

/*:VRX         PB_ADD_Click
*/
PB_ADD_Click: PROCEDURE EXPOSE config. profiles. rfIcon rfName rfDesc

    prfname = ''
    prfdesc = ''
    CALL VRLoadSecondary 'SW_ADD', 'W'
    IF prfname == '' THEN RETURN

    IF SaveProfile( prfname ) \= 0 THEN 
        CALL VRMessage 'WN_MAIN', 'Error creating profile.', 'Error', 'E'
    ELSE DO 
        CALL SetDescription prfname, prfdesc
        ok = EditProfile( prfname )
        IF ok \= 0 THEN RETURN
        prfcount = profiles.0 + 1
        profiles.prfcount = prfname
        profiles.0 = prfcount
        new = VRMethod('CN_PROFILES', 'AddRecord',,, prfname, 'Application')
        CALL VRSet 'CN_PROFILES', 'Painting', 0
        CALL VRMethod 'CN_PROFILES', 'SetFieldData', new, rfName, prfname, rfIcon, '#3', rfDesc, prfdesc
        CALL VRMethod 'CN_PROFILES', 'SortRecords'
        CALL VRSet 'CN_PROFILES', 'Painting', 1
    END

RETURN

/*:VRX         PB_ADDCANCEL_Click
*/
PB_ADDCANCEL_Click: 
    CALL SW_ADD_Close
RETURN

/*:VRX         PB_ADDOK_Click
*/
PB_ADDOK_Click: 
    _name = VRGet('EF_ADDNAME', 'Value')
    IF _name == '' THEN DO
        CALL VRMessage 'SW_ADD', 'You must enter a name.', 'Missing Name', 'E'
        RETURN
    END
    IF VERIFY( _name, '*?;,&<|>', 'M') > 0 THEN DO
        CALL VRMessage 'SW_ADD', 'The profile name cannot contain any of the following characters: * ? ; , & < > |', 'Invalid Name', 'E'
        RETURN
    END
    prfname = _name
    prfdesc = VRGet('EF_ADDDESC', 'Value')

    IF VRGet('CHK_COPYFROM', 'Set') == 1 THEN 
        prfcopy = VRGet('CB_COPYFROM', 'Value')
    CALL SW_ADD_Close
RETURN

/*:VRX         PB_DELETE_Click
*/
PB_DELETE_Click: PROCEDURE EXPOSE config. profiles. rfName
    IF ( VRMethod('CN_PROFILES', 'GetRecordList', 'Selected', 'selected.') \= 1 ) | ( selected.0 < 1 ) THEN 
        RETURN
    prfname = VRMethod('CN_PROFILES', 'GetFieldData', selected.1, rfName )

    IF prfname == '' THEN RETURN
    prfdir = config.!basepath'\'prfname

    btns.1 = 'OK'
    btns.2 = 'Cancel'
    btns.0 = 2
    ok = VRMessage( VRWindow(), 'Delete profile' prfname'?  All files in the directory' prfdir 'will be deleted.', 'Confirm', 'Q', 'btns.', 1, 2 )
    IF ok <> 1 THEN RETURN

    ok = VRDeleteFile( prfdir'\*')
    IF ok == 1 THEN ok = VRRmDir( prfdir )
    IF ok <> 1 THEN 
        CALL VRMessage VRWindow(), VRError(), 'Error', 'E'
    ELSE DO
        DROP profiles.
        profiles.0 = 0
        CALL SysFileTree config.!basepath'\*', 'profiles.', 'DO'
        DO i = 1 TO profiles.0
            profiles.i = SUBSTR( profiles.i, LASTPOS('\', profiles.i ) + 1 )
        END
        ok = VRMethod('CN_PROFILES', 'RemoveRecord', selected.1 )
    END
RETURN

/*:VRX         PB_EDIT_Click
*/
PB_EDIT_Click: 
    IF ( VRMethod('CN_PROFILES', 'GetRecordList', 'Selected', 'selected.') \= 1 ) | ( selected.0 < 1 ) THEN 
        RETURN
    prfname = VRMethod('CN_PROFILES', 'GetFieldData', selected.1, rfName )
    prfdesc = VRMethod('CN_PROFILES', 'GetFieldData', selected.1, rfDesc )
    DROP selected.

    IF prfname == '' THEN RETURN
/*
    IF config.!cfgtype == 3 THEN DO
        CALL VRLoadSecondary 'SW_VIEW', 'W'
    END
 */
    ELSE DO
        IF prfname == '[current]' THEN DO
            rc = RunTcpConfig()
            IF rc \= 0 THEN
                CALL VRMessage 'WN_MAIN', ,
                               "The configuration program '"config.!tcpconfig"' could not be executed.",,
                               'Error', 'E'
        END
        ELSE CALL EditProfile prfname
    END

RETURN

/*:VRX         PB_OPTCANCEL_Click
*/
PB_OPTCANCEL_Click: 
    CALL SW_Options_Close
return

/*:VRX         PB_OPTIONS_Click
*/
PB_OPTIONS_Click: 
    CALL VRLoadSecondary 'SW_OPTIONS', 'W'
    IF ( config.!cfgtype == 2 ) & ( config.!tcpconfig == '') THEN DO
        config.!cfgtype = 1
        config.!tcpconfig = 'TCPCFG2.CMD'
    END
RETURN

/*:VRX         PB_OPTOK_Click
*/
PB_OPTOK_Click: 
    opts_changed = 1
    SELECT
        WHEN VRGet('RB_TCPCFG',   'Set') == 1 THEN DO
            config.!cfgtype = 2
            config.!tcpconfig = STRIP( VRGet('EF_TCPCFG', 'Value'))
        END
/*
        WHEN VRGet('RB_TEXTEDIT', 'Set') == 1 THEN 
            config.!cfgtype = 3
 */
        OTHERWISE DO
            config.!cfgtype = 1
            config.!tcpconfig = 'TCPCFG2.CMD'
        END

    END
    config.!quickedit = STRIP( VRGet('EF_TEXTEDIT', 'Value'))

    CALL SW_OPTIONS_Close
RETURN

/*:VRX         PB_QEDIT1_Click
*/
PB_QEDIT1_Click: 
    IF SYMBOL('setupcmd') <> 'VAR' THEN RETURN

    CALL VRSet 'PB_QEDIT1', 'Enabled', 0
    CALL VRSet VRWindow(),  'Enabled', 0
    CALL VRSet VRWindow(),  'Pointer', 'WAIT'
    ADDRESS CMD config.!quickedit setupcmd
    CALL VRSet VRWindow(),  'Pointer', '<default>'
    CALL VRSet VRWindow(),  'Enabled', 1
    CALL VRSet 'PB_QEDIT1', 'Enabled', 1

    CALL ShowFileContents 'MLE_VIEW1', setupcmd

RETURN

/*:VRX         PB_QEDIT2_Click
*/
PB_QEDIT2_Click: 
    IF SYMBOL('dhcpcfg') <> 'VAR' THEN RETURN

    CALL VRSet 'PB_QEDIT2', 'Enabled', 0
    CALL VRSet VRWindow(),  'Enabled', 0
    CALL VRSet VRWindow(),  'Pointer', 'WAIT'
    ADDRESS CMD config.!quickedit dhcpcfg
    CALL VRSet VRWindow(),  'Pointer', '<default>'
    CALL VRSet VRWindow(),  'Enabled', 1
    CALL VRSet 'PB_QEDIT2', 'Enabled', 1

    CALL ShowFileContents 'MLE_VIEW2', dhcpcfg

return

/*:VRX         PB_QEDIT3_Click
*/
PB_QEDIT3_Click: 
    IF SYMBOL('resolv') <> 'VAR' THEN RETURN

    CALL VRSet 'PB_QEDIT1', 'Enabled', 0
    CALL VRSet VRWindow(),  'Enabled', 0
    CALL VRSet VRWindow(),  'Pointer', 'WAIT'
    ADDRESS CMD config.!quickedit resolv
    CALL VRSet VRWindow(),  'Pointer', '<default>'
    CALL VRSet VRWindow(),  'Enabled', 1
    CALL VRSet 'PB_QEDIT1', 'Enabled', 1

    CALL ShowFileContents 'MLE_VIEW3', resolv

return

/*:VRX         PB_VIEW_Click
*/
PB_VIEW_Click: PROCEDURE EXPOSE config. profiles. rfName rfDesc

    IF ( VRMethod('CN_PROFILES', 'GetRecordList', 'Selected', 'selected.') \= 1 ) | ( selected.0 < 1 ) THEN 
        RETURN
    prfname = VRMethod('CN_PROFILES', 'GetFieldData', selected.1, rfName )
    prfdesc = VRMethod('CN_PROFILES', 'GetFieldData', selected.1, rfDesc )

    CALL VRLoadSecondary 'SW_VIEW', 'W'

RETURN

/*:VRX         Pict_1_Click
*/
Pict_1_Click: 
    CALL VRLoadSecondary 'SW_ABOUT', 'W'
return

/*:VRX         Quit
*/
Quit:
    CALL SaveSettings

    window = VRWindow()
    call VRSet window, "Shutdown", 1
    drop window
return

/*:VRX         RunTcpConfig
*/
RunTcpConfig: PROCEDURE EXPOSE config.

    CALL VRSet 'DT_STATUS', 'Caption', 'Launching the TCP/IP configuration program. Please wait...'
    CALL VRSet 'PB_OPTIONS',  'Enabled', 0
    CALL VRSet 'PB_ADD',      'Enabled', 0
    CALL VRSet 'PB_EDIT',     'Enabled', 0
    CALL VRSet 'PB_DELETE',   'Enabled', 0
    CALL VRSet 'PB_ACTIVATE', 'Enabled', 0
    CALL VRSet 'CN_PROFILES', 'Enabled', 0
    CALL VRSet 'WN_MAIN', 'Pointer', 'WAIT'
    ADDRESS CMD '@' config.!tcpconfig '2>&1 >NUL'
    retcode = rc
    CALL VRSet 'WN_MAIN', 'Pointer', '<default>'
    CALL VRSet 'PB_OPTIONS',  'Enabled', 1
    CALL VRSet 'PB_ADD',      'Enabled', 1
    CALL VRSet 'PB_EDIT',     'Enabled', 1
    CALL VRSet 'PB_DELETE',   'Enabled', 1
    CALL VRSet 'PB_ACTIVATE', 'Enabled', 1
    CALL VRSet 'CN_PROFILES', 'Enabled', 1
    CALL VRSet 'DT_STATUS', 'Caption', 'Select a TCP/IP profile to use.'

RETURN retcode

/*:VRX         SaveProfile
*/
SaveProfile: PROCEDURE EXPOSE config. profiles. 
    PARSE ARG prfname, prfcopy

    prfdir = config.!basepath'\'prfname
    CALL SysFileTree prfdir, 'found.', 'SO',, '**---'
    IF found.0 < 1 THEN DO
        ok = SysMkDir( prfdir )
        IF ok \= 0 THEN DO
            SAY 'SysMkDir('prfdir'):' ok
            RETURN ok
        END
    END

    IF prfcopy == '' THEN DO
        setupcmd = config.!mptsbin'\SETUP.CMD'
        dhcpcfg  = config.!etc'\DHCPCD.CFG'
        resolv   = config.!etc'\RESOLV2'
    END
    ELSE DO
        copydir  = config.!basepath'\'prfcopy
        setupcmd = copydir'\SETUP.CMD'
        dhcpcfg  = copydir'\DHCPCD.CFG'
        resolv   = copydir'\RESOLV2'
    END

    ADDRESS CMD '@copy' setupcmd prfdir '>NUL'
    IF rc \= 0 THEN RETURN rc
    ADDRESS CMD '@copy' dhcpcfg  prfdir '>NUL'
    IF rc \= 0 THEN RETURN rc
    ADDRESS CMD '@copy' resolv   prfdir '>NUL'
    IF rc \= 0 THEN RETURN rc

RETURN 0

/*:VRX         SaveSettings
*/
SaveSettings: PROCEDURE EXPOSE config.

    wleft = VRGet("WN_MAIN", "Left")
    wtop  = VRGet("WN_MAIN", "Top")
    CALL VRSetIni 'IPProfiles', 'X', wleft, 'User', 'NoClose'
    CALL VRSetIni 'IPProfiles', 'Y', wtop,  'User', 'NoClose'

    IF config.!cfgtype == 1 THEN
        CALL VRSetIni 'IPProfiles', 'ConfigProgram', '00'x, 'User', 'NoClose'
    ELSE
        CALL VRSetIni 'IPProfiles', 'ConfigProgram', config.!tcpconfig || '00'x, 'User', 'NoClose'

    CALL VRSetIni 'IPProfiles', 'QuickEditor', config.!quickedit || '00'x, 'User'

RETURN

/*:VRX         SetDescription
*/
SetDescription: PROCEDURE EXPOSE config.
    PARSE ARG profiledir, description
    prfdir = config.!basepath'\'profiledir
    IF VRFileExists( prfdir ) THEN DO
        lenbytes = X2C( D2X( LENGTH( description ), 4 ))
        eabytes  = X2C('FDFF') || REVERSE( lenbytes ) || description
        CALL SysPutEA prfdir, '.SUBJECT', eabytes
    END

RETURN

/*:VRX         ShowFileContents
*/
ShowFileContents: PROCEDURE
    PARSE ARG mle, file

    IF VRFileExists( file ) THEN DO
        _text = ''
        CALL CHARIN setupcmd, 1, 0
        DO WHILE CHARS( file ) > 0
            _c = CHARIN( file )
            _text = _text || _c
        END
        CALL STREAM file, 'C', 'CLOSE'
        CALL VRSet mle, 'Value', _text
    END

RETURN

/*:VRX         SW_ABOUT_Close
*/
SW_ABOUT_Close: 
    call SW_ABOUT_Fini
return

/*:VRX         SW_ABOUT_Create
*/
SW_ABOUT_Create: 
    call SW_ABOUT_Init
return

/*:VRX         SW_ABOUT_Fini
*/
SW_ABOUT_Fini: 
    window = VRInfo( "Window" )
    call VRDestroy window
    drop window
return
/*:VRX         SW_ABOUT_Init
*/
SW_ABOUT_Init: 
    window = VRInfo( "Object" )
    if( \VRIsChildOf( window, "Notebook" ) ) then do
        call VRMethod window, "CenterWindow"
        call VRSet window, "Visible", 1
        call VRMethod window, "Activate"
    end
    drop window
return

/*:VRX         SW_ADD_Close
*/
SW_ADD_Close: 
    call SW_ADD_Fini
return

/*:VRX         SW_ADD_Create
*/
SW_ADD_Create: 
    call SW_ADD_Init
return

/*:VRX         SW_ADD_Fini
*/
SW_ADD_Fini: 
    window = VRInfo( "Window" )
    call VRDestroy window
    drop window
return
/*:VRX         SW_ADD_Init
*/
SW_ADD_Init: 

    CALL VRMethod 'CB_COPYFROM', 'AddStringList', 'profiles.'
    CALL VRSet 'CB_COPYFROM', 'Selected', 1  

    window = VRInfo( "Object" )
    if( \VRIsChildOf( window, "Notebook" ) ) then do
        call VRMethod window, "CenterWindow"
        call VRSet window, "Visible", 1
        call VRMethod window, "Activate"
    end
    drop window
return

/*:VRX         SW_OPTIONS_Close
*/
SW_OPTIONS_Close: 
    call SW_OPTIONS_Fini
return

/*:VRX         SW_OPTIONS_Create
*/
SW_OPTIONS_Create: 
    call SW_OPTIONS_Init
return

/*:VRX         SW_OPTIONS_Fini
*/
SW_OPTIONS_Fini: 
    window = VRInfo( "Window" )
    call VRDestroy window
    drop window
return
/*:VRX         SW_OPTIONS_Init
*/
SW_OPTIONS_Init: 

    opts_changed = 0

    SELECT
        WHEN config.!cfgtype = 1 THEN 
            CALL VRSet 'RB_TCPCFG2',  'Set', 1
        WHEN config.!cfgtype = 2 THEN DO
            CALL VRSet 'RB_TCPCFG', 'Set', 1
            CALL VRSet 'EF_TCPCFG', 'Value', config.!tcpconfig
        END
        OTHERWISE
            CALL VRSet 'RB_TEXTEDIT', 'Set', 1
    END

    CALL VRSet 'EF_TEXTEDIT', 'Value', config.!quickedit

    window = VRInfo( "Object" )
    if( \VRIsChildOf( window, "Notebook" ) ) then do
        call VRMethod window, "CenterWindow"
        call VRSet window, "Visible", 1
        call VRMethod window, "Activate"
    end
    drop window

RETURN

/*:VRX         SW_VIEW1_Close
*/
SW_VIEW1_Close: 
    call SW_VIEW1_Fini
return

/*:VRX         SW_VIEW1_Create
*/
SW_VIEW1_Create: 
    call SW_VIEW1_Init
return

/*:VRX         SW_VIEW1_Fini
*/
SW_VIEW1_Fini: 
    window = VRInfo( "Window" )
    call VRDestroy window
    drop window
return
/*:VRX         SW_VIEW1_Init
*/
SW_VIEW1_Init: PROCEDURE EXPOSE config. setupcmd

    CALL ShowFileContents 'MLE_VIEW1', setupcmd
    IF config.!quickedit == '' THEN CALL VRSet 'PB_QEDIT1', 'Enabled', 0

    window = VRInfo( "Object" )
    drop window

RETURN

/*:VRX         SW_VIEW2_Close
*/
SW_VIEW2_Close: 
    call SW_VIEW2_Fini
return

/*:VRX         SW_VIEW2_Create
*/
SW_VIEW2_Create: 
    call SW_VIEW2_Init
return

/*:VRX         SW_VIEW2_Fini
*/
SW_VIEW2_Fini: 
    window = VRInfo( "Window" )
    call VRDestroy window
    drop window
return
/*:VRX         SW_VIEW2_Init
*/
SW_VIEW2_Init: 

    CALL ShowFileContents 'MLE_VIEW2', dhcpcfg
    IF config.!quickedit == '' THEN CALL VRSet 'PB_QEDIT2', 'Enabled', 0

    window = VRInfo( "Object" )
    drop window
return

/*:VRX         SW_VIEW3_Close
*/
SW_VIEW3_Close: 
    call SW_VIEW3_Fini
return

/*:VRX         SW_VIEW3_Create
*/
SW_VIEW3_Create: 
    call SW_VIEW3_Init
return

/*:VRX         SW_VIEW3_Fini
*/
SW_VIEW3_Fini: 
    window = VRInfo( "Window" )
    call VRDestroy window
    drop window
return
/*:VRX         SW_VIEW3_Init
*/
SW_VIEW3_Init: 

    CALL ShowFileContents 'MLE_VIEW3', resolv
    IF config.!quickedit == '' THEN CALL VRSet 'PB_QEDIT3', 'Enabled', 0

    window = VRInfo( "Object" )
    drop window
return

/*:VRX         SW_VIEW_Close
*/
SW_VIEW_Close: 
    call SW_VIEW_Fini
return

/*:VRX         SW_VIEW_Create
*/
SW_VIEW_Create: 
    call SW_VIEW_Init
return

/*:VRX         SW_VIEW_Fini
*/
SW_VIEW_Fini: 
    window = VRInfo( "Window" )
    call VRDestroy window
    drop window
return
/*:VRX         SW_VIEW_Init
*/
SW_VIEW_Init: 

    IF prfname == '[current]' THEN DO
        prfdir   = ''
        setupcmd = config.!mptsbin'\SETUP.CMD'
        dhcpcfg  = config.!etc'\DHCPCD.CFG'
        resolv   = config.!etc'\RESOLV2'
        CALL VRSet 'SW_VIEW', 'Caption', 'Current Configuration'
    END
    ELSE DO
        prfdir   = config.!basepath'\'prfname
        setupcmd = prfdir'\SETUP.CMD'
        dhcpcfg  = prfdir'\DHCPCD.CFG'
        resolv   = prfdir'\RESOLV2'
        CALL VRSet 'SW_VIEW', 'Caption', prfdesc
    END

    CALL VRMethod 'NB_VIEWER', 'SetStatusText', 1, 'SETUP.CMD - TCP/IP Interface Settings'
    CALL VRMethod 'NB_VIEWER', 'SetStatusText', 2, 'RESOLV2 - Name Resolution Settings'
    CALL VRMethod 'NB_VIEWER', 'SetStatusText', 3, 'DHCPCD.CFG - DHCP Configuration'

    window = VRInfo( "Object" )
    if( \VRIsChildOf( window, "Notebook" ) ) then do
        call VRMethod window, "CenterWindow", "Desktop"
        call VRSet window, "Visible", 1
        call VRMethod window, "Activate"
    end
    drop window
return

/*:VRX         WN_MAIN_Close
*/
WN_MAIN_Close:
    call Quit
return

