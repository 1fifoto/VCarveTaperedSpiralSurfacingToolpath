-- VECTRIC LUA SCRIPT
-- ALTERED SOURCE VERSION: Create Tapered Rounding Toolpath.
-- Based on Vectric Create Rounding Toolpath, with taper and spiral support added.
-- Copyright 2013 Vectric Ltd.

-- Gadgets are an entirely optional add-in to Vectric's core software products.
-- They are provided 'as-is', without any express or implied warranty, and you make use of them entirely at your own risk.
-- In no event will the author(s) or Vectric Ltd. be held liable for any damages arising from their use.

-- Permission is granted to anyone to use this software for any purpose,
-- including commercial applications, and to alter it and redistribute it freely,
-- subject to the following restrictions:

-- 1. The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation would be appreciated but is not required.
-- 2. Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
-- 3. This notice may not be removed or altered from any source distribution.

--[[ History
| Who       When       Version What
| ======    ========== ======= ============================================================================================
| BrianM    17/11/2009 V1.1    Use g_cylinder_diameter for calculating toolpath dimesnions rather than document size as may be wrapped multiple times
| BrianM    19/02/2012 V1.11   Update for VectricJob
| GrzegorzK 12/02/2018 v1.2    Update to take advantage of new rotary implementation
| GrzegorzK 01/05/2018 v1.3    Update to remove orientation change from the UI and make job size read-only
| GrzegorzK 30/05/2018 v1.4    Update to replace read-only edit boxes with static text
| MohamedM  18/09/2018 v1.5    Don't allow negative depths to prevent producing nan.
| MohamedM  21/08/2019 v1.6    Use ToolDBId instead of tool name
--]]

require "strict"

-- Default values for variables

g_toolpath_type = 4 -- 1 = radial, 2 = raster, 3 = optimized raster, 4 = spiral
g_square_side_len = 1.25
g_blank_diameter = 1.25
g_blank_is_square = true
g_allowance = 0.0
g_cylinder_length = 48.0
g_cylinder_diameter = 8.0
g_cylinder_along_x = true
g_start_diameter = 0.0
g_end_diameter = 0.0
g_angular_step = 2.0
g_spiral_spacing = 0.0625
g_spiral_pitch = 0.0625
g_use_spiral_pitch = false
g_offset_from_start = 0.0
g_offset_from_end = 0.0
g_create_right_twist = true
g_create_left_twist = false
g_job_min_axis = 0.0
g_job_min_cross = 0.0
g_job_wrap_circumference = 0.0


g_window_width = 740
g_window_height = 800

g_default_tool_id = ToolDBId()

g_tool = nil

g_toolpath_name = "Tapered Spiral"

g_dialog_title = "Create Tapered Rounding Toolpath"

g_version = "1.0.0"

