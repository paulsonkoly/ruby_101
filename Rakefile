require "bundler/gem_tasks"

require 'erb'
require 'redcarpet'
require 'coderay'
require 'markdown_renderer'

task :default => :assemble
directory 'book'
file 'book/coderay.css' => 'css/coderay.css' do
  cp 'css/coderay.css', 'book/coderay.css'
end

task :assemble => ['book', 'book/coderay.css'] do
  rndr = MarkdownRenderer.new(:filter_html => true, :hard_wrap => true)
  options = {
    :fenced_code_blocks => true,
    :no_intra_emphasis => true,
    :autolink => true,
    :strikethrough => true,
    :lax_html_blocks => true,
    :superscript => true
  }

  markdown_to_html = Redcarpet::Markdown.new(rndr, options)
  @content = markdown_to_html.render(File.read('content/book.md'))
  template = File.read('templates/book.html.erb')
  File.write('book/ruby101.html', ERB.new(template).result)
end

task :clean do
  rm_rf 'book'
end
