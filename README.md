# Context

Modules typically handle two types of data that benefit from persistent secure storage and management: module settings and user settings and secrets.
This module introduces the concept of `Contexts`, which enable persistent and secure data storage for PowerShell modules. It allows module developers to
separate user and module data from the module code, enabling users to resume their work without needing to reconfigure the module or log in again,
provided the service supports session refresh mechanisms (e.g., refresh tokens).

The module uses NaCl-based encryption, provided by the `libsodium` library, to encrypt and decrypt `Context` data. The module that delivers this
functionality is called [`Sodium`](https://github.com/PSModule/Sodium) and is a dependency of this module. The
[`Sodium`](https://github.com/PSModule/Sodium) module is automatically installed when you install this module.

## What is a `Context`?

The concept of `Context` is widely used to represent a collection of data that is relevant to a specific use-case. In this module,
a `Context` is a way to securely persist user and module data and offers a set of functions to manage this across modules that implement it.
Data that is stored in a `Context` can include user-specific settings, secrets, and module configuration data.
A `Context` is identified by a unique ID, which is typically a string that represents the module and user of a module (e.g., `GitHub/john_doe`), but
this is just an example. Any data that can be represented in JSON format can be stored in a `Context`.

### 1. Storing data (object or dictionary) to disk using `Set-Context`

To store data to disk, use the `Set-Context` function. The function needs an ID and the data object.
The object can be anything that can be converted and represented in JSON format.

```pwsh
Set-Context -ID 'john_doe' -Context ([PSCustomObject]@{
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

When the data is primed for storage, it is finally encrypted using the `Sodium` module and saved to disk. The file is stored in the user's home
directory `$HOME\.contextvault\<context_id>.json`, where `<context_id>` is a generated GUID, providing a unique name for the file.
The encrypted JSON representation of the data is added to metadata object that holds other info such as the ID of the `Context` and the path to the
file where it is stored.

```json
{
    "ID": "PSModule.GitHub/github.com/john_doe",
    "Path": "C:\\Users\\JohnDoe\\.contextvault\\d2edaa6e-95a1-41a0-b6ef-0ecc5d116030.json",
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

## Usage

Let's take a closer look at how to store these types of data using the module.

### Module Settings

A module developer can create additional `Contexts` for settings that share the same lifecycle, such as those associated with a module extension.

For example, if we have a module called `GitHub` that needs to store some settings, the module developer could initialize a `Context` called `GitHub`
as part of the loading section in the module code. The module configuration is accessed using the ID `GitHub`.

### User Configuration

To store user data, a module developer can create a `Context` that serves as a "namespace" for user-specific configurations.

Imagine a user named `BobMarley` logs into the `GitHub` module. The following logical structure would be created:

- `GitHub`: Contains module configuration, like default user, host, and client ID.
- `GitHub/BobMarley`: Contains user configuration, secrets, and default values for API calls.

If the same user logs in with another account (`LennyKravitz`), an additional `Context` will be created:

- `GitHub/LennyKravitz`: Contains user-specific settings and secrets.

This allows users to set a default `Context`, storing its name in the module `Context`, enabling automatic login to the correct account when the
module loads. Users can also switch between accounts by changing the default `Context`.

### Setup for a New Module

1. Create a new context for the module:

```pwsh
Set-Context -ID 'GitHub' -Context @{ Name = 'GitHub' }
```

2. Add module configuration:

```pwsh
$context = Get-Context -ID 'GitHub'
# Modify settings as needed
Set-Context -ID 'GitHub' -Context $context
```

### Setup for a New User Context

1. Create a set of public integration functions using the `Context` module to store user data. This is highly recommended, as it allows module
developers to define a structured `Context` while providing users with familiar function names for interaction.
   - `Set-<ModuleName>Context` that uses `Set-Context`.
   - `Get-<ModuleName>Context` that uses `Get-Context`.
   - `Remove-<ModuleName>Context` that uses `Remove-Context`.

2. Create a new `Context` for the user:

```pwsh
Connect-GitHub ...
Set-Context -ID 'GitHub.BobMarley'
```

3. Modify user configuration:

```pwsh
$context = Get-Context -ID 'GitHub.BobMarley'
# Modify settings
Set-Context -ID 'GitHub.BobMarley' -Context $context
```

4. Retrieve user configuration:

```pwsh
Get-Context -ID 'GitHub/BobMarley'
```

## Contributing

### For Users

Even if you don’t code, your insights can help improve the project. If you experience unexpected behavior, errors, or missing functionality, submit a
bug or feature request in the project's issue tracker.

### For Developers

If you code, we'd love your contributions! Please read the [Contribution Guidelines](CONTRIBUTING.md) for more details.

## Links

- Sodium [GitHub](https://github.com/PSModule/Sodium) | [PSGallery](https://www.powershellgallery.com/packages/Sodium)
