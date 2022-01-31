component {

    this.name = "TOTP Example";
    this.sessionManagement  = true;
    this.setClientCookies   = true;
    this.sessionTimeout     = createTimeSpan( 0, 0, 15, 0 );
    this.applicationTimeout = createTimeSpan( 0, 0, 15, 0 );

    rootPath = getDirectoryFromPath( getCurrentTemplatePath() );
    this.mappings[ "/root" ] = rootPath;
    this.mappings[ "/totp" ] = rootPath;
    this.mappings[ "/CFzxing" ] = rootPath & "/modules/CFzxing";

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