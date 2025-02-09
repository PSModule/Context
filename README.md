# Context

Modules usually have two types of data that would be great to store and manage in a good way: module and user settings and secrets. With this module,
we aim to store this data using a the concept of `Contexts` that are stored locally on the machine where the module is running. It lets module
developers separate user and module data from the module code, so that modules can be created in a way where users can resume from where they left off
without having to reconfigure the module or log in to services that support refreshing sessions with data you can store, i.e., refresh tokens.

The module uses NaCl based encryption delivered by the `libsodium` library to encrypt and decrypt the data stored in a `Context`. The module that
serves this functionality is called [`Sodium`](https://github.com/someuser/Sodium) and is a dependency of this module. The
[`Sodium`](https://github.com/someuser/Sodium) module is automatically installed when you install this module.

## What is a `Context`?

A `Context` is a way to persist user and module state securely on disk while ensuring data remains encrypted at rest. It stores structured data that
can be represented in JSON format, including regular values and secure secrets. It can hold multiple secrets (such as passwords or API tokens)
alongside general data like configuration settings, session metadata, or user preferences. Secure secrets are specially handled to maintain their
security when stored and retrieved.

When saving a `Context`, the data is converted to a plain-text JSON structure, then encrypted and written to disk. Secure strings are marked with a
special prefix before encryption, ensuring they can be safely restored as secure strings when the `Context` is loaded back into memory.

When imported, the encrypted data is decrypted, converted back into its original structured format, and held in memory, ensuring both usability and
security.

<details>
<summary>Input to Set-Context - As a PSCustomObject</summary>

Typical the first input to a context (altho it can also be a hashtable or any other object type that converts with JSON)

```pwsh
Set-Context -ID 'john_doe' -Context ([PSCustomObject]@{
    Username          = 'john_doe'
    AuthToken         = 'ghp_12345ABCDE67890FGHIJ' | ConvertTo-SecureString -AsPlainText -Force #gitleaks:allow
    LoginTime         = Get-Date
    IsTwoFactorAuth   = $true
    TwoFactorMethods  = @('TOTP', 'SMS')
    LastLoginAttempts = @(
        [PSCustomObject]@{
            Timestamp = (Get-Date).AddHours(-1)
            IP        = '192.168.1.101' | ConvertTo-SecureString -AsPlainText -Force
            Success   = $true
        },
        [PSCustomObject]@{
            Timestamp = (Get-Date).AddDays(-1)
            IP        = '203.0.113.5' | ConvertTo-SecureString -AsPlainText -Force
            Success   = $false
        }
    )
    UserPreferences   = @{
        Theme         = 'dark'
        DefaultBranch = 'main'
        Notifications = [PSCustomObject]@{
            Email = $true
            Push  = $false
            SMS   = $true
        }
        CodeReview    = @('PR Comments', 'Inline Suggestions')
    }
    Repositories      = @(
        [PSCustomObject]@{
            Name        = 'Repo1'
            IsPrivate   = $true
            CreatedDate = (Get-Date).AddMonths(-6)
            Stars       = 42
            Languages   = @('Python', 'JavaScript')
        },
        [PSCustomObject]@{
            Name        = 'Repo2'
            IsPrivate   = $false
            CreatedDate = (Get-Date).AddYears(-1)
            Stars       = 130
            Languages   = @('C#', 'HTML', 'CSS')
        }
    )
    AccessScopes      = @('repo', 'user', 'gist', 'admin:org')
    ApiRateLimits     = [PSCustomObject]@{
        Limit     = 5000
        Remaining = 4985
        ResetTime = (Get-Date).AddMinutes(30)
    }
    SessionMetaData   = [PSCustomObject]@{
        SessionID   = 'sess_abc123'
        Device      = 'Windows-PC'
        Location    = [PSCustomObject]@{
            Country = 'USA'
            City    = 'New York'
        }
        BrowserInfo = [PSCustomObject]@{
            Name    = 'Chrome'
            Version = '118.0.1'
        }
    }
})
```
</details>

<details>
<summary>The stored data - As a processed JSON</summary>

This is how the objecet above is stored, except that this is an uncomressed version for readability.
Here you see that the `ID` property gets added.

```json
{
    "ID": "john_doe",
    "Username": "john_doe",
    "AuthToken": "[SECURESTRING]ghp_12345ABCDE67890FGHIJ",
    "LoginTime": "2024-11-21T21:16:56.2518249+01:00",
    "IsTwoFactorAuth": true,
    "TwoFactorMethods": [
        "TOTP",
        "SMS"
    ],
    "LastLoginAttempts": [
        {
            "Timestamp": "2024-11-21T20:16:56.2518510+01:00",
            "IP": "[SECURESTRING]192.168.1.101",
            "Success": true
        },
        {
            "Timestamp": "2024-11-20T21:16:56.2529436+01:00",
            "IP": "[SECURESTRING]203.0.113.5",
            "Success": false
        }
    ],
    "UserPreferences": {
        "Theme": "dark",
        "DefaultBranch": "main",
        "Notifications": {
            "Email": true,
            "Push": false,
            "SMS": true
        },
        "CodeReview": [
            "PR Comments",
            "Inline Suggestions"
        ]
    },
    "Repositories": [
        {
            "Name": "Repo1",
            "IsPrivate": true,
            "CreatedDate": "2024-05-21T21:16:56.2540703+02:00",
            "Stars": 42,
            "Languages": [
                "Python",
                "JavaScript"
            ]
        },
        {
            "Name": "Repo2",
            "IsPrivate": false,
            "CreatedDate": "2023-11-21T21:16:56.2545789+01:00",
            "Stars": 130,
            "Languages": [
                "C#",
                "HTML",
                "CSS"
            ]
        }
    ],
    "AccessScopes": [
        "repo",
        "user",
        "gist",
        "admin:org"
    ],
    "ApiRateLimits": {
        "Limit": 5000,
        "Remaining": 4985,
        "ResetTime": "2024-11-21T21:46:56.2550348+01:00"
    },
    "SessionMetaData": {
        "SessionID": "sess_abc123",
        "Device": "Windows-PC",
        "Location": {
            "Country": "USA",
            "City": "New York"
        },
        "BrowserInfo": {
            "Name": "Chrome",
            "Version": "118.0.1"
        }
    }
}
```
</details>

<details>
<summary>Output from Get-Context - As a PSCustomObject</summary>

This is how the object is returned from the `Get-Context` function.
Notice that the `ID` property has been added to the object.

```pwsh
Get-Context -ID 'john_doe'

ID                : john_doe
UserPreferences   : @{DefaultBranch=main; Notifications=; Theme=dark; CodeReview=System.Object[]}
LastLoginAttempts : {@{Success=True; IP=System.Security.SecureString; Timestamp=11/24/2024 2:09:12 PM}, @{Success=False; IP=System.Security.SecureString; Timestamp=11/23/2024 3:09:12 PM}}
IsTwoFactorAuth   : True
AuthToken         : System.Security.SecureString
TwoFactorMethods  : {TOTP, SMS}
LoginTime         : 11/24/2024 3:09:12 PM
ApiRateLimits     : @{Limit=5000; Remaining=4985; ResetTime=11/24/2024 3:39:12 PM}
Repositories      : {@{CreatedDate=5/24/2024 3:09:12 PM; Stars=42; Name=Repo1; IsPrivate=True; Languages=System.Object[]}, @{CreatedDate=11/24/2023 3:09:12 PM; Stars=130; Name=Repo2; IsPrivate=False;
                    Languages=System.Object[]}}
SessionMetaData   : @{BrowserInfo=; Device=Windows-PC; Location=; SessionID=sess_abc123}
Username          : john_doe
AccessScopes      : {repo, user, gist, admin:org}
```
</details>

## Prerequisites

This module relies on [Microsoft.PowerShell.SecretManagement](https://github.com/powershell/SecretManagement) and
[Microsoft.PowerShell.SecretStore](https://github.com/PowerShell/SecretStore). The module automatically installs these modules if they are not
already installed.

## Installation

Install the module from the PowerShell Gallery by running the following command:

```powershell
Install-PSResource -Name Context -TrustRepository -Repository PSGallery
Import-Module -Name Context
```

## Usage

As mentioned earlier, there are two types of data that can be stored using the `Context` module: module and user settings and secrets.
Lets have a look at how to use the module to store these types of data in abit more detail.

### Module settings

To store module data, the module developer can create a context that defines a "namespace" for the module. This context can store settings and secrets
for the module. A module developer can also create additional contexts for additional settings that share the same lifecycle, like settings
associated with a module extension.

Let's say we have a module called `GitHub` that needs to store some settings and secrets. The module developer could initialize a context called
`GitHub` as part of the loading section in the module code. All module configuration could be stored in this context by using the functionality in
this module. The context for the module is stored in the `ContextVault` as a secret with the name `GitHub`.

### User Configuration

To store user data, the module developer can create a new context that defines a "namespace" for the user configuration. So let's say a developer has
implemented this for the `GitHub` module, a user would log in using their details. The module would call upon `Context` functionality to create a new
context under the `GitHub` namespace.

Imagine a user called `BobMarley` logs in to the `GitHub` module. The following would exist in the context:

- `GitHub` containing module configuration, like default user, host, and client ID to use if not otherwise specified.
- `GitHub/BobMarley` containing user configuration, details about the user, secrets and default values for API calls etc.

Let's say the person also has another account on `GitHub` called `LennyKravitz`. After logging on the second account, the following context would
also exist in the context:

- `GitHub/LennyKravitz` containing user configuration, details about the user, secrets and default values for API calls etc.

With this the module developer could allow users to set default context, and store a key of the name of that context in the module context. This way
the module could automatically log in the user to the correct account when the module is loaded. The user could also switch between accounts by
changing the default context.

### Setup for a New Module

To set up a new module to use the `Context` module, the following steps should be taken:

1. Create a new context for the module -> `Set-Context -ID 'GitHub' -Context @{ ... }` during the module initialization.

`src\variable\private\Config.ps1`
```pwsh
$script:Config = @{
    Name = 'GitHub'
}
```

`src\loader.ps1`
```pwsh
### This is the context config for this module
$contextParams = @{
    ID      = 'GitHub'
    Context = @{
        Name = 'GitHub'
    }
}
try {
    Set-Context @contextParams
} catch {
    Write-Error $_
    throw 'Failed to initialize secret vault'
}
```

2. Add some module configuration -> `$context = Get-Context -ID 'GitHub'` -> Change settings using the returned object and
   then `Set-Context -ID 'GitHub' -Context $context` to store the changes.

### Setup for a New user context

To set up a new context for a user, the following steps should be taken:

1. Create a set of public integration functions that uses the `Context` module to store user data. Its highly recommended
   to do this so that you as a module developer can create the structure you want for the context, while also giving the user the expected function
   names to interact with the module.
   - `Set-<ModuleName>Context` that uses `Set-Context`.
   - `Get-<ModuleName>Context` that uses `Get-Context`.
   - `Remove-<ModuleName>Context` that uses `Remove-Context`

2. Create a new context for the user `Connect-GitHub ...` -> `Set-Context -ID 'GitHub.BobMarley'` -> Context `GitHub/BobMarley` is created.
3. Add some user configuration -> `$context = Get-Context -ID 'GitHub.BobMarley'` -> Change settings using the returned object and
then `Set-Context -ID 'GitHub.BobMarley' -Context $context` to store the changes.
4. Get the user configuration -> `Get-Context -Context 'GitHub/BobMarley'` -> The context object is returned, and you can access the data in it.

## Contributing

Coder or not, you can contribute to the project! We welcome all contributions.

### For Users

If you don't code, you still sit on valuable information that can make this project even better. If you experience that the
product does unexpected things, throws errors, or is missing functionality, you can help by submitting bugs and feature requests.
Please see the issues tab on this project and submit a new issue that matches your needs.

### For Developers

If you do code, we'd love to have your contributions. Please read the [Contribution guidelines](CONTRIBUTING.md) for more information.

## Links

- Sodium [GitHub](https://github.com/someuser/Sodium) | [PSGallery](https://www.powershellgallery.com/packages/Sodium)
