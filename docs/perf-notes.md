# Performance Notes

## 2026-05-29 tapered first-pass depth

Observation from Windows/VCarve testing:

- With rotary job setup diameter at 1.3 inches and taper start diameter at 1.25 inches, the first tapered pass could cut at or near the machine/job setup diameter instead of immediately cutting toward the requested taper.
- That behavior wastes toolpath time because it traces an air/surface pass above the largest requested taper diameter when the selected tool stepdown would allow cutting to the start diameter.

Cause:

- `GetTaperedPassOffsets` calculated radial stock from the blank/outer radius down to the smallest taper endpoint.
- The resulting first `pass_offset` could keep the larger endpoint at the job setup diameter, especially when the end diameter was smaller than the start diameter.
- The taper path then behaved as if the smaller endpoint controlled the first roughing layer everywhere along the axis.

Change:

- `GetTaperedPassOffsets` now calculates roughing stock down to the largest taper endpoint plus allowance.
- When tool stepdown allows the stock removal, the first tapered pass has `pass_offset = 0.0` and cuts directly to the requested start/end taper surface.
- If stepdown does not allow the full stock removal, intermediate passes still occur, but they begin cutting toward the largest requested taper diameter rather than following the job setup diameter.

Expected behavior:

- Equal start/end diameter equal to job setup diameter still routes through the original Create Rounding Toolpath code for radial/raster/optimized.
- Non-equal taper passes no longer intentionally include a surface pass at the job setup diameter.
- Optimized non-equal taper still performs the staged strategy: original optimized rough to `max(start diameter, end diameter)`, then tapered raster finish.

## 2026-05-29 start/end offsets

- Added `Offset from Start` and `Offset from End`, matching the Spiral/Fluting gadget semantics.
- Validation rejects negative offsets and rejects combined offsets greater than the cylinder length.
- Tapered raster/radial paths now start at `offset_from_start` and end at `cylinder_length - offset_from_end`.
- Tapered spiral uses the same effective axial length for pitch/turn count and samples taper Z at the actual offset axis positions.
- Original Create Rounding Toolpath code remains in use only when start/end diameters equal the job setup diameter and both offsets are zero.

## 2026-05-29 spiral twist direction

- Added `Right` and `Left` twist choices for Spiral mode, matching the Wrapping Spiral gadget controls.
- The twist controls are disabled unless Spiral machining is selected.
- Tapered spiral now emits one contour set per selected twist direction.
- Direction sign follows the Wrapping Spiral gadget convention for cylinders along X vs Y.

## 2026-05-29 blank defaults from job setup

- On gadget startup, when a wrapped rotary job is open, both square blank size and round blank diameter are initialized from the job setup cylinder diameter.
- This keeps the round-stock field aligned with the square-stock field and the machine/job setup diameter before the dialog is shown.

## 2026-05-29 spiral pitch vs spacing

- Added the Wrapping Spiral gadget's `Use Spiral Pitch or Spacing` UI, with Spiral Pitch first and Spacing between strands second.
- Pitch/spacing controls are disabled unless Spiral machining mode is selected.
- Spiral Pitch is treated as axial distance per revolution.
- Spacing between strands is converted to an axial pitch using the cylinder circumference so the requested perpendicular strand spacing drives the generated helix.
