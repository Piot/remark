require 'redcarpet'
require 'fileutils'

header = File.read 'header.html'
footer = File.read 'footer.html'
settings_content = File.read 'settings.rb'
settings = eval settings_content

Dir.glob '**/*.md' do |filename|
	contents = File.read filename
	converter =  Redcarpet::Markdown.new Redcarpet::Render::HTML
	converted = converter.render contents
	relative_dirname = File.dirname(filename)
	output_filename = File.join("../output/", filename.chomp(File.extname(filename)) + '.html')
	output_dirname = File.dirname(output_filename)
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
	if not Dir.exists? output_dirname
		FileUtils.mkdir_p output_dirname
	end
	File.open output_filename, 'wb' do |output_file|
		output_file.write converted
	end
end