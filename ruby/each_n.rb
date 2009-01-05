class Array
	def each_n(n, &block)
		(0 .. (self.size/n.to_f).ceil - 1).map { |i| block.call(self[i*n,n]) }
	end
	def collect_n(n, &block)
		c = []
		self.each_n(n) { |nth| block.call(nth).each { |x| c << x } }
		return c
	end
	def collect_n!(n, &block)
		self[0, self.size] = self.collect_n(n, &block)
	end
	alias_method :map_n,  :collect_n
	alias_method :map_n!, :collect_n!
end
