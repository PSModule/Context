# Context

Modules typically handle two types of data that benefit from persistent secure storage and management: module settings and user settings and secrets.
This module introduces the concept of `Contexts`, which store data locally on the machine where the module runs. It allows module developers to
separate user and module data from the module code, enabling users to resume their work without needing to reconfigure the module or log in again,
provided the service supports session refresh mechanisms (e.g., refresh tokens).

The module uses NaCl-based encryption, provided by the `libsodium` library, to encrypt and decrypt `Context` data. The module that delivers this
functionality is called [`Sodium`](https://github.com/someuser/Sodium) and is a dependency of this module. The
[`Sodium`](https://github.com/someuser/Sodium) module is automatically installed when you install this module.

## What is a `Context`?

A `Context` is a way to securely persist user and module state on disk while ensuring data remains encrypted at rest. It stores structured data that
can be represented in JSON format, including regular values, arrays, objects and `SecureString`. It can hold multiple secrets (such as passwords or
API tokens) alongside general data like configuration settings, session metadata, or user preferences. `SecureStrings` are specially handled to
maintain their security when stored and retrieved.

When saving a `Context`, data is first structured as plain-text JSON, then encrypted and stored on disk. `SecureStrings` are marked with a special
prefix before encryption, ensuring they can be safely restored as secure strings when the `Context` is loaded back into memory.

When imported, the encrypted data is decrypted, converted back into its original structured format, and held in memory, ensuring both usability and
security.

<details>
<summary> 1. Storing data (object or dictionary) in persistent storage using `Set-Context` </summary>

<p>
Typically, the first input to a `Context` is an object (though it can also be a hashtable or any other type that converts to JSON).
</p>

```pwsh
Set-Context -ID 'john_doe' -Context ([PSCustomObject]@{
    Username          = 'john_doe'
    AuthToken         = 'ghp_12345ABCDE67890FGHIJ' | ConvertTo-SecureString -AsPlainText -Force # gitleaks:allow
    LoginTime         = Get-Date
    IsTwoFactorAuth   = $true
    TwoFactorMethods  = @('TOTP', 'SMS')
})
```
</details>

<details>
<summary> 2. The context after preparing it for saving to file. </summary>

<p>
This is how the context object above is prepared before being encrypted and stored on disk. Notice that the `ID` property gets added.
</p>

```json
{
    "ID": "john_doe",
    "Username": "john_doe",
    "AuthToken": "[SECURESTRING]ghp_12345ABCDE67890FGHIJ",
    "LoginTime": "2024-11-21T21:16:56.2518249+01:00"
}
```
</details>

<details>
<summary> 3. How the data is ultimately stored – as processed JSON </summary>

<p>
This is how the context object above is stored after being encrypted.
</p>

```json
{
  "ID": "PSModule.GitHub/github.com/octocat",
  "Path": "C:\\Users\\MyUser\\.contextvault\\d2edaa6e-95a1-41a0-b6ef-0ecc5d116030.json",
  "Context": "0kGmtbQiEtih7 --< encrypted context data >-- ceqbMiBilUvEzO1Lk"
}
```
</details>

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
as part of the loading section in the module code. The module configuration is stored in `ContextVault` under the ID `GitHub`.

### User Configuration

To store user data, a module developer can create a `Context` that serves as a "namespace" for user-specific configurations.

Imagine a user named `BobMarley` logs into the `GitHub` module. The following would exist in `ContextVault`:

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

- Sodium [GitHub](https://github.com/someuser/Sodium) | [PSGallery](https://www.powershellgallery.com/packages/Sodium)
