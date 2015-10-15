
local zlib=require("zlib")


function s_to_number(s)
	local ret=0
	for i=1,#s do
		ret=bit.bor(bit.lshift(string.byte (s, i),(i-1)*8),ret)
	end
	return ret
end
function number_to_s( n,bytes )
	if bytes==1 then
		return string.char (n)
	elseif bytes==2 then
		return string.char (bit.band(n,255),bit.rshift(n,8))
	elseif bytes==4 then
		return string.char (bit.band(n,255),bit.band(bit.rshift(n,8),255),bit.band(bit.rshift(n,16),255),bit.band(bit.rshift(n,24),255))
	else
		error("invalid byte count")
	end
end
--maybe c={r,g,b} would be better?
function load_cell(file)
	local ret={}
	ret[1]=s_to_number(file:read(4))
	for i=1,6 do
		ret[i+1]=file:read(1):byte()
	end
	return ret
end
function save_cell( file,cell )
	file:write(number_to_s(cell[1],4),4)
	for i=1,6 do
		file:write(number_to_s(cell[i+1],1),1)
	end
end
function load_rex_file( filename ,compressed)
	if compressed==nil then
		compressed=true
	end
	local ret={}

	local file
	if compressed then
		file=zlib.open(filename)
	else
		file=io.open(filename)
	end

	ret.version=s_to_number(file:read(4))
	ret.layer_count=s_to_number(file:read(4))
	assert(ret.layer_count<=4)
	ret.layers={}
	for i=1,ret.layer_count do
		local layer={}
		layer.w=s_to_number(file:read(4))
		layer.h=s_to_number(file:read(4))
		for i=1,layer.w*layer.h do
			layer[i]=load_cell(file)
		end
		ret.layers[i]=layer
	end
	file:close()
	return ret
end
function save_rex_file( filename , data,compressed)
	if compressed==nil then
		compressed=true
	end
	local ret={}
	local file
	if compressed then
		file=zlib.open(filename,"w")
	else
		file=io.open(filename,"w+b")
	end

	file:write(number_to_s(data.version or -1,4)) --version
	file:write(number_to_s(data.layer_count,4))
	for i,v in ipairs(data.layers) do
		file:write(number_to_s(v.w,4))
		file:write(number_to_s(v.h,4))
		for j,c in ipairs(v) do
			save_cell(file,c)
		end
	end
	file:close()
end

local ret={
	load=load_rex_file,
	save=save_rex_file
}

return ret
