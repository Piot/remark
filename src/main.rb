require 'redcarpet'
require 'fileutils'
require 'pathname'
require 'date'
require 'liquid'

def write_output relative_path, contents
	output_filename = File.join("../output/", relative_path)
	puts "write:#{output_filename}"
	output_dirname = File.dirname(output_filename)
	if not Dir.exists? output_dirname
		FileUtils.mkdir_p output_dirname
	end
	File.open output_filename, 'wb' do |output_file|
		output_file.write contents
	end
end

class Page
	attr_reader :markdown
	attr_reader :meta
	attr_reader :relative_name

	def initialize filename, root_path
		relative_filename = Pathname.new(filename).relative_path_from(Pathname.new(root_path)).to_path
		relative_dirname = File.dirname(filename)
		@relative_name = relative_filename.chomp(File.extname(relative_filename)) 
		contents = File.read filename
		match_data = contents.match /\-\-\-(.*)\-\-\-(.*)/m
		if match_data.nil?
			@meta = {}
			@markdown = contents
		else
			meta_string = match_data[1].strip
			meta_array = meta_string.split /\:|\n/
			meta_array.map! do |h|
				h.strip
			end		
			@meta = Hash[*meta_array.flatten]
			@markdown = match_data[2]
		end
	end
end

class BlogArticle
	attr_reader :published_date
	attr_reader :blog_id

	def initialize page
		date_exp = page.relative_name.match /(.*?)\-(.*)/
		@blog_id = date_exp[2]
		@published_date = DateTime.strptime date_exp[1], '%Y%m%d'
	end
end

class PageDirectory
	attr_reader :pages

	def initialize root_path
		search_path = File.join root_path, '**/*.md'
		filenames = []
		Dir.glob search_path do |filename|
			filenames << filename
		end
		@pages = []
		filenames.sort.reverse.each do |filename|
			page = Page.new filename, root_path
			@pages << page
		end
	end
end

class PageRender
	attr_reader :output

	def initialize markdown, meta
		@output = template markdown, meta
	end
	
	private

	def template code, settings
		Liquid::Template.parse(code).render settings
	end
end

class PageHtmlRender
	attr_reader :html

	def initialize page
		@html = render PageRender.new(page.markdown, page.meta).output
	end

	def render markdown
		converter = Redcarpet::Markdown.new Redcarpet::Render::HTML
		converter.render markdown
	end
end

pages_directory = '_pages/'

header_page = Page.new File.join(pages_directory, 'header.html'), pages_directory
footer_page = Page.new File.join(pages_directory,'footer.html'), pages_directory
footer_output = footer_page.markdown

page_collection = PageDirectory.new pages_directory
page_collection.pages.each do |page|
	header_output = PageRender.new(header_page.markdown, page.meta).output
	html_output = ''
	title = page.meta['title']
	html_output += "<h1>#{title}</h1>\n"

	if page.meta.has_key? 'youtube_id'
		youtube_id = page.meta['youtube_id']
		youtube_frame = "<iframe src=\"http://www.youtube.com/embed/#{youtube_id}\" width=\"640\" height=\"360\" frameborder=\"0\" allowfullscreen></iframe>"
		puts "YOUTUBE: #{youtube_frame.inspect}"
		html_output += youtube_frame
	end
	html_output += PageHtmlRender.new(page).html
	if page.meta.has_key? 'ios_app_id'
		app_id = page.meta['ios_app_id']
		itunes_link = "http://itunes.apple.com/app/id#{app_id}"
		html_output += "<a href=\"#{itunes_link}\"><img src=\"/images/download_on_the_app_store_eng.png\" /></a>"
	end
	if page.meta.has_key? 'developer'
		developer = page.meta['developer']
		co_developer = page.meta['co-developer']
		publisher = page.meta['publisher']
		html_output += "<div class=\"game_information\"><table>"
		html_output += "<tr><td align=\"right\">Developer</td><td>#{developer}</td></tr>"
		html_output += "<tr><td align=\"right\">Co-Developer</td><td>#{co_developer}</td></tr>"
		html_output += "<tr><td align=\"right\">Publisher</td><td>#{publisher}</td></tr>"
		html_output += "</table></div>"
	end
	output = header_output + "<article>" + html_output + "</article>" + footer_output
	write_output page.relative_name + ".html", output

end


blog_directory = PageDirectory.new '_blog/'
blog_output = ''
blog_directory.pages.each do |page|
	header_output = PageRender.new(header_page.markdown, page.meta).output

	blog_article = BlogArticle.new page

	date_string = blog_article.published_date.strftime '%d %b, %Y'

	article_header = "<article><h1><a href=\"/blog/#{blog_article.blog_id}/\">#{page.meta['title']}</a></h1><span><span class=\"icon-calendar-empty\"></span>#{date_string}</span>"
	article_footer = "</article>"

	html_output = PageHtmlRender.new(page).html

	page_output = article_header + html_output + article_footer

	output = header_output + page_output + footer_output
	blog_output += page_output
	write_output "blog/#{blog_article.blog_id}/index.html", output
end

blog_header_output = PageRender.new(header_page.markdown, {'title' => 'Blog'}).output
write_output "blog/index.html", blog_header_output + blog_output + footer_output

FileUtils.cp_r '_raw/.', '../output/'
