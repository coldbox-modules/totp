component {

    this.name = "TOTP Tests";
    this.sessionManagement  = true;
    this.setClientCookies   = true;
    this.sessionTimeout     = createTimeSpan( 0, 0, 15, 0 );
    this.applicationTimeout = createTimeSpan( 0, 0, 15, 0 );

    testsPath = getDirectoryFromPath( getCurrentTemplatePath() );
    this.mappings[ "/tests" ] = testsPath;
    rootPath = REReplaceNoCase( this.mappings[ "/tests" ], "tests(\\|/)", "" );
    this.mappings[ "/root" ] = rootPath;
    this.mappings[ "/totp" ] = rootPath;
    this.mappings[ "/CFzxing" ] = rootPath & "/modules/CFzxing";
    this.mappings[ "/testingModuleRoot" ] = listDeleteAt( rootPath, listLen( rootPath, '\/' ), "\/" );
    this.mappings[ "/testbox" ] = rootPath & "/testbox";

    this.javaSettings = {
        loadPaths: directoryList(
            this.mappings[ "/CFzxing" ] & "/lib",
            true,
            "array",
            "*jar"
        ),
        loadColdFusionClassPath: true,
        reloadOnChange: false
    };

}