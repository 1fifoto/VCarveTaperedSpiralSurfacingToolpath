-- VECTRIC LUA SCRIPT
-- ALTERED SOURCE VERSION: Wrapped Tapered Spiral Surfacing Toolpath release package.
-- Derived from Vectric Wrapped Spiral Layout gadget; original source notice retained below.
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
| BrianM    ??/??/???? V1.0    Written
| GrzegorzK 12/02/2018 v1.1    Update to take advantage of new rotary implementation
| GrzegorzK 01/05/2018 v1.2    Update to remove orientation change from the UI and make job size read-only
| GrzegorzK 30/05/2018 v1.3    Update to replace read-only edit boxes with static text
| GrzegorzK 13/08/2018 v1.3    Corrected twist direction when wrapping around Y axis
--]]

require "strict"


-- Default values for variables

g_num_starts = 4
g_spiral_spacing = 1.0
g_spiral_pitch = 1.0
g_use_spiral_pitch = true
g_offset_from_start = 1
g_offset_from_end = 1

g_create_right_twist = true
g_create_left_twist = false

g_create_cove_at_start = false
g_create_cove_at_end = false


g_cylinder_length = 48.0
g_cylinder_diameter = 8.0
g_cylinder_along_x = true

g_spiral_surfacing_toolpath_layer_name =  "Spiral Vectors"
g_cove_surfacing_toolpath_layer_name   =  "Cove Vectors"
   
g_window_width = 700
g_window_height = 750

g_display_num_rotation = true   

g_dialog_name = "Wrapped Tapered Spiral Surfacing Toolpath"

g_version = "1.0.0"

