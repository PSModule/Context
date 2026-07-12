# Context

Most modules work with two kinds of data that benefit from persistent, secure storage: module settings and the user's own
settings and secrets. Context provides a single, secure place to keep that data so it lives separately from your module code.
Users can pick up where they left off without reconfiguring the module or signing in again, as long as the service supports
session refresh (for example, refresh tokens).

Context data is encrypted at rest using NaCl-based encryption from the `libsodium` library, delivered through the
[`Sodium`](https://github.com/PSModule/Sodium) module. `Sodium` is installed automatically when you install this module.

## What is a context?

A `context` is a collection of data that is relevant to a specific use case, such as user settings, secrets, and module
configuration. Context stores that data securely and gives you a consistent set of commands to manage it across every module
that adopts it. Each context is identified by a unique ID, and anything that can be represented as JSON can be stored in it.

When you save a context, any `SecureString` values are handled for you: they are marked, encrypted with `Sodium`, and restored
back to `SecureString` when the context is read. `Get-ContextInfo` returns a context's metadata (its ID, vault, and storage
path) without decrypting the stored data.

## Vaults

Contexts are grouped into vaults, which are logical containers for related contexts. Vaults keep data organized when you work
with multiple users or modules, and each vault is isolated with its own encryption key and storage directory. A vault is
created automatically the first time you store a context in it.

Vaults live under `$HOME/.contextvaults/<VaultName>/`. Each vault has its own `shard` file (used for encryption) and one JSON
file per context, named with a unique GUID:

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

Contexts in different vaults are completely isolated from each other.

## Installation

Install the module from the PowerShell Gallery:

```powershell
Install-PSResource -Name Context
Import-Module -Name Context
```

## Usage

### Example: Store and retrieve a context

Store an object with `Set-Context`, then read it back with `Get-Context`. The vault is created automatically if it does not
exist, and `SecureString` values round-trip securely.

```powershell
Set-Context -ID 'john_doe' -Vault 'GitHub' -Context ([PSCustomObject]@{
    Username         = 'john_doe'
    AuthToken        = 'ghp_12345ABCDE67890FGHIJ' | ConvertTo-SecureString -AsPlainText -Force # gitleaks:allow
    LoginTime        = Get-Date
    TwoFactorMethods = @('TOTP', 'SMS')
})

Get-Context -ID 'john_doe' -Vault 'GitHub'
```

### Example: Inspect metadata without decrypting

```powershell
Get-ContextInfo -Vault 'GitHub'
```

### Example: Manage vaults and contexts

```powershell
# List every vault
Get-ContextVault

# Rename a context
Rename-Context -ID 'john_doe' -NewID 'jdoe' -Vault 'GitHub'

# Remove a single context
Remove-Context -ID 'jdoe' -Vault 'GitHub'

# Remove an entire vault and all of its contexts (use with caution)
Remove-ContextVault -Name 'GitHub'
```

## Implementing Context in your module

Use Context to give your own module persistent, secure storage for settings and user data. The simplest approach is to call
`Set-Context` with your module name as the vault; the vault is created on first use and existing encryption keys are preserved.

```powershell
Set-Context -ID 'ModuleSettings' -Vault 'MyModule' -Context @{
    DefaultApiEndpoint = 'https://api.example.com'
    TimeoutSeconds     = 30
}
```

A common pattern is to wrap the Context commands so callers never need to pass the vault parameter:

```powershell
function Set-MyModuleContext {
    param(
        [Parameter(Mandatory)] [string] $ID,
        [Parameter(Mandatory)] [object] $Context
    )
    Set-Context -ID $ID -Vault 'MyModule' -Context $Context
}

function Get-MyModuleContext {
    param([string] $ID = '*')
    Get-Context -ID $ID -Vault 'MyModule'
}
```

Key points to keep in mind:

- Every context lives in a named vault — there is no default vault.
- `Set-Context` creates vaults automatically and preserves existing encryption keys.
- Use your module name as the vault name to keep related contexts together.
- Store module-wide settings separately from per-user data.
- `SecureString` values are encrypted and decrypted for you.

## Documentation

Documentation is published at [psmodule.io/Context](https://psmodule.io/Context/).

Use PowerShell help and command discovery for module details:

```powershell
Get-Command -Module Context
Get-Help -Name Get-Context -Examples
```
