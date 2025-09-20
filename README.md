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

### Context Types

The Context module supports two distinct types of contexts to provide clear separation of concerns:

#### User Contexts (Default)
User contexts store per-user data such as:
- Authentication tokens and credentials
- Personal preferences and settings
- User-specific configuration
- Account information

```pwsh
# Create a user context (default behavior)
Set-Context -ID 'john_doe' -Vault 'GitHub' -Context @{
    Username = 'john_doe'
    Token = 'ghp_token123' | ConvertTo-SecureString -AsPlainText -Force
    Preferences = @{ Theme = 'dark'; Notifications = $true }
}

# Retrieve user context
$userContext = Get-Context -ID 'john_doe' -Vault 'GitHub'
```

#### Module Contexts
Module contexts store system-level configuration shared across users:
- API endpoints and service configurations
- Module-wide settings and defaults
- Environment-specific configurations (production, staging, development)
- Feature flags and operational parameters

```pwsh
# Create a module context
Set-Context -ID 'default' -Vault 'GitHub' -Type 'Module' -Context @{
    ApiEndpoint = 'https://api.github.com'
    RateLimit = 5000
    DefaultBranch = 'main'
}

# Create alternative module contexts for different environments
Set-Context -ID 'staging' -Vault 'GitHub' -Type 'Module' -Context @{
    ApiEndpoint = 'https://staging-api.github.com'
    RateLimit = 1000
    DefaultBranch = 'develop'
}

# Retrieve active module context (defaults to the currently active one)
$moduleContext = Get-Context -Vault 'GitHub' -Type 'Module'

# Switch between module contexts
Switch-ModuleContext -Vault 'GitHub' -ContextName 'staging'
```

**Key Features of Module Contexts:**
- **Active Context Tracking**: The module automatically tracks which module context is currently active
- **Default Context**: Every vault automatically has a 'default' module context
- **Context Switching**: Switch between different module configurations (e.g., production vs staging)
- **Persistence**: The active context selection persists across PowerShell sessions

## Grouping Contexts into Vaults

Contexts can be grouped into `ContextVaults`, which are logical containers for related contexts. This allows for organization and management of
contexts, especially when dealing with multiple users or modules. Vaults are automatically created when you store a context, and they can be managed
using the provided functions in this module.

### Directory Structure

```plaintext
$HOME/.contextvaults/
├── GitHub/
│   ├── module/                          # Module contexts (system-level configuration)
│   │   ├── active-context               # Active module context name (plaintext)
│   │   ├── default.json                 # Default module context (encrypted)
│   │   ├── staging.json                 # Alternative module context (encrypted)
│   │   └── production.json              # Alternative module context (encrypted)
│   ├── user/                            # User contexts (per-user data)
│   │   ├── 64a5bbaf-96b8-4090-a77d-75e02ab6c4e0.json  # User context (encrypted)
│   │   └── f201dc50-c163-4a7a-8d69-aea7f696737d.json  # User context (encrypted)
│   ├── shard                            # Vault encryption key
│   └── config.json                      # Vault metadata (optional)
├── AzureDevOps/
│   ├── module/
│   │   ├── active-context
│   │   └── default.json
│   ├── user/
│   │   ├── cf49fceb-38d1-47da-a0ae-219ac40e4d8c.json
│   │   └── b521a424-dd1c-445b-a0d6-c26a29d93654.json
│   └── shard
```

This structure provides clear separation between:
- **Module contexts** (`module/` directory): System-level configuration shared across users, with active context tracking
- **User contexts** (`user/` directory): Per-user data like authentication tokens and personal preferences

Each vault contains its own `shard` file for encryption. The `active-context` file in the module directory stores the name of the currently active module context as plaintext for quick access without decryption.

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
function Set-MyModuleUserContext {
    param(
        [Parameter(Mandatory)]
        [string] $ID,

        [Parameter(Mandatory)]
        [object] $Context
    )

    Set-Context -ID $ID -Vault 'MyModule' -Context $Context -Type 'User'
}

