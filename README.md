# VCarve Tapered Spiral Gadget

Starter repository for a Vectric VCarve gadget named **Tapered Spiral Surfacing Toolpath**.

This repository currently contains a safely renamed scaffold based on the Vectric Spiral Layout gadget structure. It is intended to install separately from the original gadget. At this stage, it preserves the original wrapped spiral layout behavior and is ready for incremental development.

## Repository layout

```text
Tapered_Spiral_Surfacing_Toolpath/
  Tapered_Spiral_Surfacing_Toolpath.lua
  Tapered_Spiral_Surfacing_Toolpath.txt
  Tapered_Spiral_Surfacing_Toolpath/
    Tapered_Spiral_Surfacing_Toolpath.htm
    *.png
    vr.gif
.github/
  workflows/
    build-gadget.yml
```

## Manual installation

Copy the `Tapered_Spiral_Surfacing_Toolpath` folder into your Vectric Gadgets folder, then restart VCarve.

Typical location:

```text
Public Documents\Vectric\VCarve Pro\Gadgets\
```

## Automated packaging

The GitHub Actions workflow builds both:

```text
Tapered_Spiral_Surfacing_Toolpath_<version>.zip
Tapered_Spiral_Surfacing_Toolpath_<version>.vgadget
```

On ordinary pushes, these are uploaded as workflow artifacts.

On version tags such as `v1.0.0`, the workflow also creates a GitHub Release and attaches both files.

## Development note

The immediate next development step is to add editable start and end diameter fields to the UI, then replace the current straight-line spiral geometry with sampled tapered/conical spiral geometry.


## Vectric install location

The packaged gadget payload is intentionally rooted under:

```text
Wrapping/
  Tapered_Spiral_Surfacing_Toolpath/
    Tapered_Spiral_Surfacing_Toolpath.lua
    Tapered_Spiral_Surfacing_Toolpath/
      Tapered_Spiral_Surfacing_Toolpath.htm
      *.png
```

This mirrors the built-in Vectric wrapping gadgets so the gadget appears under the Wrapping group as **Tapered Spiral Surfacing Toolpath**.
