Wrapped Tapered Spiral Surfacing Toolpath
====================================

This release package is a safe, renamed gadget folder derived from Vectric's Wrapped Spiral Layout gadget.

Important: this package is currently the release scaffold/renamed clone. It is intended as the base for the tapered-spindle changes. Install and verify that it appears as a separate gadget before adding geometry changes.

Installation
------------

1. Unzip this archive.
2. Copy the top-level folder named Wrapped_Tapered_Spiral_Surfacing_Toolpath into your Vectric Gadgets folder, for example:

   Public Documents\Vectric\VCarve Pro\V12.0\Gadgets\

   or the equivalent Gadgets folder for your installed Vectric product/version.
3. Restart VCarve.
4. Open a wrapped rotary job.
5. Run Gadgets > Wrapped Tapered Spiral Surfacing Toolpath.

Do not overwrite the original Spiral_Layout gadget.

What is included
----------------

- Wrapped_Tapered_Spiral_Surfacing_Toolpath.lua: renamed main Lua gadget file.
- Wrapped_Tapered_Spiral_Surfacing_Toolpath/: renamed dialog/resources folder.
- README.txt: this file.
- CHANGELOG.txt: release history.
- LICENSE.txt: original permission notice and alteration note.

Release notes
-------------

This release changes the gadget identity only: folder name, Lua filename, dialog title, registry key, HTML path, and visible HTML title. Geometry behavior should still match the original Wrapped Spiral Layout gadget until tapered-geometry code is added.