function Get-MyModuleUserContext {
    param(
        [string] $ID = '*'
    )

    Get-Context -ID $ID -Vault 'MyModule' -Type 'User'
}

function Get-MyModuleConfig {
    # Gets the active module configuration
    Get-Context -Vault 'MyModule' -Type 'Module'
}

function Set-MyModuleEnvironment {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('production', 'staging', 'development')]
        [string] $Environment
    )
    
    Switch-ModuleContext -Vault 'MyModule' -ContextName $Environment
}
```

#### 2. Module Configuration Pattern

Use module contexts to store system-level configuration that can be switched between environments:

```pwsh
# Initialize default module configuration on first load
if (-not (Get-Context -ID 'default' -Vault 'MyModule' -Type 'Module' -ErrorAction SilentlyContinue)) {
    Set-Context -ID 'default' -Vault 'MyModule' -Type 'Module' -Context @{
        ApiEndpoint = 'https://api.example.com'
        TimeoutSeconds = 30
        EnableLogging = $false
        RateLimit = 1000
    }
}

# Create staging configuration
Set-Context -ID 'staging' -Vault 'MyModule' -Type 'Module' -Context @{
    ApiEndpoint = 'https://staging-api.example.com'
    TimeoutSeconds = 60
    EnableLogging = $true
    RateLimit = 500
}

# Switch between environments
function Set-MyModuleEnvironment {
    param([ValidateSet('default', 'staging')][string] $Environment)
    Switch-ModuleContext -Vault 'MyModule' -ContextName $Environment
    Write-Host "Switched to $Environment environment"
}

# Get current configuration (automatically uses active module context)
function Get-MyModuleConfiguration {
    Get-Context -Vault 'MyModule' -Type 'Module'
}
```

#### 3. User Context Pattern

Handle multiple user accounts within your module using user contexts:

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

Here's a complete example of how to implement Contexts in a hypothetical GitHub module using both module and user contexts:

```pwsh
# Module initialization (in .psm1 file)
$VaultName = 'GitHub'

# Initialize default module configuration
if (-not (Get-Context -ID 'default' -Vault $VaultName -Type 'Module' -ErrorAction SilentlyContinue)) {
    Set-Context -ID 'default' -Vault $VaultName -Type 'Module' -Context @{
        ApiEndpoint = 'https://api.github.com'
        DefaultOrganization = $null
        RequestTimeout = 30
        EnableRateLimit = $true
        MaxRetries = 3
    }
}

# Create staging environment configuration
Set-Context -ID 'staging' -Vault $VaultName -Type 'Module' -Context @{
    ApiEndpoint = 'https://staging-api.github.com'
    DefaultOrganization = 'staging-org'
    RequestTimeout = 60
    EnableRateLimit = $false
    MaxRetries = 1
}

# Environment switching function
function Set-GitHubEnvironment {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('default', 'staging')]
        [string] $Environment
    )
    
    Switch-ModuleContext -Vault $VaultName -ContextName $Environment
    $config = Get-Context -Vault $VaultName -Type 'Module'
    Write-Host "Switched to $Environment environment (API: $($config.ApiEndpoint))"
}

# Get current module configuration
function Get-GitHubConfiguration {
    Get-Context -Vault $VaultName -Type 'Module'
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
    Set-Context -ID $Username -Vault $VaultName -Type 'User' -Context @{
        Username = $Username
        Token = $Token | ConvertTo-SecureString -AsPlainText -Force
        Organizations = @()
        LastConnected = Get-Date
        Preferences = @{
            DefaultBranch = 'main'
            Theme = 'dark'
        }
    }

    Write-Host "Connected to GitHub as $Username"
}

# Public function to get current user context
function Get-GitHubUser {
    param(
        [string] $Username
    )
    
    if ($Username) {
        Get-Context -ID $Username -Vault $VaultName -Type 'User'
    } else {
        # Return all user contexts
        Get-Context -Vault $VaultName -Type 'User'
    }
}