--[[ ----------- GetUserChoices -------------------------------------
|
| Display a dialog prompting user for options for processing
|
| Returns 1 if Ok, 0 if user cancelled -1 if error in data (retry)
|
--]]
function GetUserChoices(job, script_path, load_default_values)
   
   -- get our default values from the registry (values used last time we were run)
   local registry = Registry("WrappedTaperedSpiral")

   -- ---------------- Get default values from last run -------------------
   if load_default_values then
      g_num_starts        = registry:GetInt   ("NumStarts",   g_num_starts)
      g_spiral_pitch      = registry:GetDouble("SpiralPitch",      g_spiral_pitch)
      g_spiral_spacing    = registry:GetDouble("SpiralSpacing",    g_spiral_spacing)
      g_use_spiral_pitch  = registry:GetBool  ("UseSpiralPitch",   g_use_spiral_pitch)

      g_create_right_twist = registry:GetBool("CreateRightTwist",  g_create_right_twist)
      g_create_left_twist  = registry:GetBool("CreateLeftTwist",   g_create_left_twist)
      
      g_offset_from_start = registry:GetDouble("OffsetFromStart",  g_offset_from_start)
      g_offset_from_end   = registry:GetDouble("OffsetFromEnd",    g_offset_from_end)

      g_create_cove_at_start = registry:GetBool("CreateCoveAtStart",  g_create_cove_at_start)
      g_create_cove_at_end   = registry:GetBool("CreateCoveAtEnd",    g_create_cove_at_end)
      
      g_cylinder_length   = registry:GetDouble("CylinderLength",   g_cylinder_length)
      g_cylinder_diameter = registry:GetDouble("CylinderDiameter", g_cylinder_diameter)
      g_cylinder_along_x  = registry:GetBool  ("CylinderAlongX",   g_cylinder_along_x)
      
      g_window_width       = registry:GetInt("WindowWidth",         g_window_width)
      g_window_height      = registry:GetInt("WindowHeight",        g_window_height)
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
   
   -- display our dialog to get user choices
   local html_path = "file:" .. script_path .. "\\Wrapped_Tapered_Spiral_Surfacing_Toolpath\\Wrapped_Tapered_Spiral_Surfacing_Toolpath.htm"
   local dialog = HTML_Dialog(false, html_path, g_window_width, g_window_height, g_dialog_name)

   -- Gadget Version
   dialog:AddLabelField("GadgetVersion", g_version)
   
   -- Set up units fields on form -----------------
   
   -- We have a job open use units from that .....
   local in_mm = job.InMM 
   
   local units_text = "units"
   if in_mm then
      units_text = "mm"
   else
      units_text = "inches"
   end   
   
   -- set the labels we display for units
   dialog:AddLabelField("Units1", units_text)
   dialog:AddLabelField("Units2", units_text)

   dialog:AddLabelField("Units10", units_text)
   dialog:AddLabelField("Units11", units_text)
   dialog:AddLabelField("Units12", units_text)
   dialog:AddLabelField("Units13", units_text)
   
   -- Spiral Parameters
   dialog:AddIntegerField("NumStarts",        g_num_starts)
   
   local spiral_spacing_index = 2
   if g_use_spiral_pitch then
      spiral_spacing_index = 1
   end
   dialog:AddRadioGroup("SpiralSpacingOptionGroup", spiral_spacing_index)   

   
   dialog:AddDoubleField("StrandSpacing",     g_spiral_spacing)
   dialog:AddDoubleField("StrandPitch",       g_spiral_pitch)
   
   dialog:AddDoubleField("StrandStartOffset", g_offset_from_start)
   dialog:AddDoubleField("StrandEndOffset",   g_offset_from_end)

   -- Twist Direction 
   dialog:AddCheckBox("CreateRightHandTwistCheck", g_create_right_twist)
   dialog:AddCheckBox("CreateLeftHandTwistCheck",  g_create_left_twist)

   -- Coves
   dialog:AddCheckBox("CreateCoveAtStartCheck", g_create_cove_at_start)
   dialog:AddCheckBox("CreateCoveAtEndCheck",   g_create_cove_at_end)
   
   -- Cylinder Dimensions - read only
   dialog:AddLabelField("CylinderLength",    tostring(g_cylinder_length))
   dialog:AddLabelField("CylinderDiameter",  tostring(g_cylinder_diameter))

   -- ========== Display Dialog ======================================== 
   if  not dialog:ShowDialog() then
      -- DisplayMessageBox("User canceled dialog")
      return 0
   end   
   
   -- we keep the size the user has used for the dialog widnow
   g_window_width       = dialog.WindowWidth
   g_window_height      = dialog.WindowHeight

   -- if we reach here, user pressed OK on form - get values

   -- Spiral Parameters
   g_num_starts        = dialog:GetIntegerField("NumStarts")
   g_spiral_spacing    = dialog:GetDoubleField("StrandSpacing")
   g_spiral_pitch      = dialog:GetDoubleField("StrandPitch")

   spiral_spacing_index = dialog:GetRadioIndex("SpiralSpacingOptionGroup")   
   if spiral_spacing_index == 1 then
      g_use_spiral_pitch = true
   else
      g_use_spiral_pitch = false
   end   
   
   g_offset_from_start = dialog:GetDoubleField("StrandStartOffset")
   g_offset_from_end   = dialog:GetDoubleField("StrandEndOffset")

   -- Twist Direction 
   g_create_right_twist = dialog:GetCheckBox("CreateRightHandTwistCheck")
   g_create_left_twist  = dialog:GetCheckBox("CreateLeftHandTwistCheck")

   -- Coves
   g_create_cove_at_start = dialog:GetCheckBox("CreateCoveAtStartCheck")
   g_create_cove_at_end   = dialog:GetCheckBox("CreateCoveAtEndCheck")
   
   -- Do some error checking
   if g_num_starts < 1 then
      DisplayMessageBox("The Number of starts must be greater than 0")
      return -1
   end

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
   end
   
   if g_cylinder_length <= 0.0 then
      DisplayMessageBox("The cylinder length must be greater than 0.0")
      return -1
   end

   if g_spiral_spacing <= 0.0 then
      DisplayMessageBox("The spacing between strands must be greater than 0.0")
      return -1
   end

   if g_cylinder_diameter <= 0.0 then
      DisplayMessageBox("The cylinder diameter must be greater than 0.0")
      return -1
   end
   
   if ((g_offset_from_start + g_offset_from_end) > g_cylinder_length) then
      DisplayMessageBox("The start and end offsets combined must not exceed the cylinder length")
      return -1
   end
   
   if (not g_create_right_twist) and (not g_create_left_twist) then
      DisplayMessageBox("You must create either a left or right twist or both")
      return -1
   end
   
   -- save job settings as default for next time ....
   registry:SetInt("NumStarts",     g_num_starts)
   
   registry:SetBool  ("UseSpiralPitch",   g_use_spiral_pitch)
   if g_use_spiral_pitch then
      registry:SetDouble("SpiralPitch",   g_spiral_pitch)
   else   
      registry:SetDouble("SpiralSpacing", g_spiral_spacing)
   end   
   registry:SetDouble("OffsetFromStart", g_offset_from_start)
   registry:SetDouble("OffsetFromEnd",   g_offset_from_end)
   
   registry:SetBool("CreateRightTwist",  g_create_right_twist)
   registry:SetBool("CreateLeftTwist",   g_create_left_twist)

   registry:SetBool("CreateCoveAtStart",  g_create_cove_at_start)
   registry:SetBool("CreateCoveAtEnd",    g_create_cove_at_end)

   registry:SetInt("WindowWidth",         g_window_width)
   registry:SetInt("WindowHeight",        g_window_height)

   
   if not dims_from_job then
      registry:SetDouble("CylinderLength",  g_cylinder_length)
      registry:SetDouble("CylinderDiameter",g_cylinder_diameter)
      registry:SetBool  ("CylinderAlongX",  g_cylinder_along_x)
   end
   
   return 1
