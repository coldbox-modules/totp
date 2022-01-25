component singleton {

    public TOTP function init() {
        variables.secureRandom = createObject( "java", "java.security.SecureRandom" ).init();
        variables.instant = createObject( "java", "java.time.Instant" );
        variables.base32 = new Base32();
        return this;
    }

    /**
     * Generates a Base32 string to use as a secret key when generating and verifying TOTPs.
     * This key should be stored securely and associated to the user who created it.
     * It is also recommended that you have the user verify a code using the secret before saving the secret.
     *
     * @length  The length of the secret key.
     *          Default: 32
     *
     * @returns A new secret key.
     */
    public string function generateSecret( numeric length = 32 ) {
        var initialBytes = [];
        for ( var i = 1; i <= ceiling( ( arguments.length * 5 ) / 8 ); i++ ) {
            initialBytes.append( 0 );
        }
        var bytes = javacast( "byte[]", initialBytes );
        variables.secureRandom.nextBytes( bytes );
        return variables.base32.encode( bytes );
    }

    /**
     * Generates a TOTP for a given secret.
     *
     * @secret     The Base32 string to use when generating the code.
     * @digits     The number of digits of the code to return.
     * @algorithm  The algorithm to use when generating the code.
     *             Valid algorithms are:
     *               - MD5
     *               - SHA1
     *               - SHA256
     *               - SHA384
     *               - SHA512
     *             Default: SHA1
     * @time       The current time (expressed as seconds since January 1, 1970).
     *             Default: now
     * @timePeriod The time period the code is valid, in seconds.
     *             Default: 30.
     *
     * @returns    A TOTP
     */
    public string function generateCode(
        required string secret,
        numeric digits = 6,
        string algorithm = "SHA1",
        numeric time = variables.instant.now().getEpochSecond(),
        numeric timePeriod = 30
    ) {
        var counter = floor( arguments.time / arguments.timePeriod );
        var hash = generateHash( arguments.secret, counter, arguments.algorithm );
        return getDigitsFromHash( hash, arguments.digits );
    }

    /**
     * Verifies a given TOTP for a given secret.
     *
     * @secret                       The Base32 string to use when verifying the code.
     *                               (This needs to be the same secret used to generate the code.)
     * @code                         The code to verify.
     * @algorithm                    The algorithm to use when verifying the code.
     *                               (This needs to be the same algorithm used to generate the code.)
     *                               Valid algorithms are:
     *                                 - MD5
     *                                 - SHA1
     *                                 - SHA256
     *                                 - SHA384
     *                                 - SHA512
     *                               Default: SHA1
     * @time                         The current time (expressed as seconds since January 1, 1970).
     *                               Default: now
     * @timePeriod                   The time period the code is valid, in seconds.
     *                               Default: 30.
     * @allowedTimePeriodDiscrepancy The number of periods, before and after, a code is considered valid.
     *                               By default, a code is valid for 30 seconds before to 30 seconds after its valid period for a total of 90 seconds.
     *                               Default: 1
     *
     * @returns                      True, if the code is valid. False, otherwise.
     */
    public boolean function verifyCode(
        required string secret,
        required string code,
        string algorithm = "SHA1",
        numeric time = variables.instant.now().getEpochSecond(),
        numeric timePeriod = 30,
        numeric allowedTimePeriodDiscrepancy = 1
    ) {
        var currentBucket = floor( arguments.time / arguments.timePeriod );

        // Calculate and compare the codes for all the "valid" time periods, even if we get an early match, to avoid timing attacks
        var success = false;
        for ( var i = -1 * arguments.allowedTimePeriodDiscrepancy; i <= allowedTimePeriodDiscrepancy; i++ ) {
            success = checkCode(
                arguments.secret,
                arguments.code,
                currentBucket + i,
                arguments.algorithm
            ) || success;
        }
        return success;
    }

    private boolean function checkCode(
        required string secret,
        required string code,
        required numeric counter,
        string algorithm = "SHA1"
    ) {
        var hash = generateHash( arguments.secret, arguments.counter, arguments.algorithm );
        return getDigitsFromHash( hash, arguments.code.len() ) == arguments.code;
    }

    private string function generateHash( required string secret, required numeric counter, string algorithm = "SHA1" ) {
        var time = leftPad( decimalToHex( arguments.counter ), 16, "0" );
        return hmac(
            binaryDecode( time, "hex" ),
            variables.base32.decode( arguments.secret ),
            "HMAC#arguments.algorithm#"
        );
    }

    private string function getDigitsFromHash( required string hash, numeric digits = 6 ) {
        var offset = hexToDecimal( right( arguments.hash, 1 ) );
        var otp = toString(
            _bitAnd( hexToDecimal( mid( arguments.hash, ( offset * 2 ) + 1, 8 ) ), hexToDecimal( "7fffffff" ) )
        );
        var truncatedDigits = mid( otp, max( otp.len() - arguments.digits + 1, 1 ), arguments.digits );
        return truncatedDigits;
    }

    private numeric function hexToDecimal( required string hex ) {
        return inputBaseN( arguments.hex, 16 );
    }

    private numeric function binaryToDecimal( required string bin ) {
        return inputBaseN( arguments.bin, 2 );
    }

    private string function decimalToHex( required numeric dec ) {
        return formatBaseN( arguments.dec, 16 );
    }

    private string function decimalToBinary( required numeric dec ) {
        return formatBaseN( arguments.dec, 2 );
    }

    private string function leftPad( required string str, required numeric len, required string pad ) {
        if ( arguments.str.len() >= arguments.len ) {
            return arguments.str;
        }
        return repeatString( arguments.pad, arguments.len - arguments.str.len() ) & arguments.str;
    }

    /**
     * We have our own bitAnd function because ACF and Lucee only support 32-bit signed integers.
     *
     * @one The first decimal number.
     * @two The second decimal number.
     *
     * @returns The decimal representation of the two numbers after a bitwise and operation.
     */
    private string function _bitAnd( required numeric one, required numeric two ) {
        var oneBigInt = createObject( "java", "java.math.BigInteger" ).init( arguments.one );
        var twoBigInt = createObject( "java", "java.math.BigInteger" ).init( arguments.two );
        var andBigInt = oneBigInt.and( twoBigInt );
        return andBigInt.intValue();
    }

}