--[[ ----------- GetUserChoices -------------------------------------
|
| Display a dialog prompting user for options for processing
|
--]]
function GetUserChoices(job, script_path, load_default_values)

   -- get our default values from the registry (values used last time we were run)
   local registry = Registry("TaperedRoundingToolpathV1")

   -- ---------------- Get default values from last run -------------------
   if load_default_values then
      g_blank_is_square      = registry:GetBool  ("BlankIsSquare",    g_blank_is_square)
      g_square_side_len      = registry:GetDouble("SquareSideLength", g_square_side_len)
      g_blank_diameter       = registry:GetDouble("BlankDiameter",    g_blank_diameter)
      g_allowance            = registry:GetDouble("Allowance",        g_allowance)

      g_toolpath_type        = registry:GetInt("ToolpathType",        g_toolpath_type)

      g_default_tool_id:LoadDefaults("TaperedRoundingToolpath", "")

      g_toolpath_name        = registry:GetString("ToolpathName",     g_toolpath_name)

      g_cylinder_length      = registry:GetDouble("CylinderLength",      g_cylinder_length)
      g_cylinder_diameter    = registry:GetDouble("CylinderDiameter",    g_cylinder_diameter)
      g_cylinder_along_x     = registry:GetBool  ("CylinderAlongX",      g_cylinder_along_x)
      g_start_diameter       = registry:GetDouble("StartDiameter",       g_start_diameter)
      g_end_diameter         = registry:GetDouble("EndDiameter",         g_end_diameter)
      g_angular_step         = registry:GetDouble("AngularStep",         g_angular_step)
      g_spiral_spacing       = registry:GetDouble("SpiralSpacing",       g_spiral_spacing)
      g_spiral_pitch         = registry:GetDouble("SpiralPitch",         g_spiral_pitch)
      g_use_spiral_pitch     = registry:GetBool  ("UseSpiralPitch",      g_use_spiral_pitch)
      g_offset_from_start    = registry:GetDouble("OffsetFromStart",     g_offset_from_start)
      g_offset_from_end      = registry:GetDouble("OffsetFromEnd",       g_offset_from_end)
      g_create_right_twist   = registry:GetBool("CreateRightTwist",      g_create_right_twist)
      g_create_left_twist    = registry:GetBool("CreateLeftTwist",       g_create_left_twist)

      g_window_width         = registry:GetInt("WindowWidth",         g_window_width)
      g_window_height        = registry:GetInt("WindowHeight",        g_window_height)
   end

   -- We don't support a job NOT being open
   if not job.Exists then
      DisplayMessageBox("A file must be loaded before this gadget is run!");
     return 0;
   end

   -- check if the job is a rotary job and retrieve its parameters
   local dims_from_job = false
   if job:IsWrappedModel() then
     local mtl_block = MaterialBlock();
     g_cylinder_along_x = mtl_block.RotationAxis == MaterialBlock.X_AXIS;
     g_cylinder_diameter = mtl_block.CylinderDiameter;
     g_cylinder_length = mtl_block.CylinderLength;
     dims_from_job = true;
   else
     DisplayMessageBox("Current job is not a wrapped rotary job!");
   end

   if dims_from_job then
      g_square_side_len = g_cylinder_diameter
      g_blank_diameter = g_cylinder_diameter
   end

   if g_start_diameter <= 0.0 or g_start_diameter > g_cylinder_diameter then
      g_start_diameter = g_cylinder_diameter
   end

   if g_end_diameter <= 0.0 or g_end_diameter > g_cylinder_diameter then
      g_end_diameter = g_cylinder_diameter
   end

   -- display our dialog to get user choices
   local html_path = "file:"..script_path.."\\Wrapped_Tapered_Spiral_Surfacing_Toolpath.htm"
   local dialog = HTML_Dialog(false, html_path, g_window_width, g_window_height, g_dialog_title)

   -- Set up units fields on form -----------------

   -- We have a job open use units from that .....
   local in_mm = job.InMM

   local units_text = "units"
   if in_mm then
      units_text = "mm"
   else
      units_text = "inches"
   end
   dialog:AddLabelField("Units1", units_text)
   dialog:AddLabelField("Units2", units_text)
   dialog:AddLabelField("Units10", units_text)
   dialog:AddLabelField("Units11", units_text)
   dialog:AddLabelField("Units12", units_text)
   dialog:AddLabelField("Units13", units_text)
   dialog:AddLabelField("Units14", units_text)
   dialog:AddLabelField("Units15", units_text)
   dialog:AddLabelField("Units16", units_text)
   dialog:AddLabelField("Units17", units_text)
   dialog:AddLabelField("Units18", units_text)

   -- connect up fields we use for getting options
   local blank_type_index = 1
   if not g_blank_is_square then
      blank_type_index = 2
   end
   dialog:AddRadioGroup("BlankShapeOptionGroup", blank_type_index)

   dialog:AddDoubleField("SquareSideLength", g_square_side_len)
   dialog:AddDoubleField("BlankDiameter", g_blank_diameter)
   dialog:AddDoubleField("Allowance", g_allowance)

   dialog:AddRadioGroup("MachiningMethodOptionGroup", g_toolpath_type)

   -- tool picking
   dialog:AddLabelField("ToolNameLabel", "No Tool Selected")
   dialog:AddToolPicker("ToolChooseButton", "ToolNameLabel", g_default_tool_id);
   -- add allowed tool types
   dialog:AddToolPickerValidToolType("ToolChooseButton", Tool.BALL_NOSE)
   dialog:AddToolPickerValidToolType("ToolChooseButton", Tool.END_MILL)
   dialog:AddToolPickerValidToolType("ToolChooseButton", Tool.RADIUSED_END_MILL)

   -- toolpath name
   dialog:AddTextField("ToolpathName",  g_toolpath_name)
   dialog:AddDoubleField("StartDiameter", g_start_diameter)
   dialog:AddDoubleField("EndDiameter",   g_end_diameter)
   dialog:AddDoubleField("AngularStep",   g_angular_step)

   local spiral_spacing_index = 2
   if g_use_spiral_pitch then
      spiral_spacing_index = 1
   end
   dialog:AddRadioGroup("SpiralSpacingOptionGroup", spiral_spacing_index)
   dialog:AddDoubleField("StrandPitch",   g_spiral_pitch)
   dialog:AddDoubleField("StrandSpacing", g_spiral_spacing)

   dialog:AddDoubleField("StrandStartOffset", g_offset_from_start)
   dialog:AddDoubleField("StrandEndOffset",   g_offset_from_end)
   dialog:AddCheckBox("CreateRightHandTwistCheck", g_create_right_twist)
   dialog:AddCheckBox("CreateLeftHandTwistCheck",  g_create_left_twist)

   -- Cylinder Dimensions - read only
   dialog:AddLabelField("CylinderLength",    tostring(g_cylinder_length))
   dialog:AddLabelField("CylinderDiameter",  tostring(g_cylinder_diameter))

   -- Gadget Version
   dialog:AddLabelField("GadgetVersion", g_version)


    -- ========== Display Dialog ========================================

   if  not dialog:ShowDialog() then
      -- DisplayMessageBox("User canceled dialog")
      return 0
   end
   -- we keep the size the user has used for the dialog widnow
   g_window_width       = dialog.WindowWidth
   g_window_height      = dialog.WindowHeight

   -- if we reach here, user pressed OK on form - get values


   -- Parameters
   g_square_side_len    = dialog:GetDoubleField("SquareSideLength")
   g_blank_diameter     = dialog:GetDoubleField("BlankDiameter")
   g_allowance          = dialog:GetDoubleField("Allowance")

   blank_type_index = dialog:GetRadioIndex("BlankShapeOptionGroup")
   if blank_type_index == 1 then
      g_blank_is_square = true
   elseif blank_type_index == 2 then
      g_blank_is_square = false
   else
      MessageBox("Unknown cblank type index from dialog " .. blank_type_index)
      return 0
   end

   g_toolpath_type = dialog:GetRadioIndex("MachiningMethodOptionGroup")
   if (g_toolpath_type < 1) or (g_toolpath_type > 4) then
      MessageBox("Unknown machining method index from dialog " .. orientation_index)
      return 0
   end

   g_start_diameter = dialog:GetDoubleField("StartDiameter")
   g_end_diameter   = dialog:GetDoubleField("EndDiameter")
   g_angular_step   = dialog:GetDoubleField("AngularStep")
   g_spiral_pitch   = dialog:GetDoubleField("StrandPitch")
   g_spiral_spacing = dialog:GetDoubleField("StrandSpacing")
   spiral_spacing_index = dialog:GetRadioIndex("SpiralSpacingOptionGroup")
   if spiral_spacing_index == 1 then
      g_use_spiral_pitch = true
   elseif spiral_spacing_index == 2 then
      g_use_spiral_pitch = false
   else
      MessageBox("Unknown spiral spacing option index from dialog " .. spiral_spacing_index)
      return 0
   end
   g_offset_from_start = dialog:GetDoubleField("StrandStartOffset")
   g_offset_from_end   = dialog:GetDoubleField("StrandEndOffset")
   g_create_right_twist = dialog:GetCheckBox("CreateRightHandTwistCheck")
   g_create_left_twist  = dialog:GetCheckBox("CreateLeftHandTwistCheck")

   if g_cylinder_length <= 0.0 then
      DisplayMessageBox("The cylinder length must be greater than 0.0")
      return -1
   end

   if g_cylinder_diameter <= 0.0 then
      DisplayMessageBox("The cylinder diameter must be greater than 0.0")
      return -1
   end

   if  g_blank_is_square then
      -- Check that square blank dimensions are valid
      if g_square_side_len <= 0.0 then
         DisplayMessageBox("The size of the square section must be greater than 0.0")
         return -1
      end


      -- size checks for taper dimensions are done below
   else
      -- Check that round blank dimensions are valid
      if g_blank_diameter <= 0.0 then
         DisplayMessageBox("The diameter of the round blank must be greater than 0.0")
         return -1
      end

      -- if user has chosen a round blank and optimised machining just set raster
      if g_toolpath_type == 3 then
         DisplayMessageBox("Optimized Raster strategy is not valid for round blanks - defaulting to Raster")
         g_toolpath_type = 2
      end
   end

   if g_start_diameter <= 0.0 then
      DisplayMessageBox("The start diameter must be greater than 0.0")
      return -1
   end

   if g_start_diameter > g_cylinder_diameter then
      DisplayMessageBox("The start diameter (" .. g_start_diameter .. ") must be equal to or less than the job setup diameter (" .. g_cylinder_diameter .. ")")
      return -1
   end

   if g_end_diameter <= 0.0 then
      DisplayMessageBox("The end diameter must be greater than 0.0")
      return -1
   end

   if g_end_diameter > g_cylinder_diameter then
      DisplayMessageBox("The end diameter (" .. g_end_diameter .. ") must be equal to or less than the job setup diameter (" .. g_cylinder_diameter .. ")")
      return -1
   end

   if g_toolpath_type == 4 and g_angular_step <= 0.0 then
      DisplayMessageBox("The angular step must be greater than 0.0 degrees")
      return -1
   end

   if g_toolpath_type == 4 and g_angular_step > 360.0 then
      DisplayMessageBox("The angular step must be 360.0 degrees or less")
      return -1
   end

   if g_toolpath_type == 4 then
      if g_use_spiral_pitch then
         if g_spiral_pitch <= 0.0 then
            DisplayMessageBox("The spiral pitch must be greater than 0.0")
            return -1
         end
      else
         if g_spiral_spacing <= 0.0 then
            DisplayMessageBox("The spacing between strands must be greater than 0.0")
            return -1
         end
         if g_spiral_spacing >= g_cylinder_diameter * math.pi then
            DisplayMessageBox("The spacing between strands must be less than the cylinder circumference")
            return -1
         end
      end
   end

   if g_offset_from_start < 0.0 then
      DisplayMessageBox("The offset from start must be zero or greater")
      return -1
   end

   if g_offset_from_end < 0.0 then
      DisplayMessageBox("The offset from end must be zero or greater")
      return -1
   end

   if ((g_offset_from_start + g_offset_from_end) > g_cylinder_length) then
      DisplayMessageBox("The start and end offsets combined must not exceed the cylinder length")
      return -1
   end

   if g_toolpath_type == 4 and (not g_create_right_twist) and (not g_create_left_twist) then
      DisplayMessageBox("You must create either a left or right twist or both")
      return -1
   end

   local max_taper_diameter = math.max(g_start_diameter, g_end_diameter) + g_allowance
   if g_blank_is_square and g_square_side_len < max_taper_diameter then
      DisplayMessageBox("The size of the square blank (" .. g_square_side_len .. ") must be equal to or greater than the largest taper diameter + allowance (" .. max_taper_diameter .. ")" )
      return -1
   end

   if (not g_blank_is_square) and g_blank_diameter < max_taper_diameter then
      DisplayMessageBox("The diameter of the round blank (" .. g_blank_diameter .. ") must be equal to or greater than the largest taper diameter + allowance (" .. max_taper_diameter .. ")" )
      return -1
   end
      -- get tool user selected
   g_tool = dialog:GetTool("ToolChooseButton");
   if g_tool == nil then
      DisplayMessageBox("No tool selected!")
      return -1
   end

   -- toolpath name
   g_toolpath_name = dialog:GetTextField("ToolpathName")
   if string.len(g_toolpath_name) < 1 then
      DisplayMessageBox("A name must be entered for the toolpath")
      return -1
   end

   -- keep name of tool as default
   g_default_tool_id = g_tool.ToolDBId


   -- save job settings as default for next time ....
   registry:SetBool  ("BlankIsSquare",  g_blank_is_square)
   if g_blank_is_square then
      registry:SetDouble("SquareSideLength",   g_square_side_len)
   else
      registry:SetDouble("BlankDiameter",   g_blank_diameter)
   end
   registry:SetDouble("Allowance",          g_allowance)
   registry:SetInt("ToolpathType",          g_toolpath_type)
   g_default_tool_id:SaveDefaults("TaperedRoundingToolpath", "")
   registry:SetString("ToolpathName",       g_toolpath_name)
   registry:SetDouble("StartDiameter",      g_start_diameter)
   registry:SetDouble("EndDiameter",        g_end_diameter)
   registry:SetDouble("AngularStep",        g_angular_step)
   registry:SetDouble("SpiralSpacing",      g_spiral_spacing)
   registry:SetDouble("SpiralPitch",        g_spiral_pitch)
   registry:SetBool  ("UseSpiralPitch",     g_use_spiral_pitch)
   registry:SetDouble("OffsetFromStart",    g_offset_from_start)
   registry:SetDouble("OffsetFromEnd",      g_offset_from_end)
   registry:SetBool("CreateRightTwist",     g_create_right_twist)
   registry:SetBool("CreateLeftTwist",      g_create_left_twist)

   registry:SetInt("WindowWidth",           g_window_width)
   registry:SetInt("WindowHeight",          g_window_height)

   if not dims_from_job then
      registry:SetDouble("CylinderLength",  g_cylinder_length)
      registry:SetDouble("CylinderDiameter",g_cylinder_diameter)
      registry:SetBool  ("CylinderAlongX",  g_cylinder_along_x)
   end

   return 1
