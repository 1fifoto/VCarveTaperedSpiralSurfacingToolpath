# VCarve Tapered Spiral Surfacing Toolpath

Starter repository for a Vectric VCarve gadget named **Wrapped Tapered Spiral Surfacing Toolpath**.

This repository contains a renamed scaffold derived from the Vectric Wrapped Spiral Layout gadget structure. The current focus is evolving the gadget into a true tapered spiral surfacing toolpath generator for rotary CNC applications such as pool cue machining.

## Repository layout

```text
Wrapped_Tapered_Spiral_Surfacing_Toolpath/
  Wrapped_Tapered_Spiral_Surfacing_Toolpath.lua
  Wrapped_Tapered_Spiral_Surfacing_Toolpath.txt
  Wrapped_Tapered_Spiral_Surfacing_Toolpath/
    Wrapped_Tapered_Spiral_Surfacing_Toolpath.htm
    *.png
```

## Manual installation

Install using:

```text
Gadgets → Install Gadget
```

and select the generated `.vgadget` file.

Alternatively, manually copy:

```text
Wrapped_Tapered_Spiral_Surfacing_Toolpath/
```

into the Vectric Gadgets directory.

Typical location:

```text
C:\Users\Public\Documents\Vectric Files\Gadgets\
```

## Automated packaging

GitHub Actions automatically builds:

```text
Wrapped_Tapered_Spiral_Surfacing_Toolpath_<version>.vgadget
```

On ordinary pushes, these are uploaded as workflow artifacts.

On version tags such as:

```text
v1.0.0
```

the workflow also creates a GitHub Release and attaches the `.vgadget` file.

## Local NAS packaging

To build a local gadget package and copy it to the shared NAS mounted on macOS:

```text
scripts/build-vgadget.sh
```

By default, the script copies the `.vgadget` file and Windows uninstall helper to:

```text
/Volumes/Shared Data/Projects/Design-and-Making/PConklin
```

To copy to a different folder, pass the destination path:

```text
scripts/build-vgadget.sh "/Volumes/Shared Data/Projects/Design-and-Making/PConklin"
```

The script writes the local package to `dist/` and copies the `.vgadget` file plus `uninstall-windows-gadget.bat` to the NAS destination when it exists.

## Windows uninstall helper

Before installing a fresh gadget build in VCarve, close VCarve and run this helper on Windows:

```text
uninstall-windows-gadget.bat
```

The local packaging script copies this helper to the PConklin NAS directory so it can be run from Windows. It removes only the installed VCarve Pro Trial Edition V12.5 gadget folder.

## Current development status

Current implemented work:
- Renamed standalone gadget scaffold
- Automated GitHub Actions packaging
- `.vgadget` generation
- Start Diameter UI field
- End Diameter UI field
- Angular Step UI field

Current in-progress work:
- Continuous tapered spiral geometry generation
- True surfacing toolpath generation
- ExternalToolpath integration
- Rotary spiral surfacing strategy
- Pool cue taper machining support
