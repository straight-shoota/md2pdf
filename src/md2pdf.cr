require "./md2pdf/transformer"
require "./md2pdf/version"

module MD2PDF
  def self.wkhtmltopdf_version
    String.new(LibWkHtmlToPdf.wkhtmltopdf_version)
  end
end