end

--[[ ---------- CreateSingleSpiral -----------------------------
|
| Create a single spiral with passed parameters
|
]]
function CreateSingleSpiral(job, along_x, cyl_dia, cyl_length, start_angle, start_offset, end_offset, line_angle, right_hand)

   local line = Contour(0.0);     -- use default tolerance

   local circum = cyl_dia * math.pi
   local start_ratio = start_angle / 360.0;
   
   local start_x
   local start_y
   local end_x
   local end_y
   local line_ang_rad = math.rad(line_angle)
   
   if along_x then
      start_x = job.MinX + start_offset
      start_y = job.MinY + (circum * start_ratio)
      end_x   = job.MinX + cyl_length - end_offset
      end_y   = start_y + ((end_x - start_x) * math.tan(line_ang_rad))
      if right_hand then
         start_y = -start_y
         end_y   = -end_y
      end
   else
      start_x = job.MinX + (circum * start_ratio)
      start_y = job.MinY + start_offset
      end_y   = job.MinY + cyl_length - end_offset
      end_x   = start_x + ((end_y - start_y) * math.tan(line_ang_rad))
      if not right_hand then
         start_x = -start_x
         end_x   = -end_x
      end
   end
   
   line:AppendPoint(start_x, start_y)
   line:LineTo(end_x, end_y)

   return line

   end
 

--[[ ------------- DrawSpirals -----------------------------------
|
|  Draw vectors representing spirals on a new layer - returns
|  number of rotations
|
]]
function DrawSpirals(job, right_hand, offset_start_angle)

   local spiral_group = ContourGroup(true)  -- this will own contours in it

   local step_angle = 360.0 / g_num_starts
   local cur_angle = 0.0  
   local circumference = g_cylinder_diameter *  math.pi
   
   local num_revolutions = 0
   
   if offset_start_angle then
      cur_angle = step_angle * 0.5
   end
   
   local spiral_angle = 0.0
   
   if g_num_starts > 0 then
      if g_use_spiral_pitch then
         spiral_angle =  90 - math.deg(math.atan2(g_spiral_pitch, circumference * 0.5))
      else
         local circumference_section = circumference / g_num_starts
         if (circumference_section <= g_spiral_spacing) then
            local max_starts = math.floor(circumference / g_spiral_spacing)
            DisplayMessageBox("ERROR\r\n\r\nIt is impossible to fit " .. g_num_starts .. " strands with " .. g_spiral_spacing .. " spacing " ..
                              "on a cylinder of " ..  g_cylinder_diameter .." diameter.\r\n\r\n" ..
                              "The maximum number of strands with the current spacing is " .. max_starts
                              )
            return 0
         end
         local alpha = math.asin(g_spiral_spacing / circumference_section )
         spiral_angle = 90.0 - math.deg(alpha);
         
      end   
   end
   
   
   for n = 1, g_num_starts do
   
      local contour = CreateSingleSpiral(
                                         job, 
                                         g_cylinder_along_x,
                                         g_cylinder_diameter,
                                         g_cylinder_length,
                                         cur_angle,
                                         g_offset_from_start,
                                         g_offset_from_end,
                                         spiral_angle,
                                         right_hand
                                         )
      
      -- add it to the spiral group
      spiral_group:AddTail(contour)

      cur_angle = cur_angle + step_angle
      
      end
   
   -- save the current layer as we don't want user drawign on our new 'construction' layer
   local cur_layer = job.LayerManager:GetActiveLayer()

   --  create a CadObject to represent the  group
   local cad_object = CreateCadGroup(spiral_group);
   
   
   -- create a layer with name if it doesnt already exist
   local layer = job.LayerManager:GetLayerWithName(g_spiral_surfacing_toolpath_layer_name)

   -- and add our object to it - on active sheet
   layer:AddObject(cad_object, true)

   -- lock the layer ?
   layer.Locked = false
   layer.Colour = 13158600  -- C8C8C8
      
   -- restore original active layer   
   job.LayerManager:SetActiveLayer(cur_layer)
  
   -- calculate number of revolutions
   local base_len = g_cylinder_length - g_offset_from_start - g_offset_from_end
   local wrap_len = base_len * math.tan(math.rad(spiral_angle))
   num_revolutions = wrap_len / circumference
      
   return num_revolutions
   
