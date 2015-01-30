require 'ox'

module XMLParser

	def XMLParser.valida_arquivo caminho_arquivo, ano_mes_referencia
		documento = Ox.parse(File.open(caminho_arquivo,"r:ISO-8859-1",&:read))
		dias_do_mes = XMLParser.dias_do_mes ano_mes_referencia
		id_canal = documento.locate("*/channel/@id/").first
		programas = []
		stop_programa_anterior = nil
		documento.locate("*/programme/").each do |programa|
			start = DateTime.strptime(programa.locate("@start").first.gsub(/ -0300/, ""), "%Y%m%d%H%M%S")
			stop = DateTime.strptime(programa.locate("@stop").first.gsub(/ -0300/, ""), "%Y%m%d%H%M%S")
			program_id =  programa.locate("@program_id").first
			event_id = programa.locate("@event_id").first
			series_key = programa.locate("@series_key").first
			canal = programa.locate("@channel").first

			dias_do_mes -= [start.to_date]
			datas_validas = stop > start
			possui_titulo = programa.locate("title/^Text").length > 0

			programa_invalido = {:program_id => program_id, :event_id => event_id, :series_key => series_key, :problemas => []}

			if !possui_titulo
				programa_invalido[:problemas].push("nao existe titulo informado para o programa")
			end

			if !datas_validas
				programa_invalido[:problemas].push("data/hora fim (#{stop.strftime("%d/%m/%Y %H:%M:%S")}) menor que data/hora inicio (#{start.strftime("%d/%m/%Y %H:%M:%S")}) para o mesmo programa")
			end

			if canal != id_canal
				programa_invalido[:problemas].push("identificador de canal (#{canal}) diferente do informado no inicio do arquivo (#{id_canal})")
			end

			if stop_programa_anterior and (stop_programa_anterior != start)
				programa_invalido[:problemas].push("data/hora inicio deste programa (#{start.strftime("%d/%m/%Y %H:%M:%S")}) diferente da data/hora fim do programa anterior (#{stop_programa_anterior.strftime("%d/%m/%Y %H:%M:%S")})")
			end

			if !datas_validas
				programa_invalido[:problemas].push("data/hora fim (#{stop.strftime("%d/%m/%Y %H:%M:%S")}) menor que data/hora inicio (#{start.strftime("%d/%m/%Y %H:%M:%S")}) para o mesmo programa")
			end

			stop_programa_anterior = stop

			if programa_invalido[:problemas].size > 0
				programas.push(programa_invalido)
			end
		end

		problemas_arquivo = []

		if documento.locate("*/programme/").empty?
			problemas_arquivo.push("nao existe nenhum programa elencado no arquivo para este mes")
		elsif !dias_do_mes.empty?
			dias_formatados = dias_do_mes.map { |dia| dia.strftime("%d/%m/%Y")}
			problemas_arquivo.push("o(s) seguinte(s) dia(s) nao esta(ao) presente(s) no arquivo: " + dias_formatados.join(", "))
		end

		return  {:id_canal => id_canal, :programas => programas, :problemas_arquivo => problemas_arquivo}
	end

	def XMLParser.dias_do_mes ano_mes_referencia
		inicio = Date.strptime(ano_mes_referencia+"01", "%Y%m%d")
		fim = (inicio >> 1) - 1
		dias = []
		(inicio..fim).each do |dia|
			dias.push(dia)
		end
		return dias
	end
end

# ap XMLParser.valida_arquivo ARGV[0], ARGV[1]
