component {

    this.name = "totp";
    this.author = "Eric Peterson <eric@elpete.com>";
    this.webUrl = "https://github.com/coldbox-modules/totp";
    this.cfmapping = "totp";
    this.autoMapModels = false;

    function configure() {
        binder.map( "TOTP@totp" ).to( "#moduleMapping#.models.TOTP" );
        binder.map( "@totp" ).to( "#moduleMapping#.models.TOTP" );
    }

}
