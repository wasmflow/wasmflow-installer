# Wasmflow installer

These install scripts simplify installation from github releases.

`install.sh` runs with bash and works on linux and mac operating systems.

`install.ps1` runs with Powershell and works on Windows operating systems.

Both of them:

- Test the local system for an existing version of the installed release.
- Download a suitable OS-arch archive from the github releases for the target org/project (e.g. wasmflow/wasmflow).
- Extract the archive with OS-suitable unpackers.
- Copy the archive contents to a local system directory (e.g. ~/.{project_name}/bin or c:\{project_name})
- Provide instructions or automatically add the destination bin dir to $PATH/%PATH%

# How to use

## Windows

```sh
powershell -Command "iwr -useb https://raw.githubusercontent.com/wasmflow/wasmflow-installer/main/install.ps1 | iex"
```

## Linux/Mac

With curl:

```sh
curl -fsSL https://raw.githubusercontent.com/wasmflow/wasmflow-installer/main/install.sh | /bin/bash
```

With wget:

```sh
wget -q https://raw.githubusercontent.com/wasmflow/wasmflow-installer/main/install.sh -O - | /bin/bash
```
