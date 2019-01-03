require 'redcarpet'
require 'coderay'

class MarkdownRenderer < Redcarpet::Render::HTML
  def block_code(code, language)
    raise "No language is given for code #{code}" if language.nil?
    CodeRay.highlight(code, language)
  end
end

