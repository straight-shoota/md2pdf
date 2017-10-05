require "markd"
require "wkhtmltopdf-crystal"
require "crinja"
require "crinja/loader/baked_file_loader"
require "xml"

class MD2PDF::Transformer
  TEMPLATE_PATH = "templates"

  property! md_file : String?
  property object_options = {} of String => String
  property global_options = {} of String => String
  property? pdf_file : String?
  property? html_file : String?
  property? output_html = false
  property? html_file : String?
  property template_path = "."

  def initialize(@md_file = nil)
  end

  def run
    generate_pdf(generate_html(load_markdown(md_file)))
  end

  def base_name
    md_file.rpartition(File.extname(md_file)).first
  end

  def html_file
    html_file? || base_name + ".html"
  end

  def pdf_file
    pdf_file? || base_name + ".pdf"
  end

  def load_markdown(md_file)
    File.read(md_file)
  end

  def generate_html_content(markdown)
    Markd.to_html(markdown)
  end

  def generate_html_main(content)
    env = Crinja::Environment.new
    env.loader = Crinja::Loader::ChoiceLoader.new([
      Crinja::Loader::FileSystemLoader.new(template_path),
      Crinja::Loader::FileSystemLoader.new(File.join(__DIR__, TEMPLATE_PATH)),
      Crinja::Loader::BakedFileLoader.new(TemplateFileSystem),
    ])

    template = env.get_template("main.html")
    template.render({
      "content"   => content,
      "generator" => "MD2PDF (#{MD2PDF::VERSION})",
      "page"      => {
        "title" => headline,
      },
    })
  end

  def generate_html(markdown)
    content = generate_html_content(markdown)

    @xml = XML.parse_html(content)

    generate_html_main(content).tap do |html|
      File.write(html_file, html) if output_html?
    end
  end

  def headline
    if h1 = @xml.try &.xpath_node("//h1")
      h1.inner_text
    else
      md_file
    end
  end

  def generate_pdf(html)
    pdf = Wkhtmltopdf::WkPdf.new
    pdf.set_output(pdf_file)
    options = default_object_options.merge object_options
    options.each do |option, value|
      pdf.object_setting option, value
    end
    options = default_global_options.merge global_options
    options.each do |option, value|
      pdf.set option, value
    end

    pdf.convert(html)
  end

  def default_object_options
    {
      "header.fontSize"    => "9",
      "header.spacing"     => "10",
      "header.fontName"    => "Helvetica",
      "footer.fontSize"    => "9",
      "footer.spacing"     => "10",
      "footer.fontName"    => "Helvetica",
      "footer.left"        => "[title]",
      "footer.right"       => "[page]/[toPage]",
      "outline"            => "true",
      "web.printMediaType" => "true",
    }
  end

  def default_global_options
    {
      "margin.top"    => "23mm",
      "margin.right"  => "18mm",
      "margin.bottom" => "23mm",
      "margin.left"   => "18mm",
    }
  end

  module TemplateFileSystem
    BakedFileSystem.load({{ TEMPLATE_PATH }}, __DIR__)
  end
end
