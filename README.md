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

the workflow also creates a GitHub Release and attaches both files.

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