end

--[[ ---------- CreateRasterLevelContour -----------------------------
|
| Create a raster pattern contour for a single level
|
| NOTE: raster_dir must be a unit vector
|
]]
function CreateRasterLevelContour(job, raster_dir, start_mid_point, width, length, stepover, z_value, make_even_steps, reverse_end)

   if width <= 0.0 then
      DisplayMessageBox("CreateRasterLevelContour - invalid width (" .. width .. ")")
      return nil
   end

   if length <= 0.0 then
      DisplayMessageBox("CreateRasterLevelContour - invalid length (" .. length .. ")")
      return nil
   end
   --[[
   DisplayMessageBox(
                    "CreateRasterLevelContour" ..
                    "\nlength =" .. length ..
                    "\nwidth = " .. width ..
                    "\nz_value = " .. z_value ..
                    "\nStart Point = " .. start_mid_point.x .. "," .. start_mid_point.y ..
                    "\nRaster Dir =  " .. raster_dir.x .. "," .. raster_dir.y
                    )

   ]]
   local raster_ctr = Contour(0.0);     -- use default tolerance

   -- calculate our actual stepover
   local num_lines = math.floor((width / stepover) + 0.5)
   if (num_lines < 0) then
      num_lines = 1;
   end
   if make_even_steps and ((num_lines % 2) == 1) then
      num_lines = num_lines + 1
   end

   local raster_stepover = 0.0
   if (num_lines > 1) then
      raster_stepover = width / (num_lines - 1)
   end

   -- we are passed the left hand mid point for our raster - get blc
   local raster_normal_vec = raster_dir:NormalTo()

   if reverse_end then
      raster_normal_vec = -1.0 * raster_normal_vec
   end

   local raster_start_pt = start_mid_point + ((width* 0.5) * raster_normal_vec)

   local stepover_vec = -raster_stepover * raster_normal_vec
   local raster_along_vec = length * raster_dir

   -- ready to start creating our raster

   local cur_pt = raster_start_pt
   raster_ctr:AppendPoint(cur_pt)

   for n = 1, num_lines do
      -- line along raster
      cur_pt = cur_pt + raster_along_vec
      raster_ctr:LineTo(cur_pt)
      -- stepover between rasters - not on last pass
      if n < num_lines then
         cur_pt = cur_pt + stepover_vec
         raster_ctr:LineTo(cur_pt)
      end
      -- reverse raster dir for next line
      raster_along_vec = -1.0 * raster_along_vec
   end

   -- set z value for this raster
   raster_ctr:SetZHeight(z_value)

   return raster_ctr

   end

 --[[ ----------- SetHomeZSafeZ -----------------------------------------
 |
 |Setup HomeZ and SafeZ dfor the current settings
 |
 ]]
 function SetHomeZSafeZ(pos_data, mtl_block)

   -- ensure that homez is in a safe position

   local outer_rad = 0.0
   if g_blank_is_square then
      local square_side_rad = g_square_side_len * 0.5
      outer_rad = math.sqrt((square_side_rad * square_side_rad) + (square_side_rad * square_side_rad))
   else
      outer_rad = g_blank_diameter * 0.5
   end

   local home_z = outer_rad + pos_data.SafeZGap

   local wrap_radius = mtl_block.Thickness

   local origin_on_surface = false
   if mtl_block.ZOrigin == MaterialBlock.Z_TOP then
      home_z = home_z - mtl_block.Thickness
      origin_on_surface = true
      -- DisplayMessageBox("Z Orign On Top\nHome_z = " ..  home_z .. "\nSafe Z Gap = " .. pos_data.SafeZGap)
   end

   --[[
   if home_z <= mtl_block.Thickness + z_range then
      if mtl_block.InMM then
         home_z = mtl_block.Thickness + z_range + 5
      else
         home_z = mtl_block.Thickness + z_range + 0.2
      end
   end
   ]]
   pos_data:SetHomePosition(
                            pos_data.HomeX,
                            pos_data.HomeY,
                            home_z
                            )

   -- home_z = mtl_block:CalcAbsoluteZ(-home_z)

   local blank_thickness = outer_rad - wrap_radius

   --[[
   if not origin_on_surface then
      if pos_data.SafeZGap <= mtl_block.Thickness + z_range then
         if mtl_block.InMM then
            pos_data.SafeZGap = z_range + 2.5
         else
             pos_data.SafeZGap = z_range + 0.1
         end
         -- pos_data.SafeZGap = pos_data.SafeZGap + mtl_block.Thickness
      end
   end
   ]]
   -- SafeZ gap is relative to the material surface, we want it realtive to
   -- the 'blank' surface which is an extra blank_thickness
   pos_data.SafeZGap = pos_data.SafeZGap + blank_thickness
   -- Ensure startz and safez are same value
   pos_data.StartZGap = pos_data.SafeZGap

 end

 --[[ ----------- CreateToolpath -----------------------------------------
 |
 | Create a toolpath from the passe ddata
 |
 |
 ]]
