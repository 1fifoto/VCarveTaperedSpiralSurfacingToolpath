-- VECTRIC LUA SCRIPT
-- ALTERED SOURCE VERSION: Tapered Spiral Surfacing Toolpath release package.
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

g_blank_is_square = true
g_blank_diameter = 1.25
g_blank_square_size = 1.25
g_allowance = 0.0
g_machining_method = 1 -- 1 = spiral, 2 = radial, 3 = raster, 4 = optimized raster

g_cylinder_length = 48.0
g_cylinder_diameter = 8.0
g_cylinder_along_x = true

g_start_diameter = 1.25
g_end_diameter = 1.0425
   
g_window_width = 740
g_window_height = 800

g_default_tool_id = ToolDBId()
g_tool = nil
g_toolpath_name = "Tapered Spiral"

g_dialog_name = "Create Tapered Rounding Toolpath"

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
   local registry = Registry("TaperedSpiralSurfacingToolpathV3")

   -- ---------------- Get default values from last run -------------------
   if load_default_values then
      g_blank_is_square    = registry:GetBool  ("BlankIsSquare",   g_blank_is_square)
      g_blank_diameter     = registry:GetDouble("BlankDiameter",   g_blank_diameter)
      g_blank_square_size  = registry:GetDouble("BlankSquareSize", g_blank_square_size)
      g_allowance          = registry:GetDouble("Allowance",       g_allowance)
      g_machining_method   = registry:GetInt   ("MachiningMethod", g_machining_method)
      g_toolpath_name      = registry:GetString("ToolpathName",    BuildToolpathName(g_machining_method))
      g_default_tool_id:LoadDefaults("TaperedRoundingToolpath", "")
      
      g_cylinder_length   = registry:GetDouble("CylinderLength",   g_cylinder_length)
      g_cylinder_diameter = registry:GetDouble("CylinderDiameter", g_cylinder_diameter)
      g_cylinder_along_x  = registry:GetBool  ("CylinderAlongX",   g_cylinder_along_x)

      g_start_diameter = registry:GetDouble("StartDiameter", g_start_diameter)
      g_end_diameter   = registry:GetDouble("EndDiameter",   g_end_diameter)
      
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

   if g_start_diameter <= 0.0 then
      g_start_diameter = g_cylinder_diameter
   end

   if g_end_diameter <= 0.0 then
      g_end_diameter = g_cylinder_diameter
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
   dialog:AddLabelField("Units14", units_text)

   local blank_shape_index = 1
   if not g_blank_is_square then
      blank_shape_index = 2
   end
   dialog:AddRadioGroup("BlankShapeOptionGroup", blank_shape_index)
   dialog:AddDoubleField("BlankSquareSize", g_blank_square_size)
   dialog:AddDoubleField("BlankDiameter", g_blank_diameter)
   dialog:AddDoubleField("Allowance", g_allowance)

   dialog:AddRadioGroup("MachiningMethodOptionGroup", g_machining_method)

   dialog:AddLabelField("ToolNameLabel", "No tool selected")
   dialog:AddToolPicker("ToolChooseButton", "ToolNameLabel", g_default_tool_id)
   dialog:AddToolPickerValidToolType("ToolChooseButton", Tool.BALL_NOSE)
   dialog:AddToolPickerValidToolType("ToolChooseButton", Tool.END_MILL)
   dialog:AddToolPickerValidToolType("ToolChooseButton", Tool.RADIUSED_END_MILL)
   dialog:AddTextField("ToolpathName", g_toolpath_name)

   dialog:AddDoubleField("StartDiameter", g_start_diameter)
   dialog:AddDoubleField("EndDiameter",   g_end_diameter)
   
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

   local blank_shape_index = dialog:GetRadioIndex("BlankShapeOptionGroup")
   g_blank_is_square = blank_shape_index == 1
   g_blank_square_size = dialog:GetDoubleField("BlankSquareSize")
   g_blank_diameter = dialog:GetDoubleField("BlankDiameter")
   g_allowance = dialog:GetDoubleField("Allowance")
   g_machining_method = dialog:GetRadioIndex("MachiningMethodOptionGroup")

   if g_machining_method < 1 or g_machining_method > 4 then
      DisplayMessageBox("Unknown machining method selected")
      return -1
   end

   if (not g_blank_is_square) and g_machining_method == 4 then
      DisplayMessageBox("Optimized Raster strategy is not valid for round blanks - defaulting to Raster")
      g_machining_method = 3
   end

   g_start_diameter = dialog:GetDoubleField("StartDiameter")
   g_end_diameter   = dialog:GetDoubleField("EndDiameter")
   g_toolpath_name = dialog:GetTextField("ToolpathName")
   
   -- Do some error checking
   if g_cylinder_length <= 0.0 then
      DisplayMessageBox("The cylinder length must be greater than 0.0")
      return -1
   end

   if g_blank_is_square and g_blank_square_size <= 0.0 then
      DisplayMessageBox("The square blank size must be greater than 0.0")
      return -1
   end

   if (not g_blank_is_square) and g_blank_diameter <= 0.0 then
      DisplayMessageBox("The round blank diameter must be greater than 0.0")
      return -1
   end

   if g_allowance < 0.0 then
      DisplayMessageBox("The allowance must be zero or greater")
      return -1
   end

   g_tool = dialog:GetTool("ToolChooseButton")
   if g_tool == nil then
      DisplayMessageBox("No tool selected!")
      return -1
   end
   if string.len(g_toolpath_name) < 1 then
      DisplayMessageBox("A name must be entered for the toolpath")
      return -1
   end
   g_default_tool_id = g_tool.ToolDBId

   if g_cylinder_diameter <= 0.0 then
      DisplayMessageBox("The cylinder diameter must be greater than 0.0")
      return -1
   end

   if g_start_diameter <= 0.0 then
      DisplayMessageBox("The start diameter must be greater than 0.0")
      return -1
   end

   if g_end_diameter <= 0.0 then
      DisplayMessageBox("The end diameter must be greater than 0.0")
      return -1
   end
   
   -- save job settings as default for next time ....
   registry:SetBool  ("BlankIsSquare",     g_blank_is_square)
   registry:SetDouble("BlankSquareSize",   g_blank_square_size)
   registry:SetDouble("BlankDiameter",     g_blank_diameter)
   registry:SetDouble("Allowance",         g_allowance)
   registry:SetInt   ("MachiningMethod",   g_machining_method)
   registry:SetString("ToolpathName",      g_toolpath_name)
   g_default_tool_id:SaveDefaults("TaperedRoundingToolpath", "")

   registry:SetDouble("StartDiameter", g_start_diameter)
   registry:SetDouble("EndDiameter",   g_end_diameter)

   registry:SetInt("WindowWidth",         g_window_width)
   registry:SetInt("WindowHeight",        g_window_height)

   
   if not dims_from_job then
      registry:SetDouble("CylinderLength",  g_cylinder_length)
      registry:SetDouble("CylinderDiameter",g_cylinder_diameter)
      registry:SetBool  ("CylinderAlongX",  g_cylinder_along_x)
   end
   
   return 1
