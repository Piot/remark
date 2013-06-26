require 'redcarpet'
require 'fileutils'
require 'pathname'
require 'date'

pages_directory = '_pages/'

header = File.read File.join(pages_directory, 'header.html')

footer = File.read File.join(pages_directory, 'footer.html')
settings_content = File.read File.join(pages_directory, 'settings.rb')
settings = eval settings_content

def write_output relative_path, contents
	output_filename = File.join("../output/", relative_path)
	output_dirname = File.dirname(output_filename)
	if not Dir.exists? output_dirname
		FileUtils.mkdir_p output_dirname
	end
	File.open output_filename, 'wb' do |output_file|
		output_file.write contents
	end

end


search_path = File.join pages_directory, '**/*.md'
Dir.glob search_path do |filename|
	puts "filename before: #{filename}"
	relative_dirname = File.dirname(filename)
	relative_filename = Pathname.new(filename).relative_path_from(Pathname.new(pages_directory)).to_path
	puts "Filename:#{filename} relative:#{relative_filename}"
	contents = File.read filename
	converter =  Redcarpet::Markdown.new Redcarpet::Render::HTML
	converted = converter.render contents
	page_name = settings[relative_dirname]
	if page_name.nil?
		page_name = File.basename(relative_dirname).capitalize
	end
	if page_name != ''
		page_name = page_name + ' - '
	end
	page_name = page_name + "Outbreak Studios"
	header_output = sprintf( header,  { :page_name => page_name })
	converted = header_output + converted + footer
	relative_path = relative_filename.chomp(File.extname(relative_filename)) + '.html'
	write_output relative_path, converted
end

blog_directory = '_blog/'
blog_path = File.join blog_directory, '**/*.md'

filenames = Dir.glob blog_path
filenames = filenames.sort.reverse
blog_content = ''
filenames.each do |filename|
	relative_filename = Pathname.new(filename).relative_path_from(Pathname.new(blog_directory)).to_path
	puts "blog:#{relative_filename}"
	contents = File.read filename
	puts "contents:#{contents}"
	match_data = contents.match /\-\-\-(.*)\-\-\-(.*)/m
	puts "match_data:#{match_data}"

	meta_string = match_data[1].strip
	meta_array = meta_string.split /\:|\n/
	puts "array:#{meta_array}"
	meta_array.map! do |h|
		h.strip
	end
	meta_hash = Hash[*meta_array.flatten]
	markdown = match_data[2]
	puts "meta:#{meta_hash}"


	name = File.basename(filename).chomp(File.extname(relative_filename))

	date_exp = name.match /(.*?)\-(.*)/
	puts "date_exp:#{date_exp[1]} rest:'#{date_exp[2]}'"
	blog_id = date_exp[2]
	published_date = DateTime.strptime date_exp[1], '%Y%m%d'
	date_string = published_date.strftime '%d %b, %Y'
	puts "published_date:#{date_string}"

	article_header = "<article><h1><a href=\"#{blog_id}/\">#{meta_hash['title']}</a></h1><span>#{date_string}</span>"
	article_footer = "</article>"

	converter = Redcarpet::Markdown.new Redcarpet::Render::HTML
	converted = converter.render markdown

	content = article_header + converted + article_footer

	write_output "blog/#{blog_id}/index.html", header + content + footer

	blog_content += content
end
write_output 'blog/index.html', header + blog_content + footer