function CreateToolpath(job, toolpath_name, vectors)

      -- Create object used to set home position and safez gap above material surface
   local pos_data = ToolpathPosData()

   local mtl_block = MaterialBlock()

   SetHomeZSafeZ(pos_data, mtl_block)

    -- object used to pass data on toolpath settings
   local toolpath_options = ExternalToolpathOptions()
   toolpath_options.StartDepth = 0.0
   toolpath_options.CreatePreview = false

   -- Create our toolpath
   local toolpath = ExternalToolpath(
                                    toolpath_name,
                                    g_tool,
                                    pos_data,
                                    toolpath_options,
                                    vectors
                                    )

   if toolpath:Error() then
      DisplayMessageBox("Error creating toolpath")
      return nil
   end

   local toolpath_manager = ToolpathManager()
   toolpath_manager:AddExternalToolpath(toolpath)

   return toolpath

end

--[[ ----------- CreateSimpleCylinderRasterContours ------------------------
|
| Create contours for rastering between cylinders of passed diameters
|
]]
function CreateSimpleCylinderRasterContours(job, along_axis, outer_rad, inner_rad, allowance, raster_group, tool)

   local stepdown = tool.Stepdown
   stepdown = tool:ConvertValueToUnits(stepdown, job.InMM)

   local stepover = tool.Stepover
   stepover = tool:ConvertValueToUnits(stepover, job.InMM)

   -- calculate number of steps in z
   local z_range = outer_rad - (inner_rad + allowance)

   local num_z_steps = math.floor((z_range / stepdown) + 0.5)
   -- if we have more than 20% of stepdown left over increase number of steps
   if ((z_range - (stepdown * num_z_steps)) > (stepdown * 0.2)) then
      num_z_steps = num_z_steps + 1;
   end
   if num_z_steps < 1 then
     num_z_steps = 1
   end
   local z_step = z_range / num_z_steps

   -- set up directions an size of area to raster - this will differ depending on orientation
   local raster_dir = Vector2D(1.0, 0.0)
   local start_mid_point = Point2D(job.MinX, job.MinY + job.YLength / 2)

   local cyl_circumference = g_cylinder_diameter * math.pi

   local raster_width = cyl_circumference
   local raster_length = g_cylinder_length
   local use_variable_stepover = along_axis
   -- dont use variable stepover for spiral machining

   local raster_along_x = true

   if g_cylinder_along_x then
      if along_axis then
         raster_along_x = true
         raster_width  = cyl_circumference
         raster_length = g_cylinder_length
         start_mid_point:Set(job.MinX, job.MinY + cyl_circumference * 0.5)
         raster_dir = Vector2D(1.0, 0.0)
      else
         raster_along_x = false
         raster_width  = g_cylinder_length
         raster_length = cyl_circumference
         start_mid_point:Set(job.MinX  + g_cylinder_length * 0.5 , job.MinY )
         raster_dir:Set(0.0, 1.0)
      end
   else -- cylinder along y
      if along_axis then
         raster_along_x = false
         raster_width  = cyl_circumference
         raster_length = g_cylinder_length
         start_mid_point:Set(job.MinX  + cyl_circumference * 0.5 , job.MinY)
         raster_dir:Set(0.0, 1.0)
      else
         raster_along_x = true
         raster_width  = g_cylinder_length
         raster_length = cyl_circumference
         start_mid_point:Set(job.MinX, job.MinY + g_cylinder_length * 0.5)
         raster_dir = Vector2D(-1.0, 0.0)
      end
   end
   --[[
   if raster_along_x then
      DisplayMessageBox("Rastering along x")
   else
      DisplayMessageBox("Rastering along y")
    end
   if along_axis then
      DisplayMessageBox("Rastering along axis")
   else
      DisplayMessageBox("NOT Rastering along axis")
   end
   ]]

   local reverse_dir = true  -- used to swap direction of rasters for radial machining
   -- we create our z levels from the outside in
   local cur_z = z_range - z_step + allowance
   if num_z_steps == 1 then
      cur_z = allowance
   end