# Function that uses both module and user contexts
function Get-GitHubRepositories {
    param(
        [Parameter(Mandatory)]
        [string] $Username
    )
    
    # Get user context for authentication
    $userContext = Get-Context -ID $Username -Vault $VaultName -Type 'User'
    if (-not $userContext) {
        throw "User '$Username' not found. Use Connect-GitHub first."
    }
    
    # Get module context for API configuration
    $moduleConfig = Get-Context -Vault $VaultName -Type 'Module'
    
    # Use configuration to make API calls
    $headers = @{
        'Authorization' = "token $($userContext.Token | ConvertFrom-SecureString -AsPlainText)"
        'User-Agent' = 'PowerShell-GitHub-Module'
    }
    
    $uri = "$($moduleConfig.ApiEndpoint)/user/repos"
    Invoke-RestMethod -Uri $uri -Headers $headers -TimeoutSec $moduleConfig.RequestTimeout
}
```

### Key Implementation Points

- **Module Contexts**: Store system-level configuration that can be switched between environments
- **User Contexts**: Store per-user authentication and preferences separately
- **Active Context Management**: The module automatically tracks the active module context
- **Environment Switching**: Easily switch between different API environments
- **Automatic Vault Creation**: `Set-Context` creates the vault automatically if it doesn't exist
- **Consistent Vault Naming**: Use your module name as the vault name for organization
- **SecureString Support**: The Context module automatically handles `SecureString` encryption and decryption
- **Clean Separation**: Module config and user data are stored separately for better organization

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
# Store a user context (default behavior)
Set-Context -ID 'UserSettings' -Vault 'MyModule' -Context @{
    Theme = 'Dark'
    Language = 'en-US'
}

# Store a module context
Set-Context -ID 'default' -Vault 'MyModule' -Type 'Module' -Context @{
    ApiEndpoint = 'https://api.example.com'
    Timeout = 30
}

# Retrieve a user context
Get-Context -ID 'UserSettings' -Vault 'MyModule'

# Retrieve a module context
Get-Context -ID 'default' -Vault 'MyModule' -Type 'Module'

# Get active module context (no ID needed)
Get-Context -Vault 'MyModule' -Type 'Module'

# Get all user contexts in a vault
Get-Context -Vault 'MyModule' -Type 'User'

# Get all module contexts in a vault
Get-Context -Vault 'MyModule' -Type 'Module'

# Remove a user context
Remove-Context -ID 'UserSettings' -Vault 'MyModule' -Type 'User'

# Remove a module context
Remove-Context -ID 'staging' -Vault 'MyModule' -Type 'Module'

# Rename a context
Rename-Context -ID 'OldName' -NewID 'NewName' -Vault 'MyModule' -Type 'User'

# Get context metadata (without decrypting)
Get-ContextInfo -Vault 'MyModule' -Type 'User'
Get-ContextInfo -Vault 'MyModule' -Type 'Module'
```

### Module Context Management

```pwsh
# Switch between module contexts
Switch-ModuleContext -Vault 'MyModule' -ContextName 'staging'

# Get the name of the active module context
Get-ActiveModuleContextName -Vault 'MyModule'

# Create multiple environment configurations
Set-Context -ID 'production' -Vault 'MyModule' -Type 'Module' -Context @{
    ApiEndpoint = 'https://api.example.com'
    EnableDebug = $false
}

Set-Context -ID 'staging' -Vault 'MyModule' -Type 'Module' -Context @{
    ApiEndpoint = 'https://staging-api.example.com'
    EnableDebug = $true
}

# Switch to staging and verify
Switch-ModuleContext -Vault 'MyModule' -ContextName 'staging' -PassThru
```

## Important Notes

- **Vault Requirement**: Every context must be stored in a named vault - there is no default vault
- **Automatic Vault Creation**: `Set-Context` automatically creates vaults if they don't exist
- **Encryption Key Preservation**: Existing vault encryption keys are preserved when using `Set-Context`
- **Vault Isolation**: Each vault is isolated with its own encryption keys and storage directory
- **Storage Location**: Vaults are stored under `$HOME/.contextvaults/<VaultName>/`
- **SecureString Support**: The module automatically handles encryption/decryption of `SecureString` values
