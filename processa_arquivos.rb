require 'rubygems'
require 'spreadsheet'
require_relative 'xml_parser'

arquivo_xls = Spreadsheet.open ARGV[1]
planilha = arquivo_xls.worksheet "Plan1"
@canais = []

planilha.each do |linha|
	@canais.push({:id_canal => linha[0].strip, :nome => linha[1].strip})
end

@meses = {"janeiro" => "01", "fevereiro" => "02", "marco" => "03", "abril" => "04", "maio" => "05", "junho" => "06", "julho" => "07", "agosto" => "08", "setembro" => "09", "outubro" => "10", "novembro" => "11", "dezembro" => "12"}

def caminha path
	resultado_validacao = []
	caminhos = Dir.entries(path) - [".", ".."]
	caminhos.each do |caminho|
		caminho_atual = path+"/"+caminho
		if File.file? caminho_atual and caminho_atual.end_with? "xml"
			puts "processando arquivo #{caminho_atual} ..."
			captura_mes_ano = caminho_atual.match(/\/(?<mes>[[:alpha:]]+)(?<ano>[[:digit:]]+)\/.*xml/)
			retorno_validacao = XMLParser.valida_arquivo(caminho_atual, captura_mes_ano[:ano]+@meses[captura_mes_ano[:mes].downcase])
			arquivo = retorno_validacao.merge({:path => path, :nome_arquivo => caminho})
			resultado_validacao.push(arquivo)
			puts "arquivo #{caminho_atual} processado ..."
		elsif !File.file? caminho_atual
			caminha caminho_atual
		end
	end

	canais_inexistentes = []

	@canais.each do |canal|
		canal_existente_no_mes = false
		resultado_validacao.each_with_index do |resultado|
			if canal[:id_canal] == resultado[:id_canal]
				canal_existente_no_mes = true
			end
		end
		if !canal_existente_no_mes
			canais_inexistentes.push({:nome => canal[:nome], :id_canal => canal[:id_canal], :problema => "arquivo nao encontrado para este canal neste mes"})
		end
	end

	if path != (ARGV[0])
		captura_mes_ano = path.match(/\/(?<mes>[[:alpha:]]+)(?<ano>[[:digit:]]+)$/)
		File.open("#{path}/#{captura_mes_ano[:mes]+captura_mes_ano[:ano]}.csv", "w+") do |arquivo_saida|
			arquivo_saida.puts "MES; ANO; TIPO DE ERRO; IDENTIFICADOR DO CANAL; NOME DO ARQUIVO OU CANAL; FATO GERADOR DO ERRO; DESCRICAO DO ERRO\n\n"
			resultado_validacao.each do |resultado|
				resultado[:programas].each do |programa|
					programa[:problemas].each do |problema|
						arquivo_saida.puts("#{captura_mes_ano[:mes]}; #{captura_mes_ano[:ano]}; PROGRAMA; #{resultado[:id_canal]}; #{resultado[:nome_arquivo]}; <programa: #{programa[:program_id]}, evento: #{programa[:event_id]}, serie: #{programa[:series_key]}>; #{problema}")
					end
				end
			end

			resultado_validacao.each do |resultado|
				resultado[:problemas_arquivo].each do |problema|
					arquivo_saida.puts("#{captura_mes_ano[:mes]}; #{captura_mes_ano[:ano]}; ARQUIVO; #{resultado[:id_canal]}; #{resultado[:nome_arquivo]}; #{resultado[:nome_arquivo]}; #{problema}")
				end
			end

			if !canais_inexistentes.empty?
				arquivo_saida.puts "\n"
			end

			canais_inexistentes.each do |canal|
				arquivo_saida.puts("#{captura_mes_ano[:mes]}; #{captura_mes_ano[:ano]}; CANAL; #{canal[:id_canal]}; #{canal[:nome]}; NAO SE APLICA; #{canal[:problema]}")
			end
		end
	end
end

caminha ARGV[0]
