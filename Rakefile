require "bundler/gem_tasks"

require 'erb'
require 'redcarpet'
require 'coderay'
require 'markdown_renderer'
require 'ruby_101/version'

task :default => :assemble
directory 'docs/css'
file 'docs/css/coderay.css' => ['docs/css'] do
  sh 'coderay stylesheet > docs/css/coderay.css'
end

task :assemble => ['docs', 'docs/css/coderay.css'] do
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
  @version = Ruby101::VERSION
  template = File.read('templates/book.html.erb')
  File.write('docs/index.html', ERB.new(template).result)
end

task :clean do
  rm_rf 'docs'
end
