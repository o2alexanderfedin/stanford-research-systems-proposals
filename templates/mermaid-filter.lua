-- Pandoc Lua filter to convert Mermaid code blocks to images for PDF/DOCX export
-- Uses mermaid-cli (mmdc) to generate PNG images

local system = require 'pandoc.system'

local function file_exists(name)
  local f = io.open(name, "r")
  if f ~= nil then
    io.close(f)
    return true
  else
    return false
  end
end

local function mermaid_to_image(code, filetype)
  -- Generate unique filename based on content hash
  local hash = pandoc.sha1(code)
  local temp_dir = "/tmp/mermaid-diagrams"
  local mmd_file = temp_dir .. "/" .. hash .. ".mmd"
  local img_file = temp_dir .. "/" .. hash .. ".png"

  -- Create temp directory if it doesn't exist
  os.execute("mkdir -p " .. temp_dir)

  -- Check if image already exists (cache)
  if file_exists(img_file) then
    io.stderr:write("Using cached diagram: " .. img_file .. "\n")
    return pandoc.Image({}, img_file, "", {width="100%"})
  end

  -- Write mermaid code to temp file
  local file = io.open(mmd_file, "w")
  if not file then
    io.stderr:write("ERROR: Could not create temp file: " .. mmd_file .. "\n")
    return nil
  end
  file:write(code)
  file:close()

  -- Convert to image using mermaid-cli
  local cmd = string.format(
    'mmdc -i "%s" -o "%s" -b transparent -t default 2>&1',
    mmd_file,
    img_file
  )

  io.stderr:write("Generating diagram: " .. cmd .. "\n")
  local handle = io.popen(cmd)
  local result = handle:read("*a")
  local success = handle:close()

  if not success or not file_exists(img_file) then
    io.stderr:write("ERROR: Failed to generate diagram\n")
    io.stderr:write(result .. "\n")
    return nil
  end

  io.stderr:write("Generated diagram: " .. img_file .. "\n")

  -- Return image element with width constraint
  return pandoc.Image({}, img_file, "", {width="100%"})
end

function CodeBlock(block)
  -- Only process mermaid code blocks
  if block.classes[1] == "mermaid" then
    io.stderr:write("Processing Mermaid diagram...\n")
    return mermaid_to_image(block.text, FORMAT)
  end
  return nil
end

return {
  {CodeBlock = CodeBlock}
}
