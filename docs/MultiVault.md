# Multi-Vault Support

The Context PowerShell module now supports multiple named vaults, allowing users to store and manage encrypted context data across distinct vaults. This feature introduces per-vault encryption keys, default vault selection, and vault management functions.

## Features

- **Multiple named vaults**: Create and manage separate vaults for different purposes
- **Per-vault encryption**: Each vault has its own unique encryption keys for security isolation
- **Default vault selection**: Set a default vault for operations when no specific vault is specified
- **Backward compatibility**: Existing single-vault setups are automatically migrated to multi-vault structure

## Vault Structure

By default, vaults are stored under `~/.contextvaults/`, with each vault having its own directory:

```
~/.contextvaults/
├── WorkVault/
│   ├── vault.shard
│   ├── api_secret.json
│   └── ssh_token.json
├── PersonalVault/
│   ├── vault.shard
│   └── personal_data.json
└── vaults.json
```

## Vault Management Commands

### New-ContextVault

Creates a new context vault.

```powershell
# Create a new vault in the default location
New-ContextVault -Name "WorkVault"

# Create a vault at a custom path
New-ContextVault -Name "PersonalVault" -Path "C:\Secrets\"
```

### Get-ContextVault

Lists all available vaults.

```powershell
# List all vaults
Get-ContextVault

# Get information about a specific vault
Get-ContextVault -Name "WorkVault"
```

### Set-CurrentVault

Sets the default vault for context operations.

```powershell
Set-CurrentVault -Name "PersonalVault"
```

### Remove-ContextVault

Removes a vault and all its contexts.

```powershell
# Remove a vault (prompts for confirmation)
Remove-ContextVault -VaultName "OldVault"

# Force removal without confirmation
Remove-ContextVault -VaultName "OldVault" -Force
```

## Context Management with Vaults

All existing context management functions now support an optional `-VaultName` parameter:

### Set-Context

```powershell
# Store context in a specific vault
Set-Context -ID "ApiKey" -Context @{ Token = "secret123" } -VaultName "WorkVault"

# Store in default vault (no VaultName specified)
Set-Context -ID "ApiKey" -Context @{ Token = "secret123" }
```

### Get-Context

```powershell
# Retrieve context from a specific vault
Get-Context -ID "ApiKey" -VaultName "WorkVault"

# Retrieve from default vault
Get-Context -ID "ApiKey"
```

### Remove-Context

```powershell
# Remove context from a specific vault
Remove-Context -ID "ApiKey" -VaultName "WorkVault"

# Remove from default vault
Remove-Context -ID "ApiKey"
```

## Backward Compatibility

- Legacy single-vault setups (using `~/.contextvault/`) are automatically detected and migrated
- The legacy vault becomes the "default" vault in the new multi-vault structure
- All existing scripts continue to work without modification
- If no vault is specified in commands, the default vault is used

## Use Cases

### Individual Users

- Separate work and personal contexts:
  ```powershell
  New-ContextVault -Name "Work"
  New-ContextVault -Name "Personal"
  
  Set-Context -ID "GitHubWork" -Context @{ Token = "work_token" } -VaultName "Work"
  Set-Context -ID "GitHubPersonal" -Context @{ Token = "personal_token" } -VaultName "Personal"
  ```

### Module Developers

- Create module-specific vaults with different security requirements:
  ```powershell
  New-ContextVault -Name "MyModule"
  Set-Context -ID "ModuleConfig" -Context @{ Setting = "value" } -VaultName "MyModule"
  ```

## Security Considerations

- Each vault has unique encryption keys, preventing cross-vault decryption
- Vaults do not share private keys, reducing the blast radius of key compromise
- Per-vault encryption enables different security policies for different data types

## Migration

When upgrading from a single-vault setup:

1. The existing vault at `~/.contextvault/` is detected
2. It's automatically moved to `~/.contextvaults/default/`
3. The "default" vault is created and set as the current vault
4. All existing contexts remain accessible without changes
5. The migration is transparent to existing scripts and users