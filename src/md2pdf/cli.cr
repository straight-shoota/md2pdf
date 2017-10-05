require "option_parser"

module MD2PDF::CLI
  def self.run(args = ARGV)
    md_file = nil
    transformer = MD2PDF::Transformer.new
    opts = OptionParser.new do |opts|
      opts.banner = <<-BANNER
        Usage: md2pdf [options] FILE

        Options:
            -Oobject_option=value            PDF object option for wkhtmltopdf, separated by `=`
                                             See https://wkhtmltopdf.org/libwkhtmltox/pagesettings.html#pagePdfObject for available settings
                                             Example: -Oweb.printMediaType=false
            -Gglobal_option=value            PDF global option for wkhtmltopdf, separated by `=`
                                             See https://wkhtmltopdf.org/libwkhtmltox/pagesettings.html#pagePdfGlobal for available settings
                                             Example: -Gmargin.top=2cm
        BANNER
      opts.on("-o FILE", "--output=FILE", "Output file [default: FILE.pdf]") { |file| transformer.pdf_file = file }
      opts.on("--output-html", "Save HTML output to file") { transformer.output_html = true }
      opts.on("--template-path=PATH", "Template path where main.html file can be found [default: ./]") { |path| transformer.template_path = path }
      opts.on("-h", "--help", "Show this help") { puts opts }
      opts.on("--version", "Show version info") do
        puts "MD2PDF #{MD2PDF::VERSION}"
        puts "using wkhtmltopdf #{MD2PDF.wkhtmltopdf_version}"
        exit 0
      end

      opts.invalid_option do |option|
        if option.starts_with?("-O")
          key, _, value = option[2..-1].partition("=")
          transformer.object_options[key] = value
        elsif option.starts_with?("-G")
          key, _, value = option[2..-1].partition("=")
          transformer.global_options[key] = value
        end
      end
      opts.unknown_args do |before, after|
        md_file = before.find { |s| s[0] != '-' }
      end
    end

    opts.parse(args)

    if md_file
      transformer.md_file = md_file
      transformer.run
    else
      puts opts
    end
  end
end