end

function BuildToolpathName(machining_method)
   if machining_method == 1 then
      return "Tapered Spiral"
   end
   if machining_method == 2 then
      return "Tapered Radial"
   end
   if machining_method == 3 then
      return "Tapered Raster"
   end
   if machining_method == 4 then
      return "Tapered Optimized Raster"
   end
   return "Tapered Toolpath"
end

--[[ ---------- CreateTaperedSurfacingToolpaths -----------------------------
|
| Placeholder for the next implementation pass. The dialog and tool selection
| are now wired, but actual ExternalToolpath generation still needs to be added.
|
]]
function GetToolpathWidthFromTool(tool, job)
   if tool == nil then
      return 0.0
   end

   return tool:ConvertValueToUnits(tool.Stepover, job.InMM)
end

function CreateTaperedSurfacingToolpaths(job)
   local toolpath_width = GetToolpathWidthFromTool(g_tool, job)

   local message = "Tapered rounding toolpath creation is not implemented yet.\n\nThe dialog now captures blank, allowance, machining method, finished taper, and tool selection. Next step is generating the ExternalToolpath."
   if g_machining_method == 1 then
      message = message .. "\n\nSpiral spacing will be derived from the selected tool stepover."
      if toolpath_width > 0.0 then
         message = message .. "\nSpiral spacing: " .. toolpath_width
      end
   end
   message = message .. "\n\nToolpath name: " .. g_toolpath_name

   DisplayMessageBox(message)
   return true
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
     
   local job_params = job.JobParameters
   if job_params ~= nil then
      job_params:SetBool("luaWrappedCylinderAlongXAxis", g_cylinder_along_x)
   else
      DisplayMessageBox("Failed to get parameters for job")
   end

   CreateTaperedSurfacingToolpaths(job)
   
   -- Make sure job shows any data we may have drawn    
   job:Refresh2DView()
     
   return true
   
end    
