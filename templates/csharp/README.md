All based on a5f638fefd45b124c890af742c5c91db21015811

A non exhaustive list of changes follows.

# partial_header

Adds the copyright info

# netcore_project

Modifies all the dependencies

# api

Add better support for File responses.
properly support multiple accept header values.
Do not dispose `HttpResponseMessage` and add it to the ApiResponse so the streams can be read for files.

# ClientUtils

Add function to support multiple accept header values

# TokenBase, TokenProvider\`1 and RateLimitProvider\`1

Make GetAsync as public and make these suitable for JIT tokens based on OAuth secrets.
Remove required container to beeter support JIT retrieval of tokens.

# DateOnlyJsonConverter and DateOnlyNullableJsonConverter

Removed unsupported `DateTimeStyles` from `TryParseExact` call.

# AsModel, ApiException, ApiResposne\`1 and 

Add proper support for the file results so returning the stream works.
Add RawResponse and ContentHeaders property to better support file downloads.