--[[
   DisplayMessageBox(
         "Allowance = " .. allowance .. "\nInner Rad = " .. inner_rad .. "\nOuter Rad = " .. outer_rad ..
         "\nz_range = " ..  z_range .. "\nNum Steps = " .. num_z_steps .. "\nz_step = " .. z_step .. "\ncur_z = " .. cur_z ..
         "\nraster_length = " ..  raster_length .."\nwidth = " .. raster_width
         )
         --]]

   for zlevel = 1, num_z_steps  do
      -- because we wrap on the inner_rad, toolpaths on higher z level will be stretched out
      -- therefore we adjust the stepover on each level so that when wrapped they will maintain
      -- a constant stepover - if we are machining radialy stepover remains constant

      local adj_stepover = stepover
      if use_variable_stepover then
         local radius_scale_factor = (inner_rad + cur_z) / inner_rad
         adj_stepover = stepover / radius_scale_factor
      end

      local raster_ctr = CreateRasterLevelContour(job, raster_dir, start_mid_point, raster_width, raster_length, adj_stepover, cur_z, true, false)
      if raster_ctr == nil then
         DisplayMessageBox("Error creating raster contour for z level " .. cur_z)
         return false
      end

      -- Reverse alternate layers to avoid long join ups
      if  reverse_dir then
         raster_ctr:Reverse()
      end

      -- last raster cant join to next one
      if (zlevel < num_z_steps) then
         raster_ctr:SetCanJoinToParent(true)
      end

      raster_group:AddTail(raster_ctr)

      reverse_dir = not reverse_dir
      cur_z = cur_z - z_step
   end

   return true
end

--[[ ------------- CreateSimpleRasterToolpath -----------------------------------
|
|  Create a raster toolpath for machining blank as two cylinders
|
]]
 function CreateSimpleRasterToolpath(job, along_axis)

   local outer_rad  = 0.0
   if g_blank_is_square then
      local square_side_rad = g_square_side_len * 0.5
      outer_rad = math.sqrt((square_side_rad * square_side_rad) + (square_side_rad * square_side_rad))
   else
      outer_rad = g_blank_diameter * 0.5
   end
   local inner_rad = g_cylinder_diameter * 0.5
   local z_range = outer_rad - inner_rad

   local raster_group = ContourGroup(true)  -- this will own contours in it

   if not CreateSimpleCylinderRasterContours(job, along_axis, outer_rad, inner_rad, g_allowance, raster_group, g_tool) then
      return false
   end


   if not CreateToolpath(job, g_toolpath_name, raster_group) then
      return false
   end

   return true

   end


