selector = config["selector"]
site_url = config["site_url"]

if not selector then
  Plugin.fail("Missing required option \"selector\"")
end

if not site_url then
  Plugin.fail("Missing required option \"site_url\"")
end

elements = HTML.select(page, selector)

if not elements then
  Plugin.exit("No elements found, nothing to do")
end

local index = 1
while elements[index] do
    HTML.set_attribute(elements[index], "href", site_url .. page_url)
    index = index + 1
end
