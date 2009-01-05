class Hash
	def setkeys(keys, values)
		keys.zip(values).each { |k,v| self[k] = v }
		self
	end
end
