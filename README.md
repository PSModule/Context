# Context

Modules typically handle two types of data that benefit from persistent secure storage and management: module settings and user settings and secrets.
This module introduces the concept of `Contexts`, which enable persistent and secure data storage for PowerShell modules. It allows module developers
to separate user and module data from the module code, enabling users to resume their work without needing to reconfigure the module or log in again,
provided the service supports session refresh mechanisms (e.g., refresh tokens).

The module uses NaCl-based encryption, provided by the `libsodium` library (delivered via the [`Sodium`](https://github.com/PSModule/Sodium) module),
to encrypt and decrypt `Context` data. The [`Sodium`](https://github.com/PSModule/Sodium) module is automatically installed when you install this
module.

## What is a `Context`?

The concept of `Context` is widely used to represent a collection of data that is relevant to a specific use-case. In this module,
a `Context` is a way to securely persist user and module data and offers a set of functions to manage this across modules that implement it.
Data that is stored in a `Context` can include user-specific settings, secrets, and module configuration data.
A `Context` is identified by a unique ID in the module that implements it.
Any data that can be represented in JSON format can be stored in a `Context`.

## Grouping Contexts into Vaults

Contexts can be grouped into `ContextVaults`, which are logical containers for related contexts. This allows for organization and management of
contexts, especially when dealing with multiple users or modules. Vaults are automatically created when you store a context, and they can be managed
using the provided functions in this module.

### Directory Structure

```plaintext
$HOME/.contextvaults/
├── GitHub/
│   ├── 64a5bbaf-96b8-4090-a77d-75e02ab6c4e0.json
│   ├── f201dc50-c163-4a7a-8d69-aea7f696737d.json
│   └── shard
├── AzureDevOps/
│   ├── cf49fceb-38d1-47da-a0ae-219ac40e4d8c.json
│   ├── b521a424-dd1c-445b-a0d6-c26a29d93654.json
│   └── shard
```

In this example there are two named vaults (`GitHub` and `AzureDevOps`). Each vault contains its own `shard` file (for encryption) and two context
files (with unique GUID filenames) that store encrypted context data. Contexts in different vaults are completely isolated from each other.

### 1. Storing data (object or dictionary) to disk using `Set-Context`

To store data to disk, use the `Set-Context` function. The function needs an ID and the data object.
The object can be anything that can be converted and represented in JSON format.

```pwsh
Set-Context -ID 'john_doe' -Vault 'GitHub' -Context ([PSCustomObject]@{
    Username          = 'john_doe'
    AuthToken         = 'ghp_12345ABCDE67890FGHIJ' | ConvertTo-SecureString -AsPlainText -Force # gitleaks:allow
    LoginTime         = Get-Date
    IsTwoFactorAuth   = $true
    TwoFactorMethods  = @('TOTP', 'SMS')
})
```

### 2. The object is converted to JSON and prepared for encryption

The object that is passed into `Set-Context` is first analyzed. If the object contains any `SecureString` values, they are converted to plain-text and
prefixed with `[SECURESTRING]`. This indicates that these values should be restored back to `SecureString`. The whole object is then converted to a
JSON string.

```json
{
    "ID": "john_doe",
    "Username": "john_doe",
    "AuthToken": "[SECURESTRING]ghp_12345ABCDE67890FGHIJ",
    "LoginTime": "2024-11-21T21:16:56.2518249+01:00",
    "IsTwoFactorAuth": true,
    "TwoFactorMethods": ["TOTP", "SMS"]
}
```

### 3. Storing the context object to disk

Finally the data is encrypted using the `Sodium` module and saved to disk. The file is stored in the user's home
directory `$HOME/.contextvaults/<VaultName>/<context_id>.json`, where `<context_id>` is a generated GUID, providing a unique name for the file.
The encrypted JSON representation of the data is added to metadata object that holds other info such as the ID of the `Context` and the path to the
file where it is stored.

```json
{
    "ID": "github.com/john_doe",
    "Vault": "GitHub",
    "Path": "C:\\Users\\JohnDoe\\.contextvaults\\GitHub\\d2edaa6e-95a1-41a0-b6ef-0ecc5d116030.json",
    "Context": "0kGmtbQiEtih7 --< encrypted context data >-- ceqbMiBilUvEzO1Lk"
}
```

The metadata can be accessed using the `Get-ContextInfo` function.

## Installation

You can install the module from the PowerShell Gallery using the following command:

```powershell
Install-PSResource -Name Context -TrustRepository -Repository PSGallery
Import-Module -Name Context
```

## Implementation Guide for Module Developers

This section shows how to integrate the Context module into your PowerShell module to provide persistent, secure storage for module settings and user data.

### Quick Start

The simplest way to implement Contexts is using `Set-Context`, which automatically creates the vault if it doesn't exist:

```pwsh
# Store module configuration - vault is created automatically
Set-Context -ID 'ModuleSettings' -Vault 'MyModule' -Context @{
    DefaultApiEndpoint = 'https://api.example.com'
    TimeoutSeconds = 30
}

# Store user credentials
Set-Context -ID 'User.JohnDoe' -Vault 'MyModule' -Context @{
    Username = 'johndoe'
    ApiKey = 'secret-key' | ConvertTo-SecureString -AsPlainText -Force
    LastLogin = Get-Date
}
```

### Best Practices for Module Integration

#### 1. Create Wrapper Functions

Create module-specific wrapper functions to provide a familiar interface for your users:

```pwsh
# In your module
function Set-MyModuleContext {
    param(
        [Parameter(Mandatory)]
        [string] $ID,

        [Parameter(Mandatory)]
        [object] $Context
    )

    Set-Context -ID $ID -Vault 'MyModule' -Context $Context
}

function Get-MyModuleContext {
    param(
        [string] $ID = '*'
    )

    Get-Context -ID $ID -Vault 'MyModule'
}
```

#### 2. Module Configuration Pattern

Store module-wide settings that persist across sessions:

```pwsh
# Initialize module settings on first load
if (-not (Get-Context -ID 'Settings' -Vault 'MyModule' -ErrorAction SilentlyContinue)) {
    Set-Context -ID 'Settings' -Vault 'MyModule' -Context @{
        DefaultUser = $null
        ApiEndpoint = 'https://api.example.com'
        EnableLogging = $false
    }
}
```

#### 3. User Context Pattern

Handle multiple user accounts within your module:

```pwsh
# Store user-specific data
function Connect-MyService {
    param(
        [Parameter(Mandatory)]
        [string] $Username,

        [Parameter(Mandatory)]
        [SecureString] $ApiKey
    )

    # Store user context
    Set-Context -ID "User.$Username" -Vault 'MyModule' -Context @{
        Username = $Username
        ApiKey = $ApiKey
        ConnectedAt = Get-Date
    }

    # Update module settings to remember the current user
    $moduleSettings = Get-Context -ID 'Settings' -Vault 'MyModule'
    $moduleSettings.DefaultUser = $Username
    Set-Context -ID 'Settings' -Vault 'MyModule' -Context $moduleSettings
}
```

### Complete Example

Here's a complete example of how to implement Contexts in a hypothetical GitHub module:

```pwsh
# Module initialization (in .psm1 file)
$VaultName = 'GitHub'

# Initialize module settings if they don't exist
if (-not (Get-Context -ID 'ModuleSettings' -Vault $VaultName -ErrorAction SilentlyContinue)) {
    Set-Context -ID 'ModuleSettings' -Vault $VaultName -Context @{
        DefaultOrganization = $null
        ApiEndpoint = 'https://api.github.com'
        DefaultUser = $null
    }
}

# Public function to connect user
function Connect-GitHub {
    param(
        [Parameter(Mandatory)]
        [string] $Username,

        [Parameter(Mandatory)]
        [string] $Token
    )

    # Store user context with secure token
    Set-Context -ID "User.$Username" -Vault $VaultName -Context @{
        Username = $Username
        Token = $Token | ConvertTo-SecureString -AsPlainText -Force
        Organizations = @()
        LastConnected = Get-Date
    }

    # Set as default user
    $settings = Get-Context -ID 'ModuleSettings' -Vault $VaultName
    $settings.DefaultUser = $Username
    Set-Context -ID 'ModuleSettings' -Vault $VaultName -Context $settings

    Write-Host "Connected to GitHub as $Username"
}

# Public function to get current user context
function Get-GitHubUser {
    $settings = Get-Context -ID 'ModuleSettings' -Vault $VaultName
    if ($settings.DefaultUser) {
        Get-Context -ID "User.$($settings.DefaultUser)" -Vault $VaultName
    }
}
```

### Key Implementation Points

- **Automatic Vault Creation**: `Set-Context` creates the vault automatically if it doesn't exist, and preserves existing encryption keys
- **Consistent Vault Naming**: Use your module name as the vault name for organization
- **Wrapper Functions**: Provide module-specific functions that hide the vault parameter from users
- **SecureString Support**: The Context module automatically handles `SecureString` encryption and decryption
- **Module Settings**: Store module-wide configuration separate from user-specific data

## Vault Management (Advanced)

For most use cases, you don't need to manage vaults directly since `Set-Context` creates them automatically. However, you can manage vaults explicitly when needed:

```pwsh
# List all vaults
Get-ContextVault

# Get specific vault information
Get-ContextVault -Name "MyModule"

# Remove a vault and all its contexts (use with caution)
Remove-ContextVault -Name "OldModule"
```

## Context Operations

### Basic Operations

```pwsh
# Store a context (creates vault automatically)
Set-Context -ID 'UserSettings' -Vault 'MyModule' -Context @{
    Theme = 'Dark'
    Language = 'en-US'
}

# Retrieve a context
Get-Context -ID 'UserSettings' -Vault 'MyModule'

# Get all contexts in a vault
Get-Context -Vault 'MyModule'

# Remove a context
Remove-Context -ID 'UserSettings' -Vault 'MyModule'

# Rename a context
Rename-Context -ID 'OldName' -NewID 'NewName' -Vault 'MyModule'

# Get context metadata (without decrypting)
Get-ContextInfo -Vault 'MyModule'
```

## Important Notes

- **Vault Requirement**: Every context must be stored in a named vault - there is no default vault
- **Automatic Vault Creation**: `Set-Context` automatically creates vaults if they don't exist
- **Encryption Key Preservation**: Existing vault encryption keys are preserved when using `Set-Context`
- **Vault Isolation**: Each vault is isolated with its own encryption keys and storage directory
- **Storage Location**: Vaults are stored under `$HOME/.contextvaults/<VaultName>/`
- **SecureString Support**: The module automatically handles encryption/decryption of `SecureString` values