--[[ ------------- CreateOptimisedRasterToolpath -----------------------------------
|
|  Create a raster toolpath for machining blank - removing the corners first
|
]]
 function CreateOptimisedRasterToolpath(job, along_axis)

   local outer_rad = g_square_side_len * 0.5
   local corner_rad = math.sqrt((outer_rad * outer_rad) + (outer_rad * outer_rad))
   local inner_rad = g_cylinder_diameter * 0.5

   local stepdown = g_tool.Stepdown
   stepdown = g_tool:ConvertValueToUnits(stepdown, job.InMM)

   local stepover = g_tool.Stepover
   stepover = g_tool:ConvertValueToUnits(stepover, job.InMM)

   -- calculate number of steps in z to machine off corners
   local z_range = corner_rad - outer_rad

   local z_offset = outer_rad - inner_rad

   local num_z_steps = math.floor((z_range / stepdown) + 0.5)
   -- if we have more than 20% of stepdown left over increase number of steps
   if ((z_range - (stepdown * num_z_steps)) > (stepdown * 0.2)) then
      num_z_steps = num_z_steps + 1;
   end
   if num_z_steps < 1 then
      num_z_steps = 1
   end
   local z_step = z_range / num_z_steps

   --[[
   DisplayMessageBox(
                    "z_range = " .. z_range ..
                    "\ncorner rad = " .. corner_rad ..
                    "\nouter_rad = " .. outer_rad ..
                    "\ninner_rad = " .. inner_rad ..
                    "\nnum_z_steps = " .. num_z_steps ..
                    "\nz_step = " .. z_step ..
                    "\njob.YLength = " .. job.YLength ..
                    "\njob.XLength = " .. job.XLength
                    )
   ]]
   local raster_group = ContourGroup(true)  -- this will own contours in it

   local use_variable_stepover =  true
   local raster_along_x = g_cylinder_along_x

   if not along_axis then
     raster_along_x = not raster_along_x
   end

   -- 'width' of area we are working on is always the wrapping circumference
   local wrap_circumference = g_cylinder_diameter * math.pi
   local width = wrap_circumference -- NOTE: this changes as we move away from surface

   local length = job.XLength
   if not g_cylinder_along_x then
      length = job.YLength
   end

   local raster_dir = Vector2D(1.0, 0.0)
   if not raster_along_x then
      raster_dir:Set(0.0, 1.0)
      length = job.YLength
   end

   local corner_offset= {}
   corner_offset[1] = 0.125   -- 1
   corner_offset[2] = 0.625   -- 3
   corner_offset[3] = 0.375   -- 2
   corner_offset[4] = 0.875   -- 4

   local do_corners_in_sequence = true
   if do_corners_in_sequence then
      corner_offset[1] = 0.125   -- 1
      corner_offset[2] = 0.375   -- 2
      corner_offset[3] = 0.625   -- 3
      corner_offset[4] = 0.875   -- 4
   end


   -- we do each corner in turn

   for corner_index = 1, 4 do

      local corner_offset_ratio = corner_offset[corner_index]

      -- set up directions and size of area to raster - this will differ depending on orientation
      local start_mid_point = Point2D(
                                     job.MinX,
                                     job.MinY + (wrap_circumference * corner_offset_ratio)
                                     )


      if not raster_along_x then
         start_mid_point:Set(
                            job.MinX + (wrap_circumference * corner_offset_ratio),
                            job.MinY
                            )
      end

      -- DisplayMessageBox("start_mid_point = " .. start_mid_point.x .. "," .. start_mid_point.y)

      local reverse_dir = false  -- used to swap direction of rasters for radial machining and end of each level pass
      -- we create our z levels from the outside in
      local cur_z = z_range

      for zlevel = 1, num_z_steps  do

         cur_z = cur_z - z_step
         if cur_z < 0 then
            cur_z = 0
         end

         -- because we wrap on the inner_rad, toolpaths on higher z level will be stretched out
         -- therefore we adjust the stepover on each level so that when wrapped they will maintain
         -- a constant stepover - if we are machining radialy stepover remains constant


         local adj_stepover = stepover
         local radius_scale_factor = 1.0
         radius_scale_factor = (outer_rad + cur_z) / inner_rad

         if use_variable_stepover then
            adj_stepover = stepover / radius_scale_factor
         end

         -- calculate size of rectangle at current z level to machine off corner
         local circumf_at_z = math.pi * inner_rad * 2.0
         local rot_ang = math.deg(math.acos(outer_rad / (outer_rad + cur_z)))
         local corner_ang_at_z = 90.0 - (2 * rot_ang)

         -- DisplayMessageBox("corner_ang_at_z = " .. corner_ang_at_z .. "\ncur_z = " .. cur_z .. "\nouter_rad = " .. outer_rad .. "\nrot_ang = " .. rot_ang)
         local corner_len_at_z = circumf_at_z * (corner_ang_at_z / 360.0)
         width = corner_len_at_z

         local raster_ctr = CreateRasterLevelContour(job, raster_dir, start_mid_point, width, length, adj_stepover, cur_z + z_offset, true, reverse_dir)
         if raster_ctr == nil then
            DisplayMessageBox("Failed to create toolpath for corner (" .. corner_index .. ") at z level " .. cur_z)
            return
         end
         -- if we are doing radial machining reverse every other pass to avoid long returns
         if reverse_dir then
            raster_ctr:Reverse()
         end

         -- if this is NOT the first contour for corner extend the previous contour to above current contours
         -- start point to avoid retract to safe z
         if zlevel > 1 then
            local prev_level_ctr = raster_group:GetTail();
            if prev_level_ctr ~= nil then
               local prev_end_pt = prev_level_ctr.EndPoint3D
               local cur_start_pt = raster_ctr.StartPoint3D
               --[[
                 DisplayMessageBox(
                                "\n Z Level = " .. zlevel .. " Num Contours = " .. raster_group.Count ..
                                "\ncur_z + z_offset = " .. cur_z + z_offset ..
                                "\nPrevious Contour End Point = " .. prev_end_pt.x .. "," .. prev_end_pt.y .. "," .. prev_end_pt.z ..
                                "\nCurrent Contour Start Point = " .. cur_start_pt.x .. "," .. cur_start_pt.y .. "," .. cur_start_pt.z
                                )
               ]]
               prev_level_ctr:LineTo(cur_start_pt.x, cur_start_pt.y, prev_end_pt.z)

               -- set flag indicating can join to next contour without retracting
               prev_level_ctr:SetCanJoinToParent(true)

            end
         end

         raster_group:AddTail(raster_ctr)

         reverse_dir = not reverse_dir
      end

   end -- end of for each corner

   -- create 360 degree toolpath to machine from outer rad to inner rad if there is a difference
   if outer_rad - (inner_rad + g_allowance) > 0.0001 then
      if not CreateSimpleCylinderRasterContours(job, true, outer_rad, inner_rad, g_allowance, raster_group, g_tool) then
         return false
      end
   end


   CreateToolpath(job, g_toolpath_name, raster_group)

   end


function IsConstantDiameter()
   return math.abs(g_start_diameter - g_end_diameter) < 0.000001
end

function UsesJobSetupDiameter()
   return IsConstantDiameter() and math.abs(g_start_diameter - g_cylinder_diameter) < 0.000001
end

function UsesFullLength()
   return math.abs(g_offset_from_start) < 0.000001 and math.abs(g_offset_from_end) < 0.000001
end

function GetEffectiveCylinderLength()
   local length = g_cylinder_length - g_offset_from_start - g_offset_from_end
   if length < 0.0 then
      return 0.0
   end

   return length
end

function GetBaseCylinderRadius()
   return g_cylinder_diameter * 0.5
end

function GetTaperRadiusAtAxis(axis_distance)
   if g_cylinder_length <= 0.0 then
      return g_start_diameter * 0.5
   end

   local ratio = axis_distance / g_cylinder_length
   if ratio < 0.0 then
      ratio = 0.0
   elseif ratio > 1.0 then
      ratio = 1.0
   end

   return ((g_start_diameter * 0.5) * (1.0 - ratio)) + ((g_end_diameter * 0.5) * ratio)
