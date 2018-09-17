require 'redcarpet'
require 'coderay'

class MarkdownRenderer < Redcarpet::Render::HTML
  def block_code(code, language)
    CodeRay.highlight(code, language)
  end
end