end

--[[ ---------- CreateSingleCove -----------------------------
|
| Create a single cove with passed parameters
|
]]
function CreateSingleCove(job, along_x, cyl_dia, offset_from_start)

   local line = Contour(0.0);     -- use default tolerance

   local circum = cyl_dia * math.pi
   
   local start_x
   local start_y
   local end_x
   local end_y
   
   if along_x then
      start_x = job.MinX + offset_from_start
      start_y = job.MinY
      end_x   = job.MinX + offset_from_start
      end_y   = job.MinY + circum
   else
      start_x = job.MinX 
      start_y = job.MinY + offset_from_start
      end_x   = job.MinX + circum
      end_y   = job.MinY + offset_from_start
   end
   
   line:AppendPoint(start_x, start_y)
   line:LineTo(end_x, end_y)

   return line

   end

   
--[[ ------------- DrawCoves -----------------------------------
|
|  Draw vectors representing coves on a new layer 
|
]]
function DrawCoves(job, do_start, do_end)

   if (not do_start) and (not do_end) then
      return
   end
   
   local cove_group = ContourGroup(true)  -- this will own contours in it

   
      -- save the current layer as we don't want user drawign on our new 'construction' layer
   local cur_layer = job.LayerManager:GetActiveLayer()

   
   -- now add our lines
   if do_start then
      local contour = CreateSingleCove(
                                      job,
                                      g_cylinder_along_x,
                                      g_cylinder_diameter,
                                      g_offset_from_start
                                      )
      cove_group:AddTail(contour)
   end
   
   if do_end then
      local contour = CreateSingleCove(
                                      job,
                                      g_cylinder_along_x,
                                      g_cylinder_diameter,
                                      g_cylinder_length - g_offset_from_end
                                      )
      cove_group:AddTail(contour)
   end
   
   --  create a CadObject to represent the  group
   local cad_object = CreateCadGroup(cove_group);
   
   -- create a layer with name if it doesnt already exist
   local layer = job.LayerManager:GetLayerWithName(g_cove_surfacing_toolpath_layer_name)

   -- and add our object to it - on active sheet
   layer:AddObject(cad_object, true)

   -- lock the layer ?
   layer.Locked = false
   layer.Colour = 13158600  -- C8C8C8
      
   -- restore original active layer   
   job.LayerManager:SetActiveLayer(cur_layer)

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
     
   -- now draw our vectors to use for spirals
   
   -- if we are creating a crossed spiral offset the starts for the second spiral
   local offset_start_angle = g_create_right_twist and g_create_left_twist
   
   local num_revolutions = 0;
   if g_create_right_twist then
      num_revolutions = DrawSpirals(job, true, false)
   end

   if g_create_left_twist then
      num_revolutions =DrawSpirals(job, false, offset_start_angle)
   end
   
   if num_revolutions > 0 then   
      if g_create_cove_at_start or g_create_cove_at_end then
        DrawCoves(job, g_create_cove_at_start, g_create_cove_at_end)
      end
   end   
   -- do we want to tell user number of rotations for spirals?
   if g_display_num_rotation then
      DisplayMessageBox("Total number of revolutions for spiral = " .. num_revolutions)
   end
   
   -- Make sure job shows any data we may have drawn    
   job:Refresh2DView()
     
   return true
   
end    
