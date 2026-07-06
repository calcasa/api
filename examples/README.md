# Calcasa API Examples

This directory contains end-to-end sample clients for the Calcasa API in:

- C# (.NET)
- PHP
- Python

All examples use OAuth2 client credentials and are configured for the staging environment by default.

## Contents

- `csharp/`: C# examples (`ApiTest.Valuations` and `ApiTest.FileSets`)
- `php/`: PHP example (`php-test.php`)
- `python/`: Python example (`python-test.py`)
- `.env.example`: template for required credentials

## Prerequisites

- Valid Calcasa API OAuth client credentials:
	- `CALCASA_CLIENT_ID`
	- `CALCASA_CLIENT_SECRET`
- Access to the staging API endpoints used by these examples

Language-specific prerequisites:

- C#: .NET SDK
	- `ApiTest.Valuations` targets `net10.0`
	- `ApiTest.FileSets` targets `net10.0`
- PHP: PHP 8.1+ and Composer
- Python: Python 3.10+ and `pip`

## Quick Start

1. Create a local env file in this `examples/` folder:

```bash
cp .env.example .env
```

On Windows PowerShell:

```powershell
Copy-Item .env.example .env
```

2. Fill in your credentials in `.env`:

```dotenv
CALCASA_CLIENT_ID=your-client-id
CALCASA_CLIENT_SECRET=your-client-secret
```

3. Install dependencies and run one of the language examples from the sections below.

## C# Example

Folder: `csharp/`

Solution contains:

- `ApiTest.Valuations` (console app)
- `ApiTest.FileSets` (console app)
- `ApiTest.Shared` (shared auth/config code)

### Install Dependencies

From `examples/csharp/`:

```bash
dotnet restore ApiTest.slnx
```

### Build

```bash
dotnet build ApiTest.slnx
```

### Run

Run valuations sample:

```bash
dotnet run --project ApiTest.Valuations/ApiTest.Valuations.csproj
```

Run file-sets sample:

```bash
dotnet run --project ApiTest.FileSets/ApiTest.FileSets.csproj
```

### Options You Can Change

In both `ApiTest.Valuations/Program.cs` and `ApiTest.FileSets/Program.cs`:

- API base URL:
	- default: `https://api.staging.calcasa.nl/api/v1`
- Token URL:
	- default: `https://authentication.01.staging.calcasa.nl/oauth2/v2.0/token`
- Callback URL in configuration example:
	- default: `https://test.calcasa.nl/callback/`
- User Agent string (`set via API client settings`)
- Sample valuation input values:
	- address/postcode/huisnummer
	- product type
	- hypotheekwaarde, klantwaarde, NHG/erfpacht flags

## PHP Example

Folder: `php/`

Entry script:

- `php-test.php`

### Install Dependencies

From `examples/php/`:

```bash
composer install
```

Notes:

- `composer.json` references the local package source `../../libraries/api-php` as a path repository.
- If that path is unavailable, adjust `composer.json` to use Packagist (`calcasa/api`) or an accessible source.

### Run

```bash
php ./php-test.php
```

### Options You Can Change

In `php-test.php` and `OAuthConfiguration.php`:

- API base path:
	- default: `https://api.staging.calcasa.nl/api/v1`
- Token URL:
	- default: `https://authentication.01.staging.calcasa.nl/oauth2/v2.0/token`
- Callback URL used in configuration endpoint example
- Sample valuation payload values
- User Agent string:
	- default: `PHP Application Name/0.0.1`

## Python Example

Folder: `python/`

Entry script:

- `python-test.py`

### Install Dependencies

From `examples/python/`:

```bash
python -m venv .venv
```

Activate virtual environment:

Windows PowerShell:

```powershell
.\.venv\Scripts\Activate.ps1
```

macOS/Linux:

```bash
source .venv/bin/activate
```

Install packages:

```bash
pip install -r requirements.txt
```

Notes:

- `requirements.txt` references local package path `../../libraries/api-python`.
- If unavailable, replace with a published package version, for example `calcasa-api==<version>`.

### Run

From `examples/python/`:

```bash
python python-test.py
```

### Options You Can Change

In `python-test.py`:

- API host:
	- default: `https://api.staging.calcasa.nl/api/v1`
- Token URL:
	- default: `https://authentication.01.staging.calcasa.nl/oauth2/v2.0/token`
- Callback URL used in configuration example
- User Agent string:
	- default: `Python Application Name/0.0.1`
- Sample request values:
	- address inputs
	- valuation input parameters
	- search parameters

## What the Examples Do

The current scripts demonstrate a broad workflow:

- Address lookup endpoints
- Callback configuration update and reset
- Valuation creation and patching
- Poll/wait simulation and webhook payload handling
- Download and persist report, invoice, and photo files when available
- Search valuations by parameters

Generated output files may be written to the current working directory, for example:

- `calcasa-report-*.pdf` or `calcasa-report-*.jpg` (depends on script and response metadata)
- `calcasa-invoice-*`
- `calcasa-photo-*`

## Troubleshooting

### Missing credentials

Symptom:

- script exits with message about missing `CALCASA_CLIENT_ID`/`CALCASA_CLIENT_SECRET`

Fix:

- ensure `.env` exists in `examples/`
- verify keys are present and non-empty
- restart the process after updating the file

### OAuth/token errors

Symptom:

- token fetch fails or API returns unauthorized

Fix:

- verify client id/secret
- verify token URL and API host belong to the same environment
- verify the client has the required API scopes/permissions

## Notes

- These examples are designed to show end-to-end usage patterns and should be adapted before production use.
- For production, add robust retry, logging, observability, and secure secret handling.
