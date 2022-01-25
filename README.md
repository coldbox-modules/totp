<h1 style="text-align: center;">totp</h1>
<p style="text-align: center;">
    <a href="https://forgebox.io/view/totp"><img src="https://cfmlbadges.monkehworks.com/images/badges/available-on-forgebox.svg" alt="Available on ForgeBox" /></a>
    <img src="https://cfmlbadges.monkehworks.com/images/badges/tested-with-testbox.svg" alt="Tested With TestBox" />
</p>
<p style="text-align: center;">
    <img height="30" src="https://cfmlbadges.monkehworks.com/images/badges/compatibility-coldfusion-2016.svg" alt="Compatible with ColdFusion 2016" />
    <img height="30" src="https://cfmlbadges.monkehworks.com/images/badges/compatibility-coldfusion-2018.svg" alt="Compatible with ColdFusion 2018" />
    <img height="30" src="https://cfmlbadges.monkehworks.com/images/badges/compatibility-lucee-5.svg" alt="Compatible with Lucee 5" />
</p>

## A CFML Implementation of Time-based One-time Passwords

### Inspiration

- [Java TOTP](https://github.com/samdjstevens/java-totp)
- [totp-generator](https://github.com/bellstrand/totp-generator)
- [Base32](https://github.com/bennadel/Base32.cfc)

### Usage

Obtain a new instance of TOTP using WireBox or simplying by creating a new instance (`new TOTP()`).

> WireBox/ColdBox is **NOT** required to use this module.

#### `generateSecret`

Generates a Base32 string to use as a secret key when generating and verifying TOTPs.
This key should be stored securely and associated to the user who created it.
It is also recommended that you have the user verify a code using the secret before saving the secret.

| Name   | Type    | Required | Default | Description                   |
| ------ | ------- | -------- | ------- | ----------------------------- |
| length | numeric | false    | 32      | The length of the secret key. |

#### `generateCode`

Generates a Time-based One-time Password (TOTP) for a given secret.

| Name       | Type    | Required | Default | Description                                                                                             |
| ---------- | ------- | -------- | ------- | ------------------------------------------------------------------------------------------------------- |
| secret     | string  | true     |         | The Base32 string to use when generating the code.                                                      |
| digits     | numeric | false    | 6       | The number of digits of the code to return.                                                             |
| algorithm  | string  | false    | "SHA1"  | The algorithm to use when generating the code. Valid algorithms are: MD5, SHA1, SHA256, SHA384, SHA512. |
| time       | numeric | false    | now     | The current time (expressed as seconds since January 1, 1970).                                          |
| timePeriod | numeric | false    | 30      | The time period the code is valid, in seconds.                                                          |

#### `verifyCode`

Verifies a given TOTP for a given secret.

| Name                         | Type    | Required | Default | Description                                                                                                                                                                            |
| ---------------------------- | ------- | -------- | ------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| secret                       | string  | true     |         | The Base32 string to use when verifying the code. (This needs to be the same secret used to generate the code.)                                                                        |
| code                         | string  | true     |         | The code to verify.                                                                                                                                                                    |
| algorithm                    | string  | false    | "SHA1"  | The algorithm to use when verifying the code. (This needs to be the same algorithm used to generate the code.) Valid algorithms are: MD5, SHA1, SHA256, SHA384, SHA512.                |
| time                         | numeric | false    | now     | The current time (expressed as seconds since January 1, 1970).                                                                                                                         |
| timePeriod                   | numeric | false    | 30      | The time period the code is valid, in seconds.                                                                                                                                         |
| allowedTimePeriodDiscrepancy | numeric | false    | 1       | The number of periods, before and after, a code is considered valid. By default, a code is valid for 30 seconds before to 30 seconds after its valid period for a total of 90 seconds. |
