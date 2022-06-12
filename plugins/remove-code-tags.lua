selector = config["selector"]
if not selector then
  Plugin.fail("Missing required option \"selector\"")
end

function remove_code_tags(element)
    content = HTML.inner_html(element)
    content = Regex.replace(content, "<code>", "")
    content = Regex.replace(content, "</code>", "")
    content = HTML.parse(content)
    HTML.replace_content(element, content)
end

elements = HTML.select(page, selector)

if not elements then
  Plugin.exit("No elements found, nothing to do")
end

local index = 1
while elements[index] do
  remove_code_tags(elements[index])
  index = index + 1
end