end

function GetCutZAtAxis(axis_distance, pass_offset, max_radius)
   local target_radius = GetTaperRadiusAtAxis(axis_distance) + g_allowance + pass_offset
   if max_radius ~= nil and target_radius > max_radius then
      target_radius = max_radius
   end

   return target_radius - GetBaseCylinderRadius()
end

function PrepareTaperedCoordinates(job)
   if g_cylinder_along_x then
      g_job_min_axis = job.MinX
      g_job_min_cross = job.MinY
   else
      g_job_min_axis = job.MinY
      g_job_min_cross = job.MinX
   end

   g_job_wrap_circumference = g_cylinder_diameter * math.pi
end

function AxisCrossToPoint(axis_distance, cross_distance)
   if g_cylinder_along_x then
      return Point2D(g_job_min_axis + axis_distance, g_job_min_cross + cross_distance)
   end

   return Point2D(g_job_min_cross + cross_distance, g_job_min_axis + axis_distance)
end

function GetTaperedPassOffsets(job, outer_radius)
   local largest_target_radius = math.max(g_start_diameter, g_end_diameter) * 0.5
   local max_radial_stock = outer_radius - (largest_target_radius + g_allowance)
   if max_radial_stock < 0.0 then
      max_radial_stock = 0.0
   end

   local stepdown = g_tool:ConvertValueToUnits(g_tool.Stepdown, job.InMM)
   if stepdown <= 0.0 then
      stepdown = max_radial_stock
   end

   local num_z_steps = 1
   if max_radial_stock > 0.0 and stepdown > 0.0 then
      num_z_steps = math.floor((max_radial_stock / stepdown) + 0.5)
      if ((max_radial_stock - (stepdown * num_z_steps)) > (stepdown * 0.2)) then
         num_z_steps = num_z_steps + 1
      end
      if num_z_steps < 1 then
         num_z_steps = 1
      end
   end

   local offsets = {}
   local z_step = max_radial_stock / num_z_steps
   for zlevel = 1, num_z_steps do
      local pass_offset = max_radial_stock - (zlevel * z_step)
      if zlevel == num_z_steps or pass_offset < 0.000001 then
         pass_offset = 0.0
      end
      offsets[zlevel] = pass_offset
   end

   return offsets
end

function CreateTaperedRasterLevelContour(raster_along_axis, pass_offset, stepover, reverse_end, outer_radius)
   local width = g_job_wrap_circumference
   local length = GetEffectiveCylinderLength()
   local step_span = width
   if not raster_along_axis then
      step_span = length
   end

   local num_lines = math.floor((step_span / stepover) + 0.5)
   if num_lines < 1 then
      num_lines = 1
   end
   if (num_lines % 2) == 1 then
      num_lines = num_lines + 1
   end

   local raster_stepover = 0.0
   if num_lines > 1 then
      raster_stepover = step_span / (num_lines - 1)
   end

   local contour = Contour(0.0)
   local first_point = true
   local reverse_line = reverse_end

   for n = 1, num_lines do
      local step_distance = (n - 1) * raster_stepover
      local start_axis = g_offset_from_start
      local start_cross = step_distance
      local end_axis = g_cylinder_length - g_offset_from_end
      local end_cross = step_distance

      if not raster_along_axis then
         start_axis = g_offset_from_start + step_distance
         start_cross = 0.0
         end_axis = start_axis
         end_cross = width
      end

      if reverse_line then
         local temp_axis = start_axis
         local temp_cross = start_cross
         start_axis = end_axis
         start_cross = end_cross
         end_axis = temp_axis
         end_cross = temp_cross
      end

      local start_point = AxisCrossToPoint(start_axis, start_cross)
      local start_z = GetCutZAtAxis(start_axis, pass_offset, outer_radius)
      local end_point = AxisCrossToPoint(end_axis, end_cross)
      local end_z = GetCutZAtAxis(end_axis, pass_offset, outer_radius)

      if first_point then
         contour:SetZHeight(start_z)
         contour:AppendPoint(start_point)
         first_point = false
      else
         contour:LineTo(start_point.x, start_point.y, start_z)
      end
      contour:LineTo(end_point.x, end_point.y, end_z)

      reverse_line = not reverse_line
   end

   return contour
end

function AddTaperedRasterContours(job, raster_group, raster_along_axis, outer_radius)
   local stepover = g_tool:ConvertValueToUnits(g_tool.Stepover, job.InMM)
   if stepover <= 0.0 then
      DisplayMessageBox("The selected tool must have a stepover greater than 0.0")
      return false
   end

   local pass_offsets = GetTaperedPassOffsets(job, outer_radius)
   local reverse_dir = false

   for pass_index = 1, #pass_offsets do
      local contour = CreateTaperedRasterLevelContour(raster_along_axis, pass_offsets[pass_index], stepover, reverse_dir, outer_radius)
      if contour == nil then
         DisplayMessageBox("Error creating tapered raster contour for pass " .. pass_index)
         return false
      end

      if pass_index < #pass_offsets then
         contour:SetCanJoinToParent(true)
      end

      raster_group:AddTail(contour)
      reverse_dir = not reverse_dir
   end

   return true
end

function CreateTaperedRasterToolpath(job, raster_along_axis)
   PrepareTaperedCoordinates(job)

   local outer_radius = 0.0
   if g_blank_is_square then
      local square_side_radius = g_square_side_len * 0.5
      outer_radius = math.sqrt((square_side_radius * square_side_radius) + (square_side_radius * square_side_radius))
   else
      outer_radius = g_blank_diameter * 0.5
   end

   local raster_group = ContourGroup(true)
   if not AddTaperedRasterContours(job, raster_group, raster_along_axis, outer_radius) then
      return false
   end

   if not CreateToolpath(job, g_toolpath_name, raster_group) then
      return false
   end

   return true
end

function CreateTaperedRasterToolpathFromRadius(job, raster_along_axis, outer_radius, toolpath_name)
   PrepareTaperedCoordinates(job)

   local original_toolpath_name = g_toolpath_name
   if toolpath_name ~= nil then
      g_toolpath_name = toolpath_name
   end

   local raster_group = ContourGroup(true)
   if not AddTaperedRasterContours(job, raster_group, raster_along_axis, outer_radius) then
      g_toolpath_name = original_toolpath_name
      return false
   end

   if not CreateToolpath(job, g_toolpath_name, raster_group) then
      g_toolpath_name = original_toolpath_name
      return false
   end

   g_toolpath_name = original_toolpath_name
   return true
