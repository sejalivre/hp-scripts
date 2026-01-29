# HP Scripts - Project Skills & Requirements

## Scope
This project contains scripts for IT technicians to automate maintenance, repair, and configuration of modern Windows systems (Windows 10 and 11).

## Operating System Support

### Supported Versions
The scripts are designed and tested to work on:
- **Windows 10**: All versions (1507 to 22H2).
- **Windows 11**: All versions.
- **Windows Server**: 2016, 2019, and 2022.

### Unsupported Versions
- **Legacy OS**: Systems older than Windows 10 are not supported. This project leverages modern security and PowerShell standards found only in Windows 10/11.

## Development Guidelines
- **PowerShell Compatibility**: Target **PowerShell 5.1** (Windows PowerShell) or **PowerShell 7+**.
- **Encoding**: UTF-8 with BOM is recommended for broad character compatibility, but no longer strictly required for legacy PowerShell 2.0.
- **Modern Tools**: Leverage modern Windows components like `winget`, `dism`, and advanced PowerShell modules.
- **CI/CD**: The `ci.yml` validates code quality and syntax for modern PowerShell environments.
