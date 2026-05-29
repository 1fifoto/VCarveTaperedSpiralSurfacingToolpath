Wrapped Tapered Spiral Surfacing Toolpath
====================================

This release package is a safe, renamed gadget folder derived from Vectric's Wrapped Spiral Layout gadget.

Important: this package is currently the release scaffold/renamed clone. It is intended as the base for the tapered-spindle changes. Install and verify that it appears as a separate gadget before adding geometry changes.

Installation
------------

1. Start VCarve.
1. Goto Gadgets > Install New Gadget...
2. Select file named wither Wrapped_Tapered_Spiral_Surfacing_Toolpath_local.vgadgets or Wrapped_Tapered_Spiral_Surfacing_Toolpath_dev-<commit>.vgadgets
3. Restart VCarve.
4. Open a wrapped rotary job.
5. Run Gadgets > Wrapped Tapered Spiral Surfacing Toolpath.

What is included
----------------

- Wrapped_Tapered_Spiral_Surfacing_Toolpath.lua: renamed main Lua gadget file.
- Wrapped_Tapered_Spiral_Surfacing_Toolpath.htm and images: dialog/resources files.
- README.txt: this file.
- CHANGELOG.txt: release history.
- LICENSE.txt: original permission notice and alteration note.

Release notes
-------------

This release changes the gadget identity only: folder name, Lua filename, dialog title, registry key, HTML path, and visible HTML title. Geometry behavior should still match the original Wrapped Spiral Layout gadget until tapered-geometry code is added.
