/**
 * @author Ben Nadel
 * @source https://github.com/bennadel/Base32.cfc
 * Slight modifications made to `encode` and `decode` to make them a bit more managable
 */
component output=false hint="I provide encoding and decoding methods for Base32 values." singleton {

    /**
     * I server no purpose since the methods on this component are "static".
     *
     * @output false
     */
    public any function init() {
        return ( this );
    }


    // ---
    // STATIC METHODS.
    // ---


    /**
     * I decode the given Base32-encoded string value.
     *
     * @output false
     * @hint The input string is assumed to be utf-8.
     */
    public any function decode( required string input, boolean toString = false, string encoding = "utf-8" ) {
        var binaryOutput = decodeBinary( charsetDecode( uCase( arguments.input ), arguments.encoding ) );
        return arguments.toString ? charsetEncode( binaryOutput, arguments.encoding ) : binaryOutput;
    }


    /**
     * I decode the given Base32-encoded binary value.
     *
     * @output false
     */
    public binary function decodeBinary( required binary input ) {
        // I map the encoded bytes onto the original 5-bit partial input bytes.
        var decodingMap = getDecodingMap();

        // I hold the intermediary, decoded bytes.
        var buffer = getAllocatedDecodingBuffer( input );

        // The input maybe be padded with "=" to make sure that the value is evenly
        // divisible by 8 (to make the length of data more predictable). Once we hit
        // this byte (if it exists), we have consumed all of the encoded data.
        var terminatingByte = asc( "=" );

        // I help zero-out the parts of the byte that were not discarded.
        var rightMostBits = [
            inputBaseN( "1", 2 ),
            inputBaseN( "11", 2 ),
            inputBaseN( "111", 2 ),
            inputBaseN( "1111", 2 )
        ];

        // As we loop over the encoded bytes, we may have to build up each decoded byte
        // across multiple input bytes. This will help us keep track of how many more
        // bits we need to complete the pending byte.
        var decodedByte = 0;
        var bitsNeeded = 8;

        // Decode each input byte.
        for ( var byte in input ) {
            // If we hit the EOF byte, there's nothing more to process.
            if ( byte == terminatingByte ) {
                break;
            }

            // Get the original 5-bit input that was encoded.
            var partialByte = decodingMap[ byte ];

            // If we need more than 5 bits, we can consume the given value in it's
            // entirety without actually filling the pending bit.
            if ( bitsNeeded > 5 ) {
                // Push the incoming 5-bits onto the end of the pending byte.
                decodedByte = bitOr( bitShln( decodedByte, 5 ), partialByte );

                bitsNeeded -= 5;

                // If we need exactly 5 more bits, we can use the given value to complete
                // the pending bit.
            } else if ( bitsNeeded == 5 ) {
                // Push the incoming 5-bits onto the end of the pending byte.
                decodedByte = bitOr( bitShln( decodedByte, 5 ), partialByte );

                // At this point, the pending byte is complete.
                buffer.put( toSignedByte( decodedByte ) );

                decodedByte = 0;
                bitsNeeded = 8;

                // If we need between 1 and 4 bits, we have to consume the given value
                // across, two different pending bytes since it won't fit entirely into the
                // currently-pending byte (the leading bits complete the currently-pending
                // byte, then the trailing bits start the next pending byte).
            } else {
                var discardedCount = ( 5 - bitsNeeded );

                // Push only the leading bits onto the end of the pending byte.
                decodedByte = bitOr( bitShln( decodedByte, bitsNeeded ), bitShrn( partialByte, discardedCount ) );

                // At this point, the pending byte is complete.
                buffer.put( toSignedByte( decodedByte ) );

                // Start the next pending byte with the trailing bits that we discarded
                // in the last operation.
                decodedByte = bitAnd( partialByte, rightMostBits[ discardedCount ] );

                bitsNeeded = ( 8 - discardedCount );
            }

            // NOTE: We will never need an ELSE case that requiers zero bits to complete
            // the pending byte. Since each case that can result in a completed byte
            // (need 5 bits (1) or less than 5 bits (2)) already push a byte on to the
            // result, we will never complete a byte without pushing it onto the output.
        }

        // Return the result as a binary value.
        return ( buffer.array() );
    }


    /**
     * I encode the given string value using Base32 encoding.
     *
     * @output false
     * @hint The input string is assumed to be utf-8.
     */
    public any function encode( required any input, boolean toString = true, string encoding = "utf-8" ) {
        if ( !isBinary( arguments.input ) ) {
            arguments.input = charsetDecode( uCase( arguments.input ), arguments.encoding );
        }
        var binaryOutput = encodeBinary( arguments.input );
        return arguments.toString ? charsetEncode( binaryOutput, arguments.encoding ) : binaryOutput;
    }


    /**
     * I encode the given binary value using Base32 encoding.
     *
     * @output false
     */
    public binary function encodeBinary( required binary input ) {
        // I map the 5-bit input chunks to the base32-encoding bytes.
        var encodingMap = getEncodingMap();

        // Base32-encoded strings must be divisible by 8 (so that the length of the data
        // is more predictable). We'll pad the null characters with "=".
        var paddingByte = asc( "=" );

        // I hold the intermediary, encoded bytes.
        var buffer = getAllocatedEncodingBuffer( input );

        // In order to iterate over the input bits more easily, we'll wrap it in a
        // BigInteger instance - this allows us to check individual bits without having
        // to calculate the offset across multiple bytes.
        var inputWrapper = createObject( "java", "java.math.BigInteger" ).init( input );

        // Since BigInteger will not take leading zeros into account, we have to
        // explicitly calculate the number of input bits based on the number of input
        // bytes.
        var bitCount = ( arrayLen( input ) * 8 );

        // Since each encoded chunk uses 5 bits, which may not divide evenly into a
        // set of 8-bit bytes, we need to normalize the input. Let's sanitize the input
        // wrapper to be evenly divisible by 5 (by pushing zeros onto the end). This
        // way, we never have to worry about reading an incomplete chunk of bits from
        // the underlying data.
        if ( bitCount % 5 ) {
            var missingBitCount = ( 5 - ( bitCount % 5 ) );

            inputWrapper = inputWrapper.shiftLeft( javacast( "int", missingBitCount ) );

            bitCount += missingBitCount;
        }

        // Now that we have know that our input bit count is evenly divisible by 5,
        // we can loop over the input in increments of 5 to read one decoded partial
        // byte at a time.
        // --
        // NOTE: We are starting a bitCount-1 since the bits are zero-indexed.
        for ( var chunkOffset = ( bitCount - 1 ); chunkOffset > 0; chunkOffset -= 5 ) {
            var partialByte = 0;

            // Read 5 bits into the partial byte, starting at the chunk offset.
            for ( var i = chunkOffset; i > ( chunkOffset - 5 ); i-- ) {
                // Implicit read of "0" bit into the right-most bit of the partial byte.
                partialByte = bitShln( partialByte, 1 );

                // If the underlying input bit is "1", update the partial byte.
                if ( inputWrapper.testBit( javacast( "int", i ) ) ) {
                    partialByte = bitOr( partialByte, 1 );
                }
            }

            // At this point, the partial byte value is a number that refers to the
            // index of the encoded value in the base32 character-set. Push the mapped
            // characterByte onto the buffer.
            // --
            // NOTE: We don't have to worry about converting to a signed byte since we
            // know the range of the inputs is always less than 128.
            buffer.put( encodingMap[ partialByte ] );
        }

        // If the number of chunks isn't divisible by 8, we need to pad the result.
        while ( buffer.remaining() ) {
            buffer.put( paddingByte );
        }

        // Return the result as a binary value.
        return ( buffer.array() );
    }


    // ---
    // PRIVATE METHODS.
    // ---


    /**
     * I provide a pre-allocated ByteBuffer that will store the output string value
     * during the decoding process. This takes into account the possible padding of the
     * input and will discard padding characters during buffer allocation.
     *
     * @output false
     */
    private any function getAllocatedDecodingBuffer( required binary input ) {
        var paddingByte = asc( "=" );

        var inputLength = arrayLen( input );

        // When allocating the output buffer, we don't want to take the padding
        // characters into account. Decrement the input length until we hit our first
        // trailing non-padding character.
        while ( input[ inputLength ] == paddingByte ) {
            inputLength--;
        }

        // Since each encoded byte reprsents only 5-bits of the encoded input, we know
        // that we know that the total number of meaningful input bits is *5. But then,
        // that has to represent full, 8-bit bytes.
        var totalOutputBytes = fix( inputLength * 5 / 8 );

        return ( createObject( "java", "java.nio.ByteBuffer" ).allocate( javacast( "int", totalOutputBytes ) ) );
    }


    /**
     * I provide a pre-allocated ByteBuffer that will store the base32 value during the
     * encoding process. This takes into account the possible need to pad the final output
     * and will be allocated to the exact length needed for encoding.
     *
     * @output false
     */
    private any function getAllocatedEncodingBuffer( required binary input ) {
        // Each 5-bits of the input bytes will represent a byte in the encoded value. As
        // such, we know that the output will required the total number of bits (n * 8)
        // divided by 5-bits (for each output byte).
        var totalOutputBytes = ceiling( arrayLen( input ) * 8 / 5 );

        // The length of the output has to be evenly divisible by 8; as such, if it is
        // not, we have to account of the trailing padding ("=") characters.
        if ( totalOutputBytes % 8 ) {
            totalOutputBytes += ( 8 - ( totalOutputBytes % 8 ) );
        }

        return ( createObject( "java", "java.nio.ByteBuffer" ).allocate( javacast( "int", totalOutputBytes ) ) );
    }


    /**
     * I return an array of character-bytes used to represent the set of possible Base32
     * encoding values.
     *
     * @output false
     * @hint This returns a Java array, not a ColdFusion array.
     */
    private array function getBase32Bytes() {
        return ( javacast( "string", "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567" ).getBytes() );
    }


    /**
     * I return a struct that maps Base32 input characters to the bytes that are
     * used in the encoding process.
     *
     * Example: map[ encodedByte ] => byte.
     *
     * @output false
     */
    private struct function getDecodingMap() {
        var byteMap = {};

        var bytes = getBase32Bytes();
        var byteLength = arrayLen( bytes );

        for ( var i = 1; i <= byteLength; i++ ) {
            byteMap[ bytes[ i ] ] = ( i - 1 );
        }

        return ( byteMap );
    }


    /**
     * I return a struct that maps input bytes to the characters that are used
     * to encode in Base32.
     *
     * Example: map[ byte ] => encodedByte.
     *
     * @output false
     */
    private struct function getEncodingMap() {
        var byteMap = {};

        var bytes = getBase32Bytes();
        var byteLength = arrayLen( bytes );

        for ( var i = 1; i <= byteLength; i++ ) {
            byteMap[ i - 1 ] = bytes[ i ];
        }

        return ( byteMap );
    }


    /**
     * I convert the given input to a Java Byte (which is signed).
     *
     * @output false
     */
    private any function toSignedByte( required numeric input ) {
        // If the 8th bit is turned on, then we have to make sure at the sign bit
        // is part of a 32-bit value with the sign carried over from the most
        // significant bit.
        if ( bitMaskRead( input, 7, 1 ) ) {
            return ( javacast( "byte", bitOr( input, -256 ) ) );
        } else {
            return ( javacast( "byte", input ) );
        }
    }

}
