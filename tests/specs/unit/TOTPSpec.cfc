component extends="testbox.system.BaseSpec" {

    function beforeAll() {
        variables.totp = new totp.models.TOTP();
    }

    function run() {
        describe( "TOTP", function() {
            describe( "generateCode", function() {
                getGenerateCodeTestCases().each( function( t ) {
                    it(
                        title = "correctly generates a code for secret code [#t.secret#] and time [#t.time#] and algorithm [#t.algorithm#] and digits [#t.digits#]",
                        data = t,
                        body = function( data ) {
                            var code = variables.totp.generateCode(
                                data.secret,
                                data.digits,
                                data.algorithm,
                                data.time
                            );
                            expect( code ).toBe( data.expectedCode );
                        }
                    );
                } );
            } );

            describe( "verifyCode", function() {
                it( "verifies a code is valid when the code is for the correct time period", function() {
                    var secret = "EX47GINFPBK5GNLYLILGD2H6ZLGJNNWB";
                    var timeToRunAt = 1567975936;
                    var correctCode = "862707";
                    var timePeriod = 30;

                    expect(
                        variables.totp.verifyCode(
                            secret,
                            correctCode,
                            "SHA1",
                            timeToRunAt,
                            timePeriod
                        )
                    ).toBeTrue();
                } );

                it( "verifies a code is valid if it is within the configured discrepancy period", function() {
                    var secret = "EX47GINFPBK5GNLYLILGD2H6ZLGJNNWB";
                    var timeToRunAt = 1567975936;
                    var correctCode = "862707";
                    var timePeriod = 30;

                    // allow for a -/+ ~30 second discrepancy
                    expect(
                        variables.totp.verifyCode(
                            secret,
                            correctCode,
                            "SHA1",
                            timeToRunAt - timePeriod,
                            timePeriod
                        )
                    ).toBeTrue();
                    expect(
                        variables.totp.verifyCode(
                            secret,
                            correctCode,
                            "SHA1",
                            timeToRunAt + timePeriod,
                            timePeriod
                        )
                    ).toBeTrue();
                } );

                it( "fails to verify a code if it is outside the discrepancy window", function() {
                    var secret = "EX47GINFPBK5GNLYLILGD2H6ZLGJNNWB";
                    var timeToRunAt = 1567975936;
                    var correctCode = "862707";
                    var timePeriod = 30;

                    expect(
                        variables.totp.verifyCode(
                            secret,
                            correctCode,
                            "SHA1",
                            timeToRunAt + timePeriod + 15,
                            timePeriod
                        )
                    ).toBeFalse();
                } );

                it( "fails to verify incorrect codes", function() {
                    var secret = "EX47GINFPBK5GNLYLILGD2H6ZLGJNNWB";
                    var timeToRunAt = 1567975936;
                    var correctCode = "862707";
                    var timePeriod = 30;

                    expect(
                        variables.totp.verifyCode(
                            secret,
                            "123",
                            "SHA1",
                            timeToRunAt,
                            timePeriod
                        )
                    ).toBeFalse();
                } );
            } );

            describe( "generateSecret", function() {
                it( "can generate a secret", function() {
                    expect( variables.totp.generateSecret() ).toHaveLength( 32 );
                } );

                it( "can generate custom length secrets", function() {
                    expect( variables.totp.generateSecret( 16 ) ).toHaveLength( 16 );
                    expect( variables.totp.generateSecret( 128 ) ).toHaveLength( 128 );
                } );

                it( "is a valid Base32 string", function() {
                    expect( variables.totp.generateSecret() ).toMatchWithCase(
                        "^[A-Z2-7]+=*$",
                        "Secret must be a valid Base32 string."
                    );
                } );
            } );

            it( "can use a generated secret to generate and verify a code", function() {
                var secret = variables.totp.generateSecret();
                var code = variables.totp.generateCode( secret );
                expect( variables.totp.verifyCode( secret, code ) ).toBeTrue();
            } );
        } );
    }

    private array function getGenerateCodeTestCases() {
        return [
            {
                "secret": "W3C5B3WKR4AUKFVWYU2WNMYB756OAKWY",
                "time": 1567631536,
                "algorithm": "SHA1",
                "digits": 6,
                "expectedCode": "082371"
            },
            {
                "secret": "W3C5B3WKR4AUKFVWYU2WNMYB756OAKWY",
                "time": 1567631536,
                "algorithm": "SHA1",
                "digits": 8,
                "expectedCode": "11082371"
            },
            {
                "secret": "W3C5B3WKR4AUKFVWYU2WNMYB756OAKWY",
                "time": 1567631536,
                "algorithm": "SHA1",
                "digits": 4,
                "expectedCode": "2371"
            },
            {
                "secret": "W3C5B3WKR4AUKFVWYU2WNMYB756OAKWY",
                "time": 1567631536,
                "algorithm": "SHA256",
                "digits": 6,
                "expectedCode": "272978"
            },
            {
                "secret": "W3C5B3WKR4AUKFVWYU2WNMYB756OAKWY",
                "time": 1567631536,
                "algorithm": "SHA512",
                "digits": 6,
                "expectedCode": "325200"
            },
            {
                "secret": "makrzl2hict4ojeji2iah4kndmq6sgka",
                "time": 1582750403,
                "algorithm": "SHA1",
                "digits": 6,
                "expectedCode": "848586"
            },
            {
                "secret": "makrzl2hict4ojeji2iah4kndmq6sgka",
                "time": 1582750403,
                "algorithm": "SHA256",
                "digits": 6,
                "expectedCode": "965726"
            },
            {
                "secret": "makrzl2hict4ojeji2iah4kndmq6sgka",
                "time": 1582750403,
                "algorithm": "SHA512",
                "digits": 6,
                "expectedCode": "741306"
            }
        ];
    }

}
