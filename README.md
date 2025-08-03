# Tylex for Windows

A simple, fast, and powerful text expansion utility for Windows.

Tylex lets you create short abbreviations (e.g., `em`) that expand into longer phrases or snippets of text (e.g., youremail@example.com). It's built with PowerShell and AutoHotkey, making it lightweight, transparent, and easy to customize.

---

## Features

  * **Fast & Lightweight:** No heavy dependencies or background processes. Just simple, efficient scripts.
  * **Simple UI:** Uses a built-in, filterable grid view that's quick and effective.
  * **Usage-Aware:** Automatically sorts your most frequently used expansions to the top.
  * **Customizable Hotkeys:** Easily change the hotkeys by editing the simple `TylexLauncher.ahk` script.
  * **Open & Transparent:** The entire codebase is made of readable PowerShell and AutoHotkey scripts.
  * **Easy to Package:** Comes with a powerful build script to compile, install, and even generate `winget` packages.

---

## Installation

You can install Tylex using one of the following methods. For most users, `winget` is the recommended choice.

### Method 1: Windows Package Manager (winget)

This is the easiest way to install Tylex. Open a Command Prompt or PowerShell terminal and run:

```sh
winget install RAOEUS.Tylex
```
### Method 2: Build from Source

If you want to modify the scripts or contribute to development, you can build the project directly from the source code. See the **[Building from Source](#building-from-source)** section below for detailed instructions.

---

## How to Use

Once installed, Tylex runs in the background. Use the following default hotkeys:

  * **`Win + z`**: **Expand Text**

      * Opens a searchable list of your saved expansions.
      * Start typing any part of the abbreviation or the expansion to filter the list.
      * Press `Enter` to select, and the full text will be typed out instantly.

  * **`Win + Shift + z`**: **Add New Expansion**

      * Opens a prompt asking for the new abbreviation (the "key").
      * Opens a second prompt asking for the full text it should expand to (the "value").

Your expansions are saved in a simple `expansions.json` file located in `%LOCALAPPDATA%\Tylex`.

---

## Building from Source

The `Build.ps1` script is the all-in-one tool for managing the project. It allows you to set up your environment, compile executables, install the application locally, and even package it for distribution.

### Step 1: Set Up the Build Environment

Before you can build the project, you need the necessary tools: **AutoHotkey** and the PowerShell module **`PS2EXE`**. The `setup` target automates this for you.

Open an **Administrator PowerShell** terminal in the project's root directory and run:

```powershell
.\Build.ps1 -Target setup
```

This command will use `winget` to install AutoHotkey and `Install-Module` to add `PS2EXE`, getting your environment ready in one step.

### Step 2: Use the Build Targets

Once your environment is set up, you can use the following targets with the `Build.ps1` script.

  * #### `build`

    Builds the PowerShell and AutoHotkey scripts into `.exe` files. The compiled executables are placed in a `build` folder.

    ```powershell
    .\Build.ps1 -Target build
    ```

  * #### `install`

    Compiles the application and installs it on your system. This copies the files to `C:\Program Files\Tylex` and adds a shortcut to your Startup folder so it runs automatically on login. **(Requires Administrator)**

    ```powershell
    .\Build.ps1 -Target install
    ```

  * #### `uninstall`

    Removes the application from your system by deleting the installation directory and the startup shortcut. **(Requires Administrator)**

    ```powershell
    .\Build.ps1 -Target uninstall
    ```

  * #### `winget`

    Generates the necessary YAML manifest files for submitting the application to the Windows Package Manager repository. This target first builds the project, zips the release files, calculates the SHA256 hash, and then creates the manifest files in a `winget-manifest` folder.

    This target requires two additional parameters:

      * `-ReleaseUrl`: The direct public URL to your `.zip` release package (e.g., from a GitHub Release).
      * `-PackageVersion`: The version number for the release (e.g., "1.0.1").

    **Example:**

    ```powershell
    .\Build.ps1 -Target winget -ReleaseUrl "https://github.com/RAOEUS/Tylex/releases/download/v1.0.0/Tylex-1.0.0.zip" -PackageVersion "1.0.0"
    ```

---

## License

This project is distributed under the MIT License. See the `LICENSE` file for more information.
