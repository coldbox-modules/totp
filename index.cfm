<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <script src="https://cdn.tailwindcss.com?plugins=forms"></script>
    <title>TOTP Tester</title>
</head>
<body class="flex flex-col justify-center items-center">
<cfoutput>
    <cfscript>
        param url.email = "john@example.com";
        param url.issuer = "Example Company";

        variables.totp = new models.TOTP();
        variables.barcodeService = new modules.CFzxing.models.Barcode();
        variables.barcodeService.setJavaloader( { "create": function( path ) {
            return createObject( "java", path );
        } } );
        variables.totp.setBarcodeService( variables.barcodeService );

        if ( form.keyExists( "regenerateSecret" ) ) {
            structDelete( application, "totpConfig" );
        }
        param application.totpConfig = variables.totp.generate( url.email, url.issuer, 32, 512, 512 );

        param form.token = "";
        param form.valid = true;
        if ( form.keyExists( "validateToken" ) ) {
            form.valid = variables.totp.verifyCode( application.totpConfig.secret, form.token );
        }
    </cfscript>

    <h1 class="text-7xl font-bold">TOTP Example</h1>

    <figure class="flex flex-col mb-4">
        <img class="mx-auto w-64 h-64" src="data:image/png;base64,#toBase64(imageGetBufferedImage(application.totpConfig.qrCode))#" alt="#application.totpConfig.url#" />
        <figcaption class="text-gray-400 text-sm">#application.totpConfig.url#</figcaption>
    </figure>

    <form method="POST" class="mb-8">
        <button type="submit" name="regenerateSecret" class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
            Regenerate Secret
        </button>
    </form>

    <hr />

    <form method="POST" class="flex">
        <div>
            <div class="mt-1 flex rounded-md shadow-sm">
                <div class="relative flex items-stretch flex-grow focus-within:z-10">
                    <input
                        aria-label="token"
                        type="text"
                        name="token"
                        id="token"
                        value="#form.token#"
                        inputmode="numeric"
                        autocomplete="one-time-code"
                        pattern="\d{6}"
                        placeholder="Token"
                        class="focus:ring-indigo-500 focus:border-indigo-500 block w-full rounded-none rounded-l-md sm:text-sm border-gray-300"
                        <cfif NOT form.valid>
                        aria-invalid="true"
                        aria-describedby="token-error"
                        <cfelse>
                        aria-describedby="token-success"
                        </cfif>
                    >
                </div>
                <button type="submit" name="validateToken" class="-ml-px relative inline-flex items-center space-x-2 px-4 py-2 border border-gray-300 text-sm font-medium rounded-r-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500">
                    <span>Validate</span>
                </button>
            </div>
            <cfif NOT form.valid>
                <p class="mt-2 text-center text-md text-red-600" id="token-error">Your token is invalid.</p>
            <cfelse>
                <p class="mt-2 text-center text-md text-green-600" id="token-success">Your token is valid!</p>
            </cfif>
        </div>
    </form>
</cfoutput>
</body>
</html>