end

function GetTaperedSpiralTurns(effective_length)
   local axial_pitch = g_spiral_pitch

   if not g_use_spiral_pitch then
      local circumference = g_cylinder_diameter * math.pi
      local spacing_ratio = g_spiral_spacing / circumference
      local alpha = math.asin(spacing_ratio)
      axial_pitch = circumference * math.tan(alpha)
   end

   if axial_pitch <= 0.0 then
      axial_pitch = effective_length
   end

   local turns = effective_length / axial_pitch
   if turns < 1.0 then
      turns = 1.0
   end
   return turns
end

function GetSpiralCrossSign(right_hand)
   if g_cylinder_along_x then
      if right_hand then
         return -1.0
      end
      return 1.0
   end

   if right_hand then
      return 1.0
   end
   return -1.0
end

function AddTaperedSpiralContours(spiral_group, effective_length, turns, segment_count, pass_offsets, outer_radius, right_hand)
   local cross_sign = GetSpiralCrossSign(right_hand)

   for pass_index = 1, #pass_offsets do
      local contour = Contour(0.0)
      for segment_index = 0, segment_count do
         local ratio = segment_index / segment_count
         local axis_distance = g_offset_from_start + (effective_length * ratio)
         local cross_distance = cross_sign * g_job_wrap_circumference * turns * ratio
         local z_value = GetCutZAtAxis(axis_distance, pass_offsets[pass_index], outer_radius)
         local point = AxisCrossToPoint(axis_distance, cross_distance)

         if segment_index == 0 then
            contour:SetZHeight(z_value)
            contour:AppendPoint(point)
         else
            contour:LineTo(point.x, point.y, z_value)
         end
      end

      if pass_index < #pass_offsets then
         contour:SetCanJoinToParent(true)
      end

      spiral_group:AddTail(contour)
   end

   return true
end

function CreateTaperedSpiralToolpath(job)
   PrepareTaperedCoordinates(job)

   local outer_radius = 0.0
   if g_blank_is_square then
      local square_side_radius = g_square_side_len * 0.5
      outer_radius = math.sqrt((square_side_radius * square_side_radius) + (square_side_radius * square_side_radius))
   else
      outer_radius = g_blank_diameter * 0.5
   end

   local effective_length = GetEffectiveCylinderLength()
   local turns = GetTaperedSpiralTurns(effective_length)
   local total_angle = turns * 360.0
   local segment_count = math.floor((total_angle / g_angular_step) + 0.5)
   if segment_count < 1 then
      segment_count = 1
   end

   local spiral_group = ContourGroup(true)
   local pass_offsets = GetTaperedPassOffsets(job, outer_radius)

   if g_create_right_twist then
      AddTaperedSpiralContours(spiral_group, effective_length, turns, segment_count, pass_offsets, outer_radius, true)
   end
   if g_create_left_twist then
      AddTaperedSpiralContours(spiral_group, effective_length, turns, segment_count, pass_offsets, outer_radius, false)
   end

   if not CreateToolpath(job, g_toolpath_name, spiral_group) then
      return false
   end

   return true
end

function CreateTaperedOptimisedRasterToolpath(job)
   local max_diameter = math.max(g_start_diameter, g_end_diameter)
   local max_radius = max_diameter * 0.5
   local original_cylinder_diameter = g_cylinder_diameter
   local original_toolpath_name = g_toolpath_name

   g_cylinder_diameter = max_diameter
   g_toolpath_name = original_toolpath_name .. " - Optimized Rough"
   CreateOptimisedRasterToolpath(job, true)

   g_cylinder_diameter = original_cylinder_diameter
   g_toolpath_name = original_toolpath_name

   return CreateTaperedRasterToolpathFromRadius(job, true, max_radius, original_toolpath_name .. " - Taper Finish")
end


--[[  ------------------------------------------ main --------------------------------------------------
|
|  Entry point for script
|
]]

function main(script_path)

   -- Check we have a job loaded
   local job = VectricJob()

   if not job.Exists then
      DisplayMessageBox("You must have a file open before running this gadget.\n\nThis gadget has been designed to be used with rotary jobs")
      return false;
   end


   -- Get user choices, if return -1 user entered an invalid value - try again
   local load_default_values = true
   local retry_dialog = true

   while retry_dialog do
      local ret_value = GetUserChoices(job, script_path, load_default_values)
      if ret_value == 0 then
         return false -- user cancelled dialog
      end
      load_default_values = false  -- we only load default values first time we display dialog
      if ret_value == 1 then
         retry_dialog = false  -- we got valid values
      end
   end



   -- set a 'parameter' on the job so that if we run any subsequent gadgets
   -- they can pick up the default wrapping axis for the file
   local job_params = job.JobParameters
   if job_params ~= nil then
      job_params:SetBool("luaWrappedCylinderAlongXAxis", g_cylinder_along_x)
   else
      DisplayMessageBox("Failed to get parameters for job")
   end

   -- Create the selected toolpath. Straight cylinders use the original
   -- Create Rounding Toolpath implementation for radial/raster/optimized.
   if g_toolpath_type == 4 then
      CreateTaperedSpiralToolpath(job)
   elseif g_toolpath_type == 1 then
      if UsesJobSetupDiameter() and UsesFullLength() then
         CreateSimpleRasterToolpath(job, false)
      else
         CreateTaperedRasterToolpath(job, false)
      end
   elseif g_toolpath_type == 2 then
      if UsesJobSetupDiameter() and UsesFullLength() then
         CreateSimpleRasterToolpath(job, true)
      else
         CreateTaperedRasterToolpath(job, true)
      end
   elseif g_toolpath_type == 3 then
      if UsesJobSetupDiameter() and UsesFullLength() then
         CreateOptimisedRasterToolpath(job, true)
      else
         CreateTaperedOptimisedRasterToolpath(job)
      end
   else
      DisplayMessageBox("Currently unsupported toolpath type chosen")
   end

   -- Make sure job shows any data we may have drawn
   job:Refresh2DView()

   return true

end